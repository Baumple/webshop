import cake/adapter/sqlite
import cake/insert
import gleam/dynamic/decode
import gleam/list
import gleam/option
import gleam/result
import sqlight.{type Connection}
import wisp

import webshop/data/poke_api
import webshop/data/types.{type Item}
import webshop/error.{type WebshopInitError}

pub fn update_items(
  db: Connection,
  continue,
) -> Result(Connection, WebshopInitError) {
  use items <- result.try(poke_api.fetch_items())
  wisp.log_info("Updated items.")
  continue()
}

fn insert_items(db: Connection, items: List(Item)) -> Result(Nil, sqlight.Error) {
  list.map(items, fn(item) {
    insert.row([
      insert.int(item.id),
      insert.string(item.name),
      insert.string(item.sprite |> option.unwrap(or: "")),
      insert.string(item.category),
      insert.int(item.cost),
    ])
  })
  |> insert.from_values(table_name: "items", columns: [
    "id",
    "name",
    "sprite",
    "category",
    "cost",
  ])
  |> insert.to_query
  |> sqlite.run_write_query(decode.dynamic, db)
  |> result.replace(Nil)
}

fn insert_item(db: Connection, item: Item) -> Result(Nil, sqlight.Error) {
  insert_items(db, [item])
}
