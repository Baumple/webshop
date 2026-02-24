import gleam/http
import gleam/http/request
import gleam/int
import gleam/list
import gleam/option
import gleam/result
import lustre/element
import webshop/html/components
import wisp.{type Request, type Response}

import webshop/context.{type Context}
import webshop/html/component_states/register_state.{
  type RegisterState, RegisterState,
}
import webshop/html/pages

fn parse_bin(s: String) -> option.Option(Int) {
  todo
}

fn assert_register_data(
  request: Request,
  continue: fn(RegisterState) -> Response,
) -> Response {
  use formdata <- wisp.require_form(request)
  let result = {
    let get = fn(key, continue: fn(String) -> Result(RegisterState, Nil)) {
      case list.key_find(formdata.values, key) {
        Ok(data) -> continue(data)
        Error(_) -> Error(Nil)
      }
    }
    use username <- get("username")
    use name <- get("name")
    use surname <- get("surname")
    use street <- get("street")

    use house_number <- get("house_number")
    let house_number =
      int.parse(house_number)
      |> option.from_result

    use postal_code <- get("postal_code")
    let postal_code =
      int.parse(postal_code)
      |> option.from_result

    use location <- get("location")

    use bin <- get("bin")
    let bin = parse_bin(bin)

    use institution <- get("inst")
    use password <- get("password")

    Ok(RegisterState(
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
    Error(Nil) -> {
      wisp.log_notice("Received invalid form data.")
      wisp.bad_request("Invalid register form data.")
    }
  }
}

fn handle_get(request: Request, continue: fn() -> Response) {
  case request.method {
    http.Get -> pages.register() |> wisp.html_response(200)
    _ -> continue()
  }
}

fn validate_password(request: Request) -> Response {
  use formdata <- wisp.require_form(request)
  let result = {
    use password <- result.try(list.key_find(formdata.values, "password"))
    Ok(password)
  }
  case result {
    Ok(pwd) ->
      case register_state.is_valid_password(pwd) {
        True ->
          components.password_input(
            value: pwd,
            endpoint: "/register/password",
            error: option.None,
          )
        False ->
          components.password_input(
            value: pwd,
            endpoint: "/register/password",
            error: option.Some("Passwort ist ungültig."),
          )
      }
      |> element.to_document_string
      |> wisp.html_response(200)
    Error(_) -> wisp.bad_request("Invalid form data.")
  }
}

fn handle_validations(_: Context, request: Request, comp: String) -> Response {
  case comp {
    "password" -> validate_password(request)
    _ -> wisp.not_found()
  }
}

pub fn handle(ctx: Context, request: Request) -> Response {
  case wisp.path_segments(request) {
    ["register"] -> handle_register(ctx, request)
    ["register", comp] -> handle_validations(ctx, request, comp)
    _ -> wisp.not_found()
  }
}

fn handle_register(ctx: Context, request: Request) -> Response {
  use <- handle_get(request)
  use register_info <- assert_register_data(request)
  todo
}

fn perform_register(ctx: Context, state: RegisterState) -> Response {
  todo
}
