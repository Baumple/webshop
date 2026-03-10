import lustre/attribute
import lustre/element
import lustre/element/html.{text}
import webshop/data/types

import webshop/html/component_states/item_list_state.{type ItemListState}
import webshop/html/component_states/register_state
import webshop/html/components
import webshop/html/components/form
import webshop/html/components/item_display
import webshop/html/components/item_list_comp as item_list
import webshop/html/layout

pub fn index(state: ItemListState) -> String {
  [item_list.views(state)]
  |> layout.layout("Webshop", "buy some items")
}

pub fn index_with_username(username: String, state: ItemListState) -> String {
  [item_list.views(state)]
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
    components.vert_separator(),
    form.register_form(register_state.new()),
  ])
}

pub fn login() -> String {
  [login_form()]
  |> layout.layout("Webshop - Login", "please log in")
}

pub fn item(item: types.Item) -> String {
  [item_display.view(item)]
  |> layout.layout("Webshop - Item", item.name)
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
