import lustre/attribute.{attribute}
import lustre/element
import lustre/element/html.{text}
import webshop/html/component_states/register_state
import webshop/html/components
import webshop/html/layout

pub fn index() -> String {
  [
    html.h1([], [html.text("Hello")]),
    html.button(
      [attribute("hx-get", "/hx/other_button"), attribute.type_("button")],
      [],
    ),
  ]
  |> layout.layout("Webshop")
}

fn input_field(
  placeholder placeholder: String,
  name name: String,
  type_ type_: String,
) -> element.Element(a) {
  html.input([
    attribute.placeholder(placeholder),
    attribute.name(name),
    attribute.type_(type_),
  ])
}

pub fn login() -> String {
  [
    html.h1([], [html.text("Hello - Please log in")]),
    html.form([attribute.action("/login"), attribute.method("post")], [
      input_field(placeholder: "Nutzername", name: "username", type_: "text"),
      input_field(placeholder: "Passwort", name: "password", type_: "password"),
      html.button([attribute.type_("submit")], [html.text("Einloggen")]),
    ]),
    html.button(
      [attribute("hx-get", "/hx/other_button"), attribute.type_("button")],
      [text("Load button")],
    ),
    html.hr([]),
    components.register_form(register_state.new()),
  ]
  |> layout.layout("Webshop - Login")
}

pub fn invalid_login() -> String {
  [html.p([], [html.text("Nutzername oder Passwort falsch.")])]
  |> layout.layout("Webshop - Invalid login")
}

pub fn register() -> String {
  [
    components.register_form(register_state.new()),
  ]
  |> layout.layout("Register - Webshop")
}
