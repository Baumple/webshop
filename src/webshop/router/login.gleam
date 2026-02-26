import argus
import gleam/float
import gleam/list
import gleam/result
import gleam/time/duration
import webshop/sessions
import wisp.{type Request, type Response}

import webshop/context.{type Context}
import webshop/data/db
import webshop/html/pages

pub fn handle(ctx: Context, request: Request) -> Response {
  use formdata <- wisp.require_form(request)
  let result = {
    use username <- result.try(list.key_find(formdata.values, "username"))
    use password <- result.try(list.key_find(formdata.values, "password"))
    Ok(#(username, password))
  }

  case result {
    Ok(#(username, password)) -> perform_login(request, ctx, username, password)
    Error(Nil) -> wisp.bad_request("Login form data is invalid.")
  }
}

const dummy_argon_hash = "$argon2id$v=13$m=19456,t=2,p=1$cndYSTVpME9LVjdiZlJ5cFpLRm1nQkMvQitoNFYxYkxyMWtPYjZJd01PT1FoZ1dRK2ZoTWxjQzU0QlBzUnVLVC9HaEcxZ1BPcFl6bTlKbkd1MjY0cVJsMHBVQld6Q2pGUk94Slg4anNDQ0x5T3JlMW5JaDk5dGgvNXVoT2hHNkQ3MFhyQUNQeERDdGNiOXM4amF2M0I3QUdvSE9EV1RvSmdWTlRhNmlXSW5qaUVlUU5QQmYwU3hxRDZsZUZiK2tOa1BVcDB0WlNFT1VpRzF2N2lWemFsUGcyK2lQazh4cHl4ZFBXYi9hdUZsRXZLdE9YZmczRG96SDNaRVF6cjVMeEhQM3BmODJ6QkF1aTJyQnIySXRDTUs0QVlzTGdNdDNqRU83RFVja3F5WkNSUmhCMWtlcUtFNTAyRkR5MWd3b1djaFN6eTJqWG5FdXhBeDl5QjdzNlRaOU9tUjdqTk9WTXU0cXBOR2Zy$1IC6ZMPhWcMEcil6tLF63SkgO9lvexj+ExiTFM1InJQ"

fn dummy_hash(password: String, continue: fn() -> Response) -> Response {
  case argus.verify(dummy_argon_hash, password) {
    Ok(_) -> continue()
    Error(_) -> {
      wisp.log_critical("Dummy password hashing failed.")
      wisp.internal_server_error()
    }
  }
}

fn perform_login(
  request: Request,
  ctx: Context,
  username: String,
  password: String,
) -> Response {
  case db.get_username_password_hash(ctx.db, username) {
    db.NotFound -> {
      use <- dummy_hash(password)
      invalid_login(ctx)
    }
    db.Found(hash) -> {
      let assert Ok(is_valid) = argus.verify(hash, password)
      case is_valid {
        True -> create_session(request, ctx, username)
        False -> invalid_login(ctx)
      }
    }
    db.SqlightError(err) -> {
      wisp.log_critical("Database error: " <> err.message)
      wisp.internal_server_error()
    }
  }
}

fn create_session(request: Request, ctx: Context, username: String) -> Response {
  let id = sessions.create_session(ctx.sessions, username:)

  wisp.html_response(pages.index(), 200)
  |> wisp.set_cookie(
    request: request,
    name: "SESSIONID",
    value: id,
    security: wisp.PlainText,
    max_age: duration.hours(24) |> duration.to_seconds() |> float.round(),
  )
}

fn invalid_login(_ctx: Context) -> Response {
  wisp.ok()
  |> wisp.html_body(pages.invalid_login())
}
