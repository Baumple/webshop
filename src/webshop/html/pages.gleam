import lustre/attribute
import lustre/element
import lustre/element/html
import webshop/html/component_states/register_state
import webshop/html/components/register_form
import webshop/html/layout

pub fn index() -> String {
  []
  |> layout.layout("Webshop", "buy some items")
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
    html.form([attribute.action("/login"), attribute.method("post")], [
      input_field(placeholder: "Nutzername", name: "username", type_: "text"),
      input_field(placeholder: "Passwort", name: "password", type_: "password"),
      html.button([attribute.type_("submit")], [html.text("Einloggen")]),
    ]),
    html.hr([]),
    register_form.register_form(register_state.new()),
  ]
  |> layout.layout("Webshop - Login", "Please log in")
}

pub fn invalid_login() -> String {
  [html.p([], [html.text("Nutzername oder Passwort falsch.")])]
  |> layout.layout("Webshop - Invalid login", "")
}

pub fn register() -> String {
  [
    register_form.register_form(register_state.new()),
  ]
  |> layout.layout("Webshop - Register", "Please register.")
}
