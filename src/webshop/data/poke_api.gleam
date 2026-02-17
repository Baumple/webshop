import gleam/dynamic/decode
import gleam/http/request
import gleam/http/response
import gleam/httpc
import gleam/json
import gleam/result
import gleam/uri
import webshop/error.{type WebshopInitError}

const base_url = "https://pokeapi.co/api/v2/"

import webshop/data/types.{type Category}

pub fn fetch_categories() -> Result(List(Category), WebshopInitError) {
  let assert Ok(uri) = uri.parse(base_url <> "item-category")
  let assert Ok(req) = request.from_uri(uri)
  use category_names <- result.try(
    httpc.send(req) |> result.map_error(error.HttpcError),
  )
  todo
}

fn parse_categorie_names(
  resp: response.Response(String),
) -> Result(List(String), WebshopInitError) {
  let decoder = {
    use results <- decode.field("results", decode.list(decode.string))
    decode.success(results)
  }

  json.parse(resp.body, decoder)
  |> result.map_error(error.ParseError)
}

fn fetch_category_attributes(name: String) -> Result(Category, WebshopInitError) {
  todo
}
