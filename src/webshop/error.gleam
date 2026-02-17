import gleam/json
import gleam/httpc
import sqlight

pub type WebshopInitError {
  DBError(sqlight.Error)
  HttpcError(httpc.HttpError)
  ParseError(json.DecodeError)
}
