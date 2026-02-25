import gleam/httpc
import gleam/json
import sqlight
import wisp

pub type WebshopInitError {
  DBError(sqlight.Error)
  HttpcError(httpc.HttpError)
  ParseError(json.DecodeError)
}

pub fn log_sql_error(err: sqlight.Error) -> wisp.Response {
  wisp.log_critical("SQL error: " <> err.message)
  wisp.internal_server_error()
}
