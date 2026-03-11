import lustre/attribute.{class}
import lustre/element
import lustre/element/html.{text}

import pokeshop/data/types.{type Cart}
import pokeshop/html/components
import pokeshop/html/components/svgs

import pokeshop/html/component_states/header_state.{type HeaderState}

pub fn view(
  title: String,
  subtitle: String,
  state: HeaderState,
) -> element.Element(a) {
  case state {
    header_state.LoggedIn(username:, cart:) ->
      logged_in_header(title, subtitle, username, cart)
    header_state.LoggedOut -> default_header(title, subtitle)
  }
}

pub fn default_header(title: String, subtitle: String) {
  html.header([], [
    html.h1([], [html.a([attribute.href("/")], [text(title)])]),
    html.p([], [text(subtitle)]),
    login_button(),
  ])
}

pub fn logged_in_header(
  title: String,
  subtitle: String,
  _username: String,
  cart: Cart,
) {
  html.header([], [
    html.h1([], [html.a([attribute.href("/")], [text(title)])]),
    html.p([], [text(subtitle)]),
    components.shopping_cart(cart),
  ])
}

pub fn login_button() -> element.Element(a) {
  html.a([class("header-comp"), class("login-icon"), attribute.href("/login")], [
    svgs.login(),
  ])
}
