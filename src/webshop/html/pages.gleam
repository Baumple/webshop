import lustre/attribute
import lustre/element
import lustre/element/html.{text}
import webshop/data/types

import webshop/html/component_states/register_state
import webshop/html/components
import webshop/html/components/form
import webshop/html/components/items
import webshop/html/layout

pub fn index(items: List(types.PartialItem)) -> String {
  [items.views(items)]
  |> layout.layout("Webshop", "buy some items")
}

pub fn index_with_username(
  username: String,
  items: List(types.PartialItem),
) -> String {
  [items.views(items)]
  |> layout.layout("Webshop", "hello, " <> username <> "! let's buy some items")
}

fn login_form() -> element.Element(a) {
  html.div([attribute.class("login")], [
    html.div([], [
      html.h2([], [text("Login")]),
      html.form([attribute.action("/login"), attribute.method("post")], [
        form.input_field(
          placeholder: "Nutzername",
          name: "username",
          type_: "text",
        ),
        form.password_input(value: "", state: form.Pristine),
        html.button([attribute.type_("submit")], [html.text("> Einloggen <")]),
      ]),
    ]),
    components.separator(),
    form.register_form(register_state.new()),
  ])
}

pub fn login() -> String {
  [login_form()]
  |> layout.layout("Webshop - Login", "please log in")
}

pub fn invalid_login() -> String {
  [html.p([], [html.text("Nutzername oder Passwort falsch.")])]
  |> layout.layout("Webshop - Invalid login", "")
}

pub fn register() -> String {
  [
    form.register_form(register_state.new()),
  ]
  |> layout.layout("Webshop - Register", "Please register.")
}
