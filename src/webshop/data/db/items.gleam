import cake/adapter/sqlite
import cake/insert
import cake/select
import cake/where
import gleam/bool
import gleam/dict
import gleam/dynamic/decode
import gleam/list
import gleam/option
import gleam/result
import sqlight.{type Connection}
import wisp

import webshop/data/db/db_result.{type SqlResult}
import webshop/data/db/helper
import webshop/data/poke_api
import webshop/data/types.{
  type EffectEntry, type Item, type PartialItem, EffectEntry, PartialItem,
}
import webshop/error.{type WebshopInitError}

fn item_exists(db: Connection, name: String) -> Result(Bool, WebshopInitError) {
  let res =
    select.new()
    |> select.from_table("items")
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

pub fn update_items(db: Connection) -> Result(Nil, WebshopInitError) {
  let res = poke_api.fetch_items(item_exists(db, _), insert_items(db, _))
  case res {
    Ok(Nil) -> {
      wisp.log_info("Updated items.")
      Ok(Nil)
    }
    Error(err) -> Error(err)
  }
}

pub fn item_to_insert_row(item: Item) -> insert.InsertRow {
  insert.row([
    insert.int(item.id),
    insert.string(item.name),
    insert.string(
      item.sprite
      |> option.unwrap(
        or: "https://github.com/PokeAPI/sprites/blob/master/sprites/items/data-card-01.png?raw=true",
      ),
    ),
    insert.string(item.category),
    insert.int(item.cost),
  ])
}

// PERF: this codes creates a new prepared statement per item which may be
//       undesirable

fn insert_item_names(
  db: Connection,
  items: List(Item),
) -> Result(Nil, sqlight.Error) {
  list.map(items, fn(item) {
    use <- bool.guard(when: dict.is_empty(item.names), return: Ok(Nil))

    list.map(item.names |> dict.to_list, fn(names) {
      let #(language, name) = names
      insert.row([
        insert.int(item.id),
        insert.string(language),
        insert.string(name),
      ])
    })
    |> insert.from_values(table_name: "item_names", columns: [
      "item_id",
      "language",
      "name",
    ])
    |> insert.to_query
    |> sqlite.run_write_query(decode.dynamic, db)
    |> result.replace(Nil)
  })
  |> result.all
  |> result.replace(Nil)
}

fn insert_item_attributes(
  db: Connection,
  items: List(Item),
) -> Result(Nil, sqlight.Error) {
  list.map(items, fn(item) {
    use <- bool.guard(when: list.is_empty(item.attributes), return: Ok(Nil))

    list.map(item.attributes, fn(attribute) {
      insert.row([insert.int(item.id), insert.string(attribute)])
    })
    |> insert.from_values(table_name: "item_attributes", columns: [
      "item_id",
      "attribute",
    ])
    |> insert.to_query
    |> sqlite.run_write_query(decode.dynamic, db)
    |> result.replace(Nil)
  })
  |> result.all
  |> result.replace(Nil)
}

fn insert_item_effect_entries(
  db: Connection,
  items: List(Item),
) -> Result(Nil, sqlight.Error) {
  list.map(items, fn(item) {
    use <- bool.guard(when: dict.is_empty(item.effect_entries), return: Ok(Nil))
    list.map(item.effect_entries |> dict.to_list, fn(effect) {
      let #(language, entry) = effect
      insert.row([
        insert.int(item.id),
        insert.string(language),
        insert.string(entry.effect),
        insert.string(entry.short_effect),
      ])
    })
    |> insert.from_values(table_name: "item_effect_entries", columns: [
      "item_id",
      "language",
      "effect",
      "short_effect",
    ])
    |> insert.to_query
    |> sqlite.run_write_query(decode.dynamic, db)
    |> result.replace(Nil)
  })
  |> result.all
  |> result.replace(Nil)
}

fn insert_items(db: Connection, items: List(Item)) -> Result(Nil, sqlight.Error) {
  use <- helper.require_not_empty(items, otherwise: Ok(Nil))
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
  use _ <- result.try(insert_item_effect_entries(db, items))
  insert_item_attributes(db, items)
}

pub fn partial_item_decoder() -> decode.Decoder(PartialItem) {
  use id <- decode.field(0, decode.int)
  use name <- decode.field(1, decode.string)
  use sprite <- decode.field(2, decode.string)
  use category <- decode.field(3, decode.string)
  use cost <- decode.field(4, decode.int)
  decode.success(PartialItem(id:, name:, sprite:, category:, cost:))
}

pub fn get_items_range(
  db: Connection,
  offset offset: Int,
  count limit: Int,
) -> Result(List(PartialItem), sqlight.Error) {
  default_partial_item_query()
  |> select.offset(offset)
  |> select.limit(limit)
  |> select.to_query()
  |> sqlite.run_read_query(partial_item_decoder(), db)
}

fn default_partial_item_query() {
  select.new()
  |> select.select_cols([
    "id",
    "name",
    "sprite",
    "category",
    "cost",
  ])
  |> select.from_table("items")
}

fn get_partial_item_by_id(db: Connection, id: Int) -> SqlResult(PartialItem) {
  let res =
    default_partial_item_query()
    |> select.where(where.eq(where.col("id"), where.int(id)))
    |> select.to_query()
    |> sqlite.run_read_query(partial_item_decoder(), db)

  case res {
    Ok([partial]) -> db_result.Success(partial)
    Ok([]) -> db_result.NotFound
    Ok(_) -> panic as "Illegal state of data."
    Error(err) -> db_result.FailedQuery(err)
  }
}

fn decode_effect_entry() {
  use language <- decode.field(1, decode.string)
  use effect <- decode.field(2, decode.string)
  use short_effect <- decode.field(3, decode.string)
  decode.success(#(language, EffectEntry(effect:, short_effect:)))
}

fn get_effect_entries_by_id(
  db: Connection,
  id: Int,
) -> SqlResult(dict.Dict(String, EffectEntry)) {
  let res =
    select.new()
    |> select.from_table("item_effect_entries")
    |> select.where(where.eq(where.col("item_id"), where.int(id)))
    |> select.to_query()
    |> sqlite.run_read_query(decode_effect_entry(), db)
  case res {
    Ok(entries) -> db_result.Success(dict.from_list(entries))
    Error(err) -> db_result.FailedQuery(err)
  }
}

fn attribute_decoder() -> decode.Decoder(String) {
  use attribute <- decode.field(1, decode.string)
  decode.success(attribute)
}

fn get_attributes_by_id(db: Connection, id: Int) -> SqlResult(List(String)) {
  let res =
    select.new()
    |> select.from_table("item_attributes")
    |> select.where(where.eq(where.col("item_id"), where.int(id)))
    |> select.to_query()
    |> sqlite.run_read_query(attribute_decoder(), db)

  case res {
    Ok(attributes) -> db_result.Success(attributes)
    Error(err) -> db_result.FailedQuery(err)
  }
}

fn decode_item_name() -> decode.Decoder(#(String, String)) {
  use language <- decode.field(1, decode.string)
  use name <- decode.field(2, decode.string)
  decode.success(#(language, name))
}

fn get_item_names_by_id(
  db: Connection,
  id: Int,
) -> SqlResult(dict.Dict(String, String)) {
  let res =
    select.new()
    |> select.from_table("item_names")
    |> select.where(where.eq(where.col("item_id"), where.int(id)))
    |> select.to_query()
    |> sqlite.run_read_query(decode_item_name(), db)
  case res {
    Ok(decoded) -> db_result.Success(dict.from_list(decoded))
    Error(err) -> db_result.FailedQuery(err)
  }
}

pub fn get_item_by_id(db: Connection, id: Int) -> SqlResult(Item) {
  use partial <- db_result.try(get_partial_item_by_id(db, id))
  let PartialItem(id:, name:, sprite:, category:, cost:) = partial
  use effect_entries <- db_result.try(get_effect_entries_by_id(db, id))
  use attributes <- db_result.try(get_attributes_by_id(db, id))
  use names <- db_result.try(get_item_names_by_id(db, id))

  db_result.Success(types.Item(
    id:,
    name:,
    cost:,
    category:,
    attributes:,
    names:,
    effect_entries:,
    sprite: option.Some(sprite),
  ))
}
