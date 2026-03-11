import gleam/int
import gleam/list
import gleam/option.{None, Some}
import lustre/attribute.{attribute}
import lustre/element
import lustre/element/html.{text}

import pokeshop/html/component_states/register_state.{type RegisterState}

pub type ComponentState {
  /// Component contains valid data
  Valid
  /// Component contains invalid data
  /// Includes a message
  Invalid(String)
  /// Initial, unverified component state
  Pristine
}

pub fn input_field(
  placeholder placeholder: String,
  name name: String,
  type_ type_: String,
) -> element.Element(a) {
  html.div([attribute.class("terminal-input")], [
    html.input([
      attribute.placeholder(placeholder),
      attribute.name(name),
      attribute.type_(type_),
    ]),
  ])
}

/// - `name` name of the form data entry
/// - `value` value of input
/// - `state` component state
/// - `placeholder` the endpoint to validate component data state
fn checked_text_input(
  placeholder placeholder: String,
  name name: String,
  value value: String,
  state state: ComponentState,
  endpoint validate_endpoint: String,
) -> element.Element(a) {
  let elements = [
    html.div([attribute.class("terminal-input")], [
      html.input([
        attribute("hx-swap", "outerHTML"),
        attribute("hx-target", "closest .input-wrapper"),
        attribute("hx-post", validate_endpoint),
        attribute("hx-on:change", ""),
        attribute.type_("text"),
        attribute.placeholder(placeholder),
        attribute.name(name),
        attribute.value(value),
        attribute.required(True),
      ]),
    ]),
  ]
  let elements = case state {
    Valid | Pristine -> elements
    Invalid(msg) -> list.append(elements, [html.p([], [text(msg)])])
  }
  html.div([attribute.class("input-wrapper")], elements)
}

fn text_input(
  placeholder: String,
  name: String,
  value: String,
) -> element.Element(a) {
  html.div([attribute.class("terminal-input")], [
    html.input([
      attribute.type_("text"),
      attribute.placeholder(placeholder),
      attribute.name(name),
      attribute.value(value),
      attribute.required(True),
    ]),
  ])
}

pub fn password_input(
  value value: String,
  state state: ComponentState,
) -> element.Element(a) {
  let elements = [
    html.div([attribute.class("terminal-input")], [
      html.input([
        attribute("hx-swap", "outerHTML"),
        attribute("hx-target", "closest .input-wrapper"),
        attribute("hx-post", "/users/check/password"),
        attribute("hx-on:change", ""),
        attribute.type_("password"),
        attribute.placeholder("Passwort"),
        attribute.value(value),
        attribute.name("password"),
        attribute.required(True),
      ]),
    ]),
  ]

  let elements = case state {
    Invalid(msg) -> list.append(elements, [html.p([], [text(msg)])])
    _ -> elements
  }

  html.div(
    [
      attribute.id("password"),
      attribute.class("input-wrapper"),
    ],
    elements,
  )
}

pub fn username_input(
  username username: String,
  state state: ComponentState,
) -> element.Element(a) {
  checked_text_input(
    placeholder: "Nutzername",
    name: "username",
    value: username,
    state:,
    endpoint: "/users/check/username",
  )
}

fn user_info(
  username username: String,
  password password: String,
) -> element.Element(a) {
  html.div([], [
    html.h3([], [text("Anmeldedaten")]),
    username_input(username, Pristine),
    password_input(value: password, state: Pristine),
  ])
}

fn user_name(name name: String, surname surname: String) -> element.Element(a) {
  html.div([], [
    html.h3([], [text("Name")]),
    text_input("Vorname", "name", name),
    text_input("Nachname", "surname", surname),
  ])
}

pub fn postal_code_input(
  postal_code: String,
  state: ComponentState,
) -> element.Element(a) {
  checked_text_input(
    placeholder: "Postleitzahl",
    name: "postal_code",
    value: postal_code,
    state:,
    endpoint: "/users/check/postal_code",
  )
}

pub fn house_number_input(
  value: String,
  state: ComponentState,
) -> element.Element(a) {
  checked_text_input(
    placeholder: "Hausnummer",
    name: "house_number",
    value:,
    state:,
    endpoint: "/users/check/house_number",
  )
}

fn user_address(
  street street: String,
  house_number house_number: String,
  postal_code postal_code: String,
  location location: String,
) -> element.Element(a) {
  html.div([], [
    html.h3([], [text("Adresse")]),
    text_input("Straße", "street", street),
    house_number_input(house_number, Pristine),
    postal_code_input(postal_code, Pristine),
    text_input("Ort", "location", location),
  ])
}

pub fn bin_input(bin bin: String, state state: ComponentState) {
  checked_text_input(
    "Bankidentifikationsnummer",
    "bin",
    bin,
    state,
    "/users/check/bin",
  )
}

pub fn bank_information(
  bin bin: String,
  state state: ComponentState,
) -> element.Element(a) {
  html.div([], [
    html.h3([], [text("Bankinformationen")]),
    bin_input(bin:, state:),
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
      attribute.action("/users"),
    ],
    [
      html.h2([], [text("Regristrierung")]),
      user_info(username: state.username, password: state.password),

      html.br([]),

      user_name(name: state.name, surname: state.surname),

      html.br([]),

      user_address(
        street: state.street,
        house_number: house_number,
        postal_code: postal_code,
        location: state.location,
      ),

      html.br([]),

      bank_information(bin, Pristine),

      html.br([]),

      user_affiliation(state.institution),

      html.br([]),

      html.button([attribute.type_("submit")], [text("> Regristieren <")]),
    ],
  )
}
