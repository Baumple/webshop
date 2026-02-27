import dream_ets/table
import gleam/httpc
import gleam/json
import gleam/string
import sqlight
import wisp

pub type WebshopInitError {
  DBError(sqlight.Error)
  HttpcError(httpc.HttpError)
  ParseError(json.DecodeError)
  SessionError(table.EtsError)
}

pub fn log_sql_error(err: sqlight.Error) -> wisp.Response {
  wisp.log_critical("SQL error: " <> err.message)
  wisp.internal_server_error()
}

pub fn log_ets_error(err: table.EtsError) -> wisp.Response {
  wisp.log_critical("ETS error: " <> string.inspect(err))
  wisp.internal_server_error()
}
