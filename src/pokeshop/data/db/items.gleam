import cake/adapter/sqlite
import cake/combined
import cake/delete
import cake/insert
import cake/join
import cake/select
import cake/update
import cake/where
import gleam/bool
import gleam/dict
import gleam/dynamic/decode
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import sqlight.{type Connection}
import wisp

import pokeshop/data/db/db_result.{type SqlResult}
import pokeshop/data/db/helper
import pokeshop/data/db/query
import pokeshop/data/poke_api
import pokeshop/data/types.{
  type EffectEntry, type Item, type PartialItem, EffectEntry, PartialItem,
}
import pokeshop/error.{type WebshopInitError}

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

fn where_attributes_query(
  s: combined.Select,
  query: query.Query,
) -> combined.Select {
  case query.attribute {
    option.Some(attr) ->
      select.join(
        s,
        join.inner(
          join.table("item_attributes"),
          on: where.and([
            where.eq(where.col("items.id"), where.col("attributes.item_id")),
            where.eq(where.col("attributes.attribute"), where.string(attr)),
          ]),
          alias: "attributes",
        ),
      )
    option.None -> s
  }
}

fn where_category_query(
  s: combined.Select,
  query: query.Query,
) -> combined.Select {
  case query.category {
    None -> s
    Some(cat) ->
      select.where(s, where.eq(where.col("category"), where.string(cat)))
  }
}

fn where_text_query(s: combined.Select, query: query.Query) -> combined.Select {
  case query.text {
    None -> s
    Some(text) ->
      select.where(s, where.like(where.col("name"), "%" <> text <> "%"))
  }
}

fn where_query(s: combined.Select, query: query.Query) -> combined.Select {
  s
  |> where_text_query(query)
  |> where_category_query(query)
  |> where_attributes_query(query)
}

const partial_item_cols = [
  "id",
  "name",
  "sprite",
  "category",
  "cost",
]

pub fn partial_item_decoder() -> decode.Decoder(PartialItem) {
  use id <- decode.field(0, decode.int)
  use name <- decode.field(1, decode.string)
  use sprite <- decode.field(2, decode.string)
  use category <- decode.field(3, decode.string)
  use cost <- decode.field(4, decode.int)
  decode.success(PartialItem(id:, name:, sprite:, category:, cost:))
}

pub fn get_partial_items_range(
  db: Connection,
  query: query.Query,
  offset offset: Int,
  count limit: Int,
) -> Result(List(PartialItem), sqlight.Error) {
  select.new()
  |> select.select_cols(partial_item_cols)
  |> select.from_table("items")
  |> select.offset(offset)
  |> select.limit(limit)
  |> select.order_by_asc("cost")
  |> select.where(where.gt(where.col("cost"), where.int(0)))
  |> where_query(query)
  |> select.to_query()
  |> sqlite.run_read_query(partial_item_decoder(), db)
}

pub fn get_item_count(
  db: Connection,
  query: query.Query,
) -> Result(Int, sqlight.Error) {
  let res =
    select.new()
    |> select.select_col("COUNT(*) as count")
    |> select.from_table("items")
    |> where_query(query)
    |> select.where(where.gt(where.col("cost"), where.int(0)))
    |> select.to_query()
    |> sqlite.run_read_query(
      {
        use count <- decode.field(0, decode.int)
        decode.success(count)
      },
      db,
    )

  case res {
    Ok([count]) -> Ok(count)
    Ok(_) -> panic as "Invalid sql data."
    Error(err) -> Error(err)
  }
}

fn get_partial_item_by_id(db: Connection, id: Int) -> SqlResult(PartialItem) {
  let res =
    select.new()
    |> select.select_cols(partial_item_cols)
    |> select.from_table("items")
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
  use language <- decode.field(0, decode.string)
  use effect <- decode.field(1, decode.string)
  use short_effect <- decode.field(2, decode.string)
  decode.success(#(language, EffectEntry(effect:, short_effect:)))
}

fn get_effect_entries_by_id(
  db: Connection,
  id: Int,
) -> SqlResult(dict.Dict(String, EffectEntry)) {
  let res =
    select.new()
    |> select.select_cols(["language", "effect", "short_effect"])
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
    sprite: Some(sprite),
  ))
}

fn cart_item_decoder() -> decode.Decoder(#(PartialItem, Int)) {
  use partial_item <- decode.then(partial_item_decoder())
  use count <- decode.field(list.length(partial_item_cols), decode.int)
  decode.success(#(partial_item, count))
}

pub fn get_cart_items(
  db: Connection,
  username: String,
) -> Result(types.Cart, sqlight.Error) {
  select.new()
  |> select.select_cols(list.append(partial_item_cols, ["cart_items.count"]))
  |> select.from_table(name: "cart_items")
  |> select.join(join.inner(
    join.table("items"),
    alias: "items",
    on: where.eq(where.col("cart_items.item_id"), where.col("items.id")),
  ))
  |> select.where(where.eq(
    where.col("cart_items.username"),
    where.string(username),
  ))
  |> select.to_query()
  |> sqlite.run_read_query(cart_item_decoder(), db)
  |> result.map(types.Cart(username:, items: _))
}

pub fn add_item_to_cart(
  db: Connection,
  username: String,
  item_id: Int,
) -> Result(Nil, sqlight.Error) {
  insert.from_values(
    table_name: "cart_items",
    columns: [
      "username",
      "item_id",
      "count",
    ],
    values: [
      insert.row([
        insert.string(username),
        insert.int(item_id),
        insert.int(1),
      ]),
    ],
  )
  |> insert.on_columns_conflict_update(
    columns: ["username", "item_id"],
    where: where.is_true(where.true()),
    update: update.new()
      |> update.set(update.set_expression("count", "count + 1")),
  )
  |> insert.to_query()
  |> sqlite.run_write_query(decode.dynamic, db)
  |> result.replace(Nil)
}

pub fn remove_item_from_cart(
  db: Connection,
  username: String,
  item_id: Int,
) -> Result(Nil, sqlight.Error) {
  update.new()
  |> update.table("cart_items")
  |> update.set(update.set_expression("count", "count - 1"))
  |> update.where(where.eq(where.col("username"), where.string(username)))
  |> update.where(where.eq(where.col("item_id"), where.int(item_id)))
  |> update.to_query()
  |> sqlite.run_write_query(decode.dynamic, db)
  |> result.replace(Nil)
}

pub fn delete_item_from_cart(
  db: Connection,
  username: String,
  item_id: Int,
) -> Result(Nil, sqlight.Error) {
  delete.new()
  |> delete.table("cart_items")
  |> delete.where(where.eq(where.col("username"), where.string(username)))
  |> delete.where(where.eq(where.col("item_id"), where.int(item_id)))
  |> delete.to_query()
  |> sqlite.run_write_query(decode.dynamic, db)
  |> result.replace(Nil)
}

pub fn clear_cart(
  db: Connection,
  username: String,
) -> Result(Nil, sqlight.Error) {
  delete.new()
  |> delete.table("cart_items")
  |> delete.where(where.eq(where.col("username"), where.string(username)))
  |> delete.to_query()
  |> sqlite.run_write_query(decode.dynamic, db)
  |> result.replace(Nil)
}
