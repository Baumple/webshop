import gleam/int
import lustre/attribute.{class}
import lustre/element
import lustre/element/html.{text}
import webshop/data/types.{type Cart}
import webshop/html/components/svgs

pub fn separator() -> element.Element(a) {
  html.hr([class("separator")])
}

pub fn vert_separator() -> element.Element(a) {
  html.hr([class("vert-separator")])
}

pub fn dashed_separator() -> element.Element(a) {
  html.hr([class("dashed-separator")])
}

pub fn section_header(t: String) -> element.Element(a) {
  html.h2([], [text(t)])
}

pub fn shopping_cart(cart cart: Cart) -> element.Element(a) {
  html.a(
    [
      class("header-comp"),
      class("shopping-icon"),
      attribute.href("/cart/view/"),
      attribute.id("shopping-cart"),
    ],
    [
      svgs.cart(),
      html.p([], [text(types.get_cart_item_count(cart) |> int.to_string)]),
    ],
  )
}

pub fn payment_success() -> element.Element(a) {
  [
    html.h2([], [text("Einkauf Erfolgreich!")]),
    html.p([], [text("Deine Rechnung findest du hier")]),
  ]
  |> html.div([], _)
}
