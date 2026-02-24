import gleam/erlang/process
import gleam/string
import radiate

import mist
import wisp
import wisp/wisp_mist

import webshop/context
import webshop/error
import webshop/router

fn handle_startup_error(err: error.WebshopInitError) -> Nil {
  let log_err = fn(prefix: String, err: a) {
    wisp.log_critical(prefix <> ": " <> string.inspect(err))
  }
  case err {
    error.HttpcError(err) -> log_err("Failed to request data from api", err)

    error.DBError(err) -> log_err("Failed to initialize database", err)

    error.ParseError(err) -> log_err("Failed to acquire data from api", err)
  }
}

fn start_server(context: context.Context) -> Nil {
  let assert Ok(_) =
    wisp_mist.handler(router.handler(context, _), wisp.random_string(64))
    |> mist.new()
    |> mist.port(8000)
    |> mist.start()
  process.sleep_forever()
}

pub fn main() -> Nil {
  wisp.configure_logger()
  let assert Ok(_) =
    radiate.new()
    |> radiate.add_dir("src/webshop/html/")
    |> radiate.add_dir("src/webshop/router/")
    |> radiate.start
  case context.new() {
    Error(err) -> handle_startup_error(err)
    Ok(context) -> start_server(context)
  }
}
