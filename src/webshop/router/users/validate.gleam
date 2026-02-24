import gleam/bool
import gleam/int
import gleam/list
import gleam/option
import gleam/result
import lustre/element
import wisp.{type FormData, type Request, type Response}

import webshop/context.{type Context}
import webshop/data/db
import webshop/html/component_states/register_state
import webshop/html/components.{type ComponentState} as comps

pub fn handle_validations(
  ctx: Context,
  request: Request,
  comp: String,
) -> Response {
  use formdata <- wisp.require_form(request)
  case comp {
    "username" -> validate_username(ctx, formdata)
    "password" ->
      validate_field(
        formdata,
        "password",
        comps.password_input,
        register_state.is_valid_password,
        "Passwort ist ungültig",
      )
    "bin" -> validate_bin(formdata)
    "house_number" -> validate_house_number(formdata)
    "postal_code" -> validate_postal_code(formdata)
    _ -> wisp.not_found()
  }
}

fn is_valid_username(ctx: Context, username: String) -> Bool {
  db.username_exists(ctx.db, username)
}

fn validate_field(
  formdata: FormData,
  field: String,
  comp: fn(String, ComponentState) -> element.Element(a),
  is_valid: fn(String) -> Bool,
  invalid_message: String,
) -> Response {
  let field = list.key_find(formdata.values, field)
  case field {
    Ok(field) -> {
      let is_valid = is_valid(field)
      case is_valid {
        True -> comp(field, comps.Valid)
        False -> comp(field, comps.Invalid(invalid_message))
      }
      |> element.to_document_string
      |> wisp.html_response(200)
    }
    Error(_) -> wisp.bad_request("Invalid form data")
  }
}

fn validate_postal_code(formdata: FormData) -> Response {
  todo
}

fn validate_house_number(formdata: FormData) -> Response {
  let house_number = list.key_find(formdata.values, "house_number")
  case house_number {
    Ok(house_number) -> {
      let pc = int.parse(house_number) |> option.from_result
      let is_valid = register_state.is_valid_house_number(pc)
      case is_valid {
        True -> comps.house_number_input(house_number, comps.Valid)
        False ->
          comps.house_number_input(
            house_number,
            comps.Invalid("Hausnummer ist ungültig."),
          )
      }
      |> element.to_document_string
      |> wisp.html_response(200)
    }
    Error(_) -> wisp.bad_request("Invalid form data")
  }
}

fn validate_bin(formdata: FormData) -> Response {
  todo
}

// TODO: Looks ugly
fn validate_username(ctx: Context, formdata: FormData) -> Response {
  let username = list.key_find(formdata.values, "username")
  case username {
    Ok(username) -> {
      use <- bool.lazy_guard(
        when: !register_state.is_valid_username(username),
        return: fn() {
          comps.username_input(
            username,
            comps.Invalid("Nutzername nicht verfügbar"),
          )
          |> element.to_document_string
          |> wisp.html_response(200)
        },
      )
      case db.username_exists(ctx.db, username) {
        Ok(exists) if exists ->
          comps.username_input(
            username,
            comps.Invalid("Nutzername nicht verfügbar"),
          )
          |> element.to_document_string
          |> wisp.html_response(200)
        Ok(_) ->
          comps.username_input(username, comps.Valid)
          |> element.to_document_string
          |> wisp.html_response(200)
        Error(err) -> {
          wisp.log_critical(err.message)
          wisp.internal_server_error()
        }
      }
    }
    Error(Nil) -> wisp.bad_request("Invalid form data.")
  }
}

fn validate_password(formdata: FormData) -> Response {
  let result = {
    use password <- result.try(list.key_find(formdata.values, "password"))
    Ok(password)
  }
  case result {
    Ok(pwd) ->
      case register_state.is_valid_password(pwd) {
        True -> comps.password_input(value: pwd, state: comps.Valid)
        False ->
          comps.password_input(
            value: pwd,
            state: comps.Invalid("Passwort ist ungültig."),
          )
      }
      |> element.to_document_string
      |> wisp.html_response(200)
    Error(_) -> wisp.bad_request("Invalid form data.")
  }
}
