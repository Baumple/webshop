import cake/adapter/sqlite
import cake/insert
import cake/join
import cake/select
import cake/where
import gleam/dict
import gleam/dynamic/decode
import gleam/list
import gleam/result
import sqlight.{type Connection}
import wisp

import pokeshop/data/db/helper
import pokeshop/data/poke_api
import pokeshop/data/types.{type Category}
import pokeshop/error.{type WebshopInitError}

fn category_exists(
  db: Connection,
  name: String,
) -> Result(Bool, WebshopInitError) {
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

pub fn update_categories(db: Connection) -> Result(Nil, WebshopInitError) {
  let res =
    poke_api.fetch_item_categories(category_exists(db, _), insert_categories(
      db,
      _,
    ))

  case res {
    Ok(Nil) -> {
      wisp.log_info("Updated categories.")
      Ok(Nil)
    }
    Error(err) -> Error(err)
  }
}

fn insert_categories(
  db: sqlight.Connection,
  categories: List(Category),
) -> Result(Nil, sqlight.Error) {
  use <- helper.require_not_empty(categories, Ok(Nil))
  let res =
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
    |> helper.run_write_query(db)
  use _ <- result.try(res)
  insert_category_names(db, categories)
}

fn insert_category_names(
  db: Connection,
  cs: List(Category),
) -> Result(Nil, sqlight.Error) {
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
  }
  |> result.all
  |> result.replace(Nil)
}

pub fn get_categories(db: Connection) -> Result(List(types.PartialCategory), sqlight.Error) {
  select.new()
  |> select.select_cols(["categories.name", "cn.name"])
  |> select.from_table("categories")
  |> select.join(
    join.table("category_names")
    |> join.inner(
      on: where.eq(where.col("id"), where.col("cn.category_id")),
      alias: "cn",
    ),
  )
  |> select.where(where.eq(where.col("cn.language"), where.string("en")))
  |> select.order_by_asc(by: "cn.name")
  |> select.to_query()
  |> sqlite.run_read_query(types.partial_category_decoder(), db)
}
