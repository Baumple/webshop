import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import lustre/attribute.{attribute}
import lustre/element
import lustre/element/html.{text}

import webshop/html/component_states/register_state.{type RegisterState}

fn validated_text_input(
  placeholder placeholder: String,
  name name: String,
  value value: String,
  endpoint valdiate_endpoint: String,
) -> element.Element(a) {
  html.input([
    attribute("hx-post", valdiate_endpoint),
    attribute("hx-on:change", ""),
    attribute.type_("text"),
    attribute.placeholder(placeholder),
    attribute.name(name),
    attribute.value(value),
    attribute.required(True),
  ])
}

fn text_input(
  placeholder: String,
  name: String,
  value: String,
) -> element.Element(a) {
  html.input([
    attribute.type_("text"),
    attribute.placeholder(placeholder),
    attribute.name(name),
    attribute.value(value),
    attribute.required(True),
  ])
}

pub fn password_input(
  value value: String,
  endpoint validate_endpoint: String,
  error error: Option(String),
) -> element.Element(a) {
  let elements = [
    html.input([
      attribute("hx-swap", "outerHTML"),
      attribute("hx-target", "#password"),
      attribute("hx-post", validate_endpoint),
      attribute("hx-on:change", ""),
      attribute.type_("password"),
      attribute.placeholder("Passwort"),
      attribute.value(value),
      attribute.name("password"),
      attribute.required(True),
    ]),
  ]

  let elements = case error {
    Some(msg) -> list.append(elements, [html.p([], [text(msg)])])
    None -> elements
  }

  html.div([attribute.id("password")], elements)
}

fn user_info(
  username username: String,
  password password: String,
) -> element.Element(a) {
  html.div([], [
    validated_text_input(
      placeholder: "Nutzername",
      name: "username",
      value: username,
      endpoint: "/register/username",
    ),
    password_input(value: password, endpoint: "/register/password", error: None),
  ])
}

fn user_name(
  name name: String,
  surname surname: String,
  error error: Option(String),
) -> element.Element(a) {
  html.div([], [
    text_input("Vorname", "name", name),
    text_input("Nachname", "surname", surname),
  ])
}

fn user_address(
  street street: String,
  house_number house_number: String,
  postal_code postal_code: String,
  location location: String,
  error error: Option(String),
) -> element.Element(a) {
  html.div([], [
    text_input("Straße", "street", street),
    text_input("Hausnummer", "house_number", house_number),
    text_input("Postleitzahl", "postal_code", postal_code),
    text_input("Ort", "Location", location),
  ])
}

fn bank_information(
  bin bin: String,
  error error: Option(String),
) -> element.Element(a) {
  html.div([], [
    validated_text_input(
      "Bankidentifikationsnummer",
      "bin",
      bin,
      "/register/bin",
    ),
  ])
}

fn user_affiliation(institution institution: String) -> element.Element(a) {
  html.div([], [
    text_input("Institution", "institution", institution),
  ])
}

pub fn register_form(state: RegisterState) -> element.Element(a) {
  let house_number = case state.house_number {
    Some(hn) -> int.to_string(hn)
    None -> ""
  }
  let postal_code = case state.house_number {
    Some(pc) -> int.to_string(pc)
    None -> ""
  }
  let bin = case state.bin {
    Some(bin) -> int.to_string(bin)
    None -> ""
  }

  html.form(
    [
      attribute.method("POST"),
      attribute.action("/register"),
    ],
    [
      user_info(username: state.username, password: state.password),

      html.br([]),

      user_name(name: state.name, surname: state.surname, error: None),

      html.br([]),

      user_address(
        street: state.street,
        house_number: house_number,
        postal_code: postal_code,
        location: state.location,
        error: None,
      ),

      html.br([]),

      bank_information(bin, None),

      html.br([]),

      user_affiliation(state.institution),

      html.br([]),

      html.input([attribute.type_("submit")]),
    ],
  )
}
