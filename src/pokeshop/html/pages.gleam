import lustre/attribute
import lustre/element
import lustre/element/html.{text}
import pokeshop/data/types.{type Cart}
import pokeshop/html/component_states/header_state.{type HeaderState}
import pokeshop/html/components/shopping_cart

import pokeshop/html/component_states/item_list_state.{type ItemListState}
import pokeshop/html/component_states/register_state
import pokeshop/html/components
import pokeshop/html/components/form
import pokeshop/html/components/item_display
import pokeshop/html/components/item_list_comp as item_list
import pokeshop/html/layout

pub fn index(
  item_list_state: ItemListState,
  header_state: HeaderState,
) -> String {
  [item_list.views(item_list_state)]
  |> layout.layout("Webshop", "buy some items", header_state)
}

pub fn index_with_username(
  username: String,
  item_list_state: ItemListState,
  header_state: HeaderState,
) -> String {
  [item_list.views(item_list_state)]
  |> layout.layout(
    "Webshop",
    "hello, " <> username <> "! let's buy some items",
    header_state,
  )
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
  |> layout.layout("Webshop - Login", "please log in", header_state.LoggedOut)
}

pub fn item(item: types.Item, header_state: HeaderState) -> String {
  [item_display.view(item)]
  |> layout.layout("Webshop - Item", item.name, header_state)
}

pub fn shopping_cart(
  username username: String,
  cart cart: Cart,
  invoices invoices: List(types.Invoice),
) -> String {
  [shopping_cart.view(username, cart, invoices)]
  |> layout.layout(
    "Webshop - Shopping cart",
    "dein bisheriger einkauf",
    header_state.LoggedIn(username:, cart:),
  )
}

pub fn invalid_login() -> String {
  [html.p([], [html.text("Nutzername oder Passwort falsch.")])]
  |> layout.layout("Webshop - Invalid login", "", header_state.LoggedOut)
}

pub fn register() -> String {
  [
    form.register_form(register_state.new()),
  ]
  |> layout.layout(
    "Webshop - Register",
    "Please register.",
    header_state.LoggedOut,
  )
}
