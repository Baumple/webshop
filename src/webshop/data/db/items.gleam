import cake/adapter/sqlite
import cake/insert
import cake/select
import cake/where
import gleam/dict
import gleam/dynamic/decode
import gleam/list
import gleam/option
import gleam/result
import sqlight.{type Connection}
import wisp

import webshop/data/poke_api
import webshop/data/types.{type Item}
import webshop/error.{type WebshopInitError}

fn item_exists(db: Connection, name: String) -> Result(Bool, WebshopInitError) {
  let res =
    select.new()
    |> select.from_table("categories")
    |> select.where(where.eq(where.col("name"), where.string(name)))
    |> select.to_query()
    |> sqlite.run_read_query(decode.dynamic, db)
    |> result.map_error(error.DBError)
  case res {
    Ok([_]) -> Ok(True)
    Ok([]) -> Ok(False)
    Ok([_, _, ..]) -> panic as "Illegal SQL result"
    Error(err) -> Error(err)
  }
}

pub fn update_items(
  db: Connection,
  continue,
) -> Result(Connection, WebshopInitError) {
  use items <- result.try(poke_api.fetch_items(item_exists(db, _)))
  use _ <- result.try(
    insert_items(db, items) |> result.map_error(error.DBDataError),
  )
  wisp.log_info("Updated items.")
  continue()
}

pub fn item_to_insert_row(item: Item) -> insert.InsertRow {
  insert.row([
    insert.int(item.id),
    insert.string(item.name),
    insert.string(item.sprite |> option.unwrap(or: "")),
    insert.string(item.category),
    insert.int(item.cost),
  ])
}

fn insert_item_names(
  db: Connection,
  items: List(Item),
) -> Result(Nil, sqlight.Error) {
  list.map(items, fn(item) {
    list.map(item.names |> dict.to_list, fn(names) {
      let #(language, name) = names
      insert.row([
        insert.int(item.id),
        insert.string(language),
        insert.string(name),
      ])
    })
  })
  |> list.flatten
  |> insert.from_values(table_name: "item_names", columns: [
    "item_id",
    "language",
    "name",
  ])
  |> insert.to_query
  |> sqlite.run_write_query(decode.dynamic, db)
  |> result.replace(Nil)
}

fn insert_item_attributes(
  db: Connection,
  items: List(Item),
) -> Result(Nil, sqlight.Error) {
  list.map(items, fn(item) {
    list.map(item.attributes, fn(attribute) {
      insert.row([insert.int(item.id), insert.string(attribute)])
    })
  })
  |> list.flatten
  |> insert.from_values(table_name: "item_attributes", columns: [
    "item_id",
    "name",
  ])
  |> insert.to_query
  |> sqlite.run_write_query(decode.dynamic, db)
  |> result.replace(Nil)
}

fn insert_item_effetc_entries(
  db: Connection,
  items: List(Item),
) -> Result(Nil, sqlight.Error) {
  list.map(items, fn(item) {
    list.map(item.effect_entries |> dict.to_list, fn(effect) {
      let #(language, entry) = effect
      insert.row([
        insert.int(item.id),
        insert.string(language),
        insert.string(entry.effect),
        insert.string(entry.short_effect),
      ])
    })
  })
  |> list.flatten
  |> insert.from_values(table_name: "item_effect_entries", columns: [
    "item_id",
    "language",
    "effect",
    "short_effect",
  ])
  |> insert.to_query
  |> sqlite.run_write_query(decode.dynamic, db)
  |> result.replace(Nil)
}

fn insert_items(db: Connection, items: List(Item)) -> Result(Nil, sqlight.Error) {
  use _ <- result.try(
    insert.from_records(
      table_name: "items",
      columns: ["id", "name", "sprite", "category", "cost"],
      records: items,
      encoder: item_to_insert_row,
    )
    |> insert.to_query
    |> sqlite.run_write_query(decode.dynamic, db)
    |> result.replace(Nil),
  )
  use _ <- result.try(insert_item_names(db, items))
  use _ <- result.try(insert_item_effetc_entries(db, items))
  insert_item_attributes(db, items)
}
