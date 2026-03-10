import gleam/result
import cake/insert
import webshop/data/types.{type Customer}
import cake/adapter/sqlite
import cake/where
import cake/select
import gleam/dynamic/decode
import sqlight.{type Connection}

import webshop/data/db/db_result.{type SqlResult}

pub fn get_username_password_hash(
  db: Connection,
  username: String,
) -> SqlResult(String) {
  let res =
    sqlight.query(
      username_password_query,
      db,
      [sqlight.text(username)],
      decode.list(decode.string),
    )
  case res {
    Ok([[hash]]) -> db_result.Success(hash)
    Ok([]) -> db_result.NotFound
    Error(err) -> db_result.FailedQuery(err)
    _ -> panic as "Invalid sql data."
  }
}

const username_password_query = "
  SELECT hash FROM customers WHERE username = ?
"

pub fn username_exists(
  db: Connection,
  username: String,
) -> Result(Bool, sqlight.Error) {
  let res =
    select.new()
    |> select.from_table("customers")
    |> select.select_col("username")
    |> select.where(where.eq(where.col("username"), where.string(username)))
    |> select.limit(1)
    |> select.to_query
    |> sqlite.run_read_query(decode.dynamic, db)

  case res {
    Ok([]) -> Ok(False)
    Ok([_]) -> Ok(True)
    Ok(_) -> panic as "Multiple users with same username"
    Error(err) -> Error(err)
  }
}

pub fn insert_customer(
  customer: Customer,
  db: Connection,
) -> Result(Nil, sqlight.Error) {
  insert.from_records(
    table_name: "customers",
    columns: [
      "username",
      "name",
      "surname",
      "street",
      "house_number",
      "postal_code",
      "location",
      "bin",
      "institution",
      "hash",
    ],
    records: [customer],
    encoder: types.customer_to_insert_row,
  )
  |> insert.to_query()
  |> sqlite.run_write_query(decode.dynamic, db)
  |> result.replace(Nil)
}
