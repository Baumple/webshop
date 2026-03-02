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

/// Spawns multiple processes which fetch the data in parallel batches
fn parallel_fetch_resources(
  entries: List(ResourceEntry),
  decoder: decode.Decoder(a),
) -> Result(List(a), WebshopInitError) {
  let entry_count = list.length(entries)
  let process_count = 1
  let entries_per_process = echo entry_count / process_count

  wisp.log_info(
    "Fetching "
    <> int.to_string(entry_count)
    <> " entries on "
    <> int.to_string(process_count)
    <> " processes.",
  )

  let subject = process.new_subject()
  let assert Ok(started) =
    actor.new(ActorState(process_count, [], subject))
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

type FetchState(a) {
  ActorState(
    process_count: Int,
    entries: List(a),
    subject: process.Subject(Result(List(a), WebshopInitError)),
  )
}

fn handle(
  state: FetchState(a),
  msg: FetchMessage(a),
) -> actor.Next(FetchState(a), FetchMessage(a)) {
  case msg {
    Success(entries) -> {
      let new_process_count = state.process_count - 1
      let entries = list.append(state.entries, entries)
      echo list.length(entries)
      case new_process_count == 0 {
        False ->
          actor.continue(
            ActorState(..state, process_count: new_process_count, entries:),
          )
        True -> {
          actor.send(state.subject, Ok(entries))
          actor.stop()
        }
      }
    }
    Failure(err) -> {
      actor.send(state.subject, Error(err))
      actor.stop_abnormal("An error occurred while fetching data.")
    }
  }
}

fn filter_if_cached(
  entries: List(ResourceEntry),
  is_cached: fn(String) -> Result(Bool, WebshopInitError),
) -> Result(List(ResourceEntry), WebshopInitError) {
  filter_if_cached_loop(entries, is_cached, [])
}

fn filter_if_cached_loop(
  entries: List(ResourceEntry),
  is_cached: fn(String) -> Result(Bool, WebshopInitError),
  acc: List(ResourceEntry),
) -> Result(List(ResourceEntry), WebshopInitError) {
  case entries {
    [] -> Ok(acc)
    [entry, ..rest] ->
      case is_cached(entry.name) {
        Ok(False) -> filter_if_cached_loop(rest, is_cached, acc)
        Ok(True) -> filter_if_cached_loop(rest, is_cached, [entry, ..acc])
        Error(err) -> Error(err)
      }
  }
}

// TODO: pass callback parameter so items can be inserted on the fly into the database
pub fn fetch_item_categories(
  is_cached: fn(String) -> Result(Bool, WebshopInitError),
) -> Result(List(Category), WebshopInitError) {
  use entries <- result.try(fetch_resource_entries(endpoint_item_categories))
  use entries <- result.try(filter_if_cached(entries, is_cached))
  case entries {
    [] -> Ok([])
    entries -> parallel_fetch_resources(entries, types.category_decoder())
  }
}

pub fn fetch_items(
  is_cached: fn(String) -> Result(Bool, WebshopInitError),
) -> Result(List(Item), WebshopInitError) {
  use entries <- result.try(fetch_resource_entries(endpoint_items))
  use entries <- result.try(filter_if_cached(entries, is_cached))
  case entries {
    [] -> Ok([])
    entries -> parallel_fetch_resources(entries, types.item_decoder())
  }
}
