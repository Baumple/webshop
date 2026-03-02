import cake/adapter/sqlite
import cake/insert
import gleam/dynamic/decode
import gleam/result
import sqlight

pub fn require_not_empty(
  l: List(a),
  otherwise otherwise: b,
  then continue: fn() -> b,
) -> b {
  case l {
    [] -> otherwise
    _ -> continue()
  }
}

pub fn run_write_query(
  query: insert.WriteQuery(a),
  db: sqlight.Connection,
) -> Result(Nil, sqlight.Error) {
  sqlite.run_write_query(query, decoder: decode.dynamic, db_connection: db)
  |> result.replace(Nil)
}
