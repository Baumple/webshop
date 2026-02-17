import cake/adapter/sqlite
import cake/insert
import gleam/dict
import gleam/dynamic/decode
import gleam/list
import gleam/result
import sqlight.{type Connection}
import wisp

import webshop/data/poke_api
import webshop/data/types.{type Category}
import webshop/error.{type WebshopInitError}

pub fn update_categories(
  db: Connection,
  continue,
) -> Result(Connection, WebshopInitError) {
  use categories <- result.try(poke_api.fetch_item_categories())
  use _ <- result.try(insert_categories(db, categories))
  case insert_category_names(db, categories) {
    Ok(_) -> {
      wisp.log_info("Updated categories.")
      continue()
    }
    Error(err) -> Error(err)
  }
}

fn insert_categories(
  db: sqlight.Connection,
  categories: List(Category),
) -> Result(Nil, WebshopInitError) {
  list.map(categories, fn(c) {
    insert.row([
      insert.int(c.id),
      insert.string(c.name),
      insert.string(c.pocket),
    ])
  })
  |> insert.from_values(table_name: "categories", columns: [
    "id",
    "name",
    "pocket",
  ])
  |> insert.to_query()
  |> sqlite.run_write_query(decode.dynamic, db)
  |> result.replace(Nil)
  |> result.map_error(error.DBError)
}

fn insert_category_names(
  db: Connection,
  cs: List(Category),
) -> Result(Nil, WebshopInitError) {
  {
    use c <- list.map(cs)
    list.map(dict.to_list(c.names), fn(language_name) {
      let #(language, name) = language_name
      insert.row([
        insert.int(c.id),
        insert.string(language),
        insert.string(name),
      ])
    })
    |> insert.from_values(table_name: "category_names", columns: [
      "category_id",
      "language",
      "name",
    ])
    |> insert.to_query()
    |> sqlite.run_write_query(decode.dynamic, db)
    |> result.map_error(error.DBError)
  }
  |> result.all
  |> result.replace(Nil)
}
