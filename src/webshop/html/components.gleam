import gleam/int
import gleam/option.{type Option, None, Some}
import lustre/attribute
import lustre/element
import lustre/element/html

import webshop/html/component_states.{type RegisterState}

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
  ])
}

fn password_input(
  placeholder placeholder: String,
  name name: String,
  value value: String,
) -> element.Element(a) {
  html.input([
    attribute.type_("password"),
    attribute.placeholder(placeholder),
    attribute.value(value),
    attribute.name(name),
  ])
}

fn user_info(
  username username: String,
  password password: String,
  error error: Option(String),
) -> element.Element(a) {
  html.div([], [
    text_input("Nutzername", "username", username),
    password_input(placeholder: "Passwort", name: "password", value: password),
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
    text_input("Bankidentifikationsnummer", "bin", bin),
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
      attribute.method("/post"),
      attribute.action("/register"),
    ],
    [
      user_info(username: state.username, password: state.password, error: None),
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
