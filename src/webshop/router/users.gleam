import argus
import gleam/http
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import webshop/data/db
import webshop/sessions
import wisp.{type Request, type Response}

import webshop/context.{type Context}
import webshop/data/types.{Customer}
import webshop/error
import webshop/html/component_states/register_state
import webshop/html/pages
import webshop/router/middleware
import webshop/router/users/validate

fn parse_bin(s: String) -> Result(Int, Nil) {
  let l = string.length(s)
  int.parse(s)
  |> result.try(fn(x) {
    case l == 6 || l == 8 {
      True -> Ok(x)
      False -> Error(Nil)
    }
  })
}

type RegisterInfo {
  RegisterInfo(
    username: String,
    name: String,
    surname: String,
    street: String,
    house_number: Int,
    postal_code: Int,
    location: String,
    bin: Int,
    institution: String,
    password: String,
  )
}

fn require_register_data(
  request: Request,
  continue: fn(RegisterInfo) -> Response,
) -> Response {
  use formdata <- wisp.require_form(request)
  let result = {
    let get = fn(key, continue: fn(String) -> Result(RegisterInfo, String)) {
      case list.key_find(formdata.values, key) {
        Ok(data) -> continue(data)
        Error(_) -> Error("'" <> key <> "' missing")
      }
    }
    let check_validity = fn(s: String, check) -> Result(String, Nil) {
      case check(s) {
        True -> Ok(s)
        False -> Error(Nil)
      }
    }
    use username <- get("username")

    use name <- get("name")
    use surname <- get("surname")

    use street <- get("street")

    use house_number <- get("house_number")
    use house_number <- result.try(
      int.parse(house_number) |> result.replace_error("'house_numer' invalid"),
    )

    use postal_code <- get("postal_code")
    use postal_code <- result.try(
      int.parse(postal_code) |> result.replace_error("'postal_code' invalid"),
    )

    use location <- get("location")

    use bin <- get("bin")
    use bin <- result.try(
      parse_bin(bin) |> result.replace_error("'bin' invalid"),
    )

    use institution <- get("institution")

    use password <- get("password")
    use password <- result.try(
      check_validity(password, register_state.is_valid_password)
      |> result.replace_error("password invalid"),
    )

    Ok(RegisterInfo(
      name:,
      username:,
      surname:,
      street:,
      house_number:,
      postal_code:,
      location:,
      bin:,
      institution:,
      password:,
    ))
  }

  case result {
    Ok(state) -> continue(state)
    Error(s) -> {
      wisp.log_notice("Received invalid form data: " <> s)
      wisp.bad_request("Invalid register form data: " <> s)
    }
  }
}

fn handle_get(request: Request, continue: fn() -> Response) {
  case request.method {
    http.Get -> pages.register() |> wisp.html_response(200)
    _ -> continue()
  }
}

pub fn handle(ctx: Context, request: Request) -> Response {
  case wisp.path_segments(request) {
    ["users"] -> handle_register(ctx, request)
    ["users", "logout"] -> handle_logout(ctx, request)
    ["users", "check", comp] -> validate.handle_validations(ctx, request, comp)
    _ -> wisp.not_found()
  }
}

fn handle_logout(ctx: Context, request: Request) -> Response {
  use session_id <- middleware.require_session_id(ctx, request)
  case sessions.remove(ctx.sessions, session_id) {
    Ok(_) -> pages.login() |> wisp.html_response(200)
    Error(err) -> error.log_ets_error(err)
  }
}

fn handle_register(ctx: Context, request: Request) -> Response {
  use <- handle_get(request)
  use register_info <- require_register_data(request)
  perform_register(ctx, register_info)
}

fn hash_password(password, continue) -> Response {
  let hash =
    argus.hasher()
    |> argus.hash(password, argus.gen_salt())
  case hash {
    Ok(hash) -> continue(hash)
    Error(err) -> {
      wisp.log_critical("Could not hash password: " <> string.inspect(err))
      wisp.internal_server_error()
    }
  }
}

fn perform_register(ctx: Context, state: RegisterInfo) -> Response {
  use hash <- hash_password(state.password)
  let res =
    db.insert_customer(
      ctx.db,
      Customer(
        username: state.username,
        name: state.name,
        surname: state.surname,
        street: state.street,
        house_number: state.house_number,
        postal_code: state.postal_code,
        location: state.location,
        bin: state.bin,
        institution: state.institution,
        password_hash: hash.encoded_hash,
      ),
    )

  case res {
    Ok(_) ->
      pages.login()
      |> wisp.html_response(200)
    Error(err) -> error.log_sql_error(err)
  }
}
