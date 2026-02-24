import gleam/http
import gleam/int
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import wisp.{type Request, type Response}

import webshop/context.{type Context}
import webshop/html/component_states.{type RegisterState, RegisterState}
import webshop/html/pages

fn validate_register_state(state: RegisterState) -> Bool {
  let RegisterState(
    username:,
    name:,
    surname:,
    street:,
    house_number:,
    postal_code:,
    location:,
    bin:,
    institution:,
    password:,
  ) = state

  is_valid_username(username)
  && is_valid_house_number(house_number)
  && is_valid_password(password)
}

fn is_valid_password(password: String) -> Bool {
  todo
}

fn is_valid_house_number(house_number: option.Option(Int)) -> Bool {
  todo
}

fn is_valid_username(username: String) -> Bool {
  string.contains
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
    let bin =
      int.parse(bin)
      |> option.from_result

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

pub fn handle(ctx: Context, request: Request) -> Response {
  use <- handle_get(request)
  use register_info <- assert_register_data(request)

  todo
}

fn perform_register(ctx: Context, state: RegisterState) -> Response {
  todo
}
