import gleam/dynamic/decode
import gleam/erlang/process
import gleam/http/request
import gleam/http/response
import gleam/httpc
import gleam/int
import gleam/json
import gleam/list
import gleam/otp/actor
import gleam/result
import gleam/uri
import sqlight
import wisp

import webshop/data/types.{type Category, type Item}
import webshop/error.{type WebshopInitError}

const base_url = "https://pokeapi.co/api/v2/"

const endpoint_item_categories = "item-category"

const endpoint_items = "item"

@internal
pub type ResourceEntry {
  ResourceEntry(name: String, url: String)
}

fn resource_entry_decoder() -> decode.Decoder(ResourceEntry) {
  use url <- decode.field("url", decode.string)
  use name <- decode.field("name", decode.string)
  decode.success(ResourceEntry(name:, url:))
}

@internal
pub fn fetch_resource_entries(
  resource: String,
) -> Result(List(ResourceEntry), WebshopInitError) {
  let assert Ok(uri) = uri.parse(base_url <> resource <> "?limit=10000")
  let assert Ok(req) = request.from_uri(uri)
  use resp <- result.try(httpc.send(req) |> result.map_error(error.HttpcError))
  parse_resource_entries(resp)
}

fn parse_resource_entries(
  resp: response.Response(String),
) -> Result(List(ResourceEntry), WebshopInitError) {
  let decoder = {
    use results <- decode.field(
      "results",
      decode.list(resource_entry_decoder()),
    )
    decode.success(results)
  }
  json.parse(resp.body, decoder)
  |> result.map_error(error.ParseError)
}

fn fetch_resource(
  decoder: decode.Decoder(a),
  resource: ResourceEntry,
) -> Result(a, WebshopInitError) {
  let assert Ok(uri) = uri.parse(resource.url)
  let assert Ok(req) = request.from_uri(uri)
  use resp <- result.try(httpc.send(req) |> result.map_error(error.HttpcError))
  json.parse(resp.body, decoder) |> result.map_error(error.ParseError)
}

type FetchMessage(a) {
  Success(List(a))
  Failure(WebshopInitError)
}

type FetchState(a) {
  FetchState(
    process_count: Int,
    insert_resource: fn(List(a)) -> Result(Nil, sqlight.Error),
    subject: process.Subject(Result(Nil, WebshopInitError)),
  )
}

/// Spawns multiple processes which fetch the data in parallel batches
fn parallel_fetch_resources(
  entries: List(ResourceEntry),
  insert_resource: fn(List(a)) -> Result(Nil, sqlight.Error),
  decoder: decode.Decoder(a),
) -> Result(Nil, WebshopInitError) {
  let entry_count = list.length(entries)
  let process_count = 5
  let entries_per_process = entry_count / process_count

  wisp.log_info(
    "Fetching "
    <> int.to_string(entry_count)
    <> " entries on "
    <> int.to_string(process_count)
    <> " processes.",
  )

  let subject = process.new_subject()
  let assert Ok(started) =
    actor.new(FetchState(process_count:, insert_resource:, subject:))
    |> actor.on_message(handle)
    |> actor.start()
  let accumulator = started.data

  let chunked_entries = list.sized_chunk(entries, entries_per_process)
  list.map(chunked_entries, fn(entries) {
    process.spawn(fn() {
      let result =
        list.map(entries, fetch_resource(decoder, _))
        |> result.all()
      case result {
        Ok(res) -> actor.send(accumulator, Success(res))
        Error(err) -> actor.send(accumulator, Failure(err))
      }
    })
  })

  // wait until all fetching processes concluded or there was an error
  process.receive_forever(subject)
}

fn log_process(_state: FetchState(a), new_progress_count: Int) -> Nil {
  wisp.log_info(
    "Remaining number of processes: " <> int.to_string(new_progress_count),
  )
}

fn handle(
  state: FetchState(a),
  msg: FetchMessage(a),
) -> actor.Next(FetchState(a), FetchMessage(a)) {
  case msg {
    Success(entries) -> {
      let new_process_count = state.process_count - 1
      log_process(state, new_process_count)

      case state.insert_resource(entries) {
        Ok(Nil) ->
          case new_process_count == 0 {
            False ->
              actor.continue(
                FetchState(..state, process_count: new_process_count),
              )
            True -> {
              actor.send(state.subject, Ok(Nil))
              actor.stop()
            }
          }
        Error(err) -> {
          wisp.log_error("Failed to insert fetched resource into database.")
          actor.send(state.subject, Error(error.DBError(err)))
          actor.stop_abnormal(
            "Failed to insert fetched resource into database.",
          )
        }
      }
    }
    Failure(err) -> {
      actor.send(state.subject, Error(err))
      actor.stop_abnormal("An error occurred while fetching data.")
    }
  }
}

fn filter_not_cached(
  entries: List(ResourceEntry),
  is_cached: fn(String) -> Result(Bool, WebshopInitError),
) -> Result(List(ResourceEntry), WebshopInitError) {
  filter_not_cached_loop(entries, is_cached, [])
}

fn filter_not_cached_loop(
  entries: List(ResourceEntry),
  is_cached: fn(String) -> Result(Bool, WebshopInitError),
  acc: List(ResourceEntry),
) -> Result(List(ResourceEntry), WebshopInitError) {
  case entries {
    [] -> Ok(acc)
    [entry, ..rest] ->
      case is_cached(entry.name) {
        Ok(False) -> filter_not_cached_loop(rest, is_cached, [entry, ..acc])
        Ok(True) -> filter_not_cached_loop(rest, is_cached, acc)
        Error(err) -> Error(err)
      }
  }
}

pub fn fetch_item_categories(
  is_cached: fn(String) -> Result(Bool, WebshopInitError),
  insert_categories: fn(List(Category)) -> Result(Nil, sqlight.Error),
) -> Result(Nil, WebshopInitError) {
  use entries <- result.try(fetch_resource_entries(endpoint_item_categories))
  use not_in_cache <- result.try(filter_not_cached(entries, is_cached))

  let total = list.length(entries)
  let not_cached = list.length(not_in_cache)

  wisp.log_notice(
    "Cached "
    <> int.to_string(total - not_cached)
    <> "/"
    <> int.to_string(total)
    <> " categories",
  )

  case not_in_cache {
    [] -> Ok(Nil)
    entries ->
      parallel_fetch_resources(
        entries,
        insert_categories,
        types.category_decoder(),
      )
  }
}

pub fn fetch_items(
  is_cached: fn(String) -> Result(Bool, WebshopInitError),
  insert_items: fn(List(Item)) -> Result(Nil, sqlight.Error),
) -> Result(Nil, WebshopInitError) {
  use entries <- result.try(fetch_resource_entries(endpoint_items))
  use not_in_cache <- result.try(filter_not_cached(entries, is_cached))

  let total = list.length(entries)
  let not_cached = list.length(not_in_cache)

  wisp.log_notice(
    "Cached "
    <> int.to_string(total - not_cached)
    <> "/"
    <> int.to_string(total)
    <> " items",
  )
  case not_in_cache {
    [] -> Ok(Nil)
    entries ->
      parallel_fetch_resources(entries, insert_items, types.item_decoder())
  }
}
