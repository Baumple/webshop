import argus
import gleam/bit_array
import gleam/list
import gleam/result
import webshop/data/db
import webshop/error
import wisp.{type Request, type Response}

import webshop/context.{type Context}

pub fn handle(ctx: Context, request: Request) -> Response {
  use formdata <- wisp.require_form(request)
  let result = {
    use username <- result.try(list.key_find(formdata.values, "username"))
    use password <- result.try(list.key_find(formdata.values, "password"))
    Ok(#(username, password))
  }

  case result {
    Ok(#(username, password)) -> perform_login(ctx, username, password)
    Error(Nil) -> wisp.bad_request("Login form data is invalid.")
  }
}

fn perform_login(ctx: Context, username: String, password: String) -> Response {
  case db.get_username_password_hash(ctx.db, username) {
    Error(error.InvalidUsername) -> invalid_login(ctx)
    Error(error.DBError(err)) -> {
      wisp.log_critical("Database error: " <> err.message)
      wisp.internal_server_error()
    }
    Ok(hash) -> {
      let assert Ok(is_valid) = argus.verify(hash, password)
      case is_valid {
        True -> create_session(ctx)
        False -> invalid_login(ctx)
      }
    }
  }

  wisp.bad_request("suck ma balls")
}

fn create_session(ctx: context.Context) -> Response {
}

fn invalid_login(ctx: context.Context) -> Response {
  wisp.ok()
  |> wisp.html_body(ctx.invalid_login_page())
}
