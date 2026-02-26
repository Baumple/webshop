import gleam/dynamic/decode
import gleam/erlang/process
import gleam/http/request
import gleam/http/response
import gleam/httpc
import gleam/json
import gleam/list
import gleam/otp/actor
import gleam/result
import gleam/uri

import webshop/data/types.{type Category, type Item}
import webshop/error.{type WebshopInitError}

const base_url = "https://pokeapi.co/api/v2/"

const endpoint_item_categories = "item-category"

const endpoint_items = "item"

type ResourceUrl =
  String

fn resource_entry_decoder() -> decode.Decoder(ResourceUrl) {
  use url <- decode.field("url", decode.string)
  decode.success(url)
}

fn fetch_resource_entries(
  resource: String,
) -> Result(List(ResourceUrl), WebshopInitError) {
  let assert Ok(uri) = uri.parse(base_url <> resource <> "?limit=10000")
  let assert Ok(req) = request.from_uri(uri)
  use resp <- result.try(httpc.send(req) |> result.map_error(error.HttpcError))
  parse_resource_entries(resp)
}

fn parse_resource_entries(
  resp: response.Response(String),
) -> Result(List(ResourceUrl), WebshopInitError) {
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

fn fetch_resource_from_url(
  decoder: decode.Decoder(a),
  url: String,
) -> Result(a, WebshopInitError) {
  let assert Ok(uri) = uri.parse(url)
  let assert Ok(req) = request.from_uri(uri)

  use resp <- result.try(httpc.send(req) |> result.map_error(error.HttpcError))
  json.parse(resp.body, decoder) |> result.map_error(error.ParseError)
}

type Message(a) {
  Success(List(a))
  Failure(WebshopInitError)
}

fn fetch_resources(
  resource: String,
  decoder: decode.Decoder(a),
) -> Result(List(a), WebshopInitError) {
  use entries <- result.try(fetch_resource_entries(resource))
  let entry_count = list.length(entries)
  let process_count = 10
  let entries_per_process = entry_count / process_count

  let chunked_entries = list.sized_chunk(entries, entries_per_process)

  let subject = process.new_subject()
  let assert Ok(started) =
    actor.new(ActorState(process_count, [], subject))
    |> actor.on_message(handle)
    |> actor.start()
  let accumulator = started.data

  list.map(chunked_entries, fn(entries) {
    process.spawn(fn() {
      let result =
        list.map(entries, fetch_resource_from_url(decoder, _))
        |> result.all()
      case result {
        Ok(res) -> actor.send(accumulator, Success(res))
        Error(err) -> actor.send(accumulator, Failure(err))
      }
    })
  })

  process.receive_forever(subject)
}

type ActorState(a) {
  ActorState(
    process_count: Int,
    entries: List(a),
    subject: process.Subject(Result(List(a), WebshopInitError)),
  )
}

fn handle(
  state: ActorState(a),
  msg: Message(a),
) -> actor.Next(ActorState(a), Message(a)) {
  case msg {
    Success(entries) -> {
      let new_process_count = state.process_count - 1
      case new_process_count == 0 {
        False ->
          actor.continue(
            ActorState(
              ..state,
              process_count: new_process_count,
              entries: list.append(entries, state.entries),
            ),
          )
        True -> {
          actor.send(state.subject, Ok(state.entries))
          actor.stop()
        }
      }
    }
    Failure(err) -> {
      actor.send(state.subject, Error(err))
      actor.stop()
    }
  }
}

// TODO: pass callback parameter so items can be inserted on the fly into the database
pub fn fetch_item_categories() -> Result(List(Category), WebshopInitError) {
  fetch_resources(endpoint_item_categories, types.category_decoder())
}

pub fn fetch_items() -> Result(List(Item), WebshopInitError) {
  fetch_resources(endpoint_items, types.item_decoder())
}
