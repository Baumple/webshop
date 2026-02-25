import gleam/list
import lustre/element
import wisp.{type FormData, type Request, type Response}

import webshop/context.{type Context}
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
    "bin" ->
      validate_field(
        formdata,
        "bin",
        comps.bank_information,
        register_state.is_valid_bin_string,
        "Bankidentifikationsnummer ungültig",
      )
    "house_number" ->
      validate_field(
        formdata,
        "house_number",
        comps.house_number_input,
        register_state.is_valid_house_number_string,
        "Hausnummer ungültig",
      )
    "postal_code" ->
      validate_field(
        formdata,
        "postal_code",
        comps.postal_code_input,
        register_state.is_valid_house_number_string,
        "Postleitzahl ungültig",
      )
    _ -> wisp.not_found()
  }
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

fn assert_field_exists(
  fd: FormData,
  field_name: String,
  continue: fn(String) -> Response,
) -> Response {
  let field = list.key_find(fd.values, field_name)
  case field {
    Ok(field) -> continue(field)
    Error(Nil) -> wisp.bad_request("Invalid form data.")
  }
}

fn validate_username(ctx: Context, formdata: FormData) -> Response {
  use username <- assert_field_exists(formdata, "username")
  case register_state.is_valid_username(username) {
    True -> {
      use <- prevent_duplicate_usernames(ctx, username)
      comps.username_input(
        username,
        comps.Invalid("Nutzername nicht verfügbar"),
      )
      |> element.to_document_string
      |> wisp.html_response(200)
    }
    False ->
      comps.username_input(
        username,
        comps.Invalid("Nutzername nicht verfügbar"),
      )
      |> element.to_document_string
      |> wisp.html_response(200)
  }
}

fn prevent_duplicate_usernames(
  ctx: Context,
  username: String,
  continue: fn() -> Response,
) -> Response {
  comps.username_input(username, comps.Valid)
  |> element.to_document_string
  |> wisp.html_response(200)
}
