import argus
import gleam/list
import gleam/result
import webshop/data/db
import wisp.{type Request, type Response}

import webshop/context.{type Context}
import webshop/html/pages

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
    db.NotFound -> invalid_login(ctx)
    db.Found(hash) -> {
      let assert Ok(is_valid) = argus.verify(hash, password)
      case is_valid {
        True -> create_session(ctx)
        False -> invalid_login(ctx)
      }
    }
    db.SqlightError(err) -> {
      wisp.log_critical("Database error: " <> err.message)
      wisp.internal_server_error()
    }
  }

  wisp.bad_request("suck ma balls")
}

fn create_session(ctx: context.Context) -> Response {
  todo
}

fn invalid_login(_ctx: context.Context) -> Response {
  wisp.html_response(pages.invalid_login(), 200)
}
