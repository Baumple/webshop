import gleam/dynamic/decode
import gleam/http/request
import gleam/http/response
import gleam/httpc
import gleam/int
import gleam/json
import gleam/list
import gleam/result
import gleam/uri
import sqlight
import wisp

import webshop/data/types.{type Category, type Item}
import webshop/error.{type WebshopInitError}

const base_url = "https://pokeapi.co/api/v2/"

const endpoint_item_categories = "item-category"

const endpoint_items = "item"

const batch_size = 60

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

// fn log_process(_state: FetchState(a), new_progress_count: Int) -> Nil {
//   wisp.log_info(
//     "Remaining number of processes: " <> int.to_string(new_progress_count),
//   )
// }

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

/// Fetches resources in batches of `batch_size` size.
/// Whenever a batch has been fetched, it is inserted into the database.
fn fetch_resources(
  entries: List(ResourceEntry),
  insert_resource: fn(List(a)) -> Result(Nil, sqlight.Error),
  decoder: decode.Decoder(a),
) -> Result(Nil, WebshopInitError) {
  let batches = list.sized_chunk(entries, batch_size)
  let batch_count = list.length(batches)
  fetch_resources_loop(batches, batch_count, 0, insert_resource, decoder)
}

fn fetch_resources_loop(
  batches: List(List(ResourceEntry)),
  batch_count: Int,
  batch_index: Int,
  insert_resource: fn(List(a)) -> Result(Nil, sqlight.Error),
  decoder: decode.Decoder(a),
) -> Result(Nil, WebshopInitError) {
  case batches {
    [] -> Ok(Nil)
    [batch, ..remaining] -> {
      log_progress(batch_count, batch_index)
      use fetched <- result.try(
        list.map(batch, fetch_resource(decoder, _)) |> result.all,
      )
      use _ <- result.try(
        insert_resource(fetched) |> result.map_error(error.DBError),
      )

      fetch_resources_loop(
        remaining,
        batch_count,
        batch_index + 1,
        insert_resource,
        decoder,
      )
    }
  }
}

fn log_progress(batch_count: Int, batch_index: Int) {
  wisp.log_info(
    int.to_string(batch_index)
    <> "/"
    <> int.to_string(batch_count)
    <> " batches fetched (batch size: "
    <> int.to_string(batch_size)
    <> ")",
  )
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
      fetch_resources(entries, insert_categories, types.category_decoder())
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
    entries -> fetch_resources(entries, insert_items, types.item_decoder())
  }
}
