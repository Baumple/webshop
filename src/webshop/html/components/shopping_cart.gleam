import gleam/int
import gleam/list
import lustre/attribute.{attribute, class}
import lustre/element
import lustre/element/html.{text}

import webshop/data/types.{type Cart}

pub fn view(username username: String, cart cart: Cart) -> element.Element(a) {
  html.div([class("cart-view")], [
    html.div([class("cart-entries")], list.map(cart.items, item_view)),
    html.button(
      [
        attribute("hx-post", "/buy"),
        class("buy-button"),
        attribute.disabled(cart.items == []),
      ],
      [
        text(case cart.items == [] {
          False -> "Jetzt Kaufen"
          True -> "Warenkorb leer"
        }),
      ],
    ),
  ])
}

pub fn item_view(entry: #(types.PartialItem, Int)) -> element.Element(a) {
  let #(partial_item, count) = entry
  let types.PartialItem(id:, name:, sprite:, category:, cost:) = partial_item

  html.div([class("cart-entry")], [
    case count == 1 {
      True ->
        html.button(
          [
            class("cart-entry-button"),
            attribute("hx-target", "this"),
            attribute(
              "hx-post",
              "/cart/delete/" <> int.to_string(partial_item.id),
            ),
          ],
          [text("X")],
        )
      False ->
        html.button(
          [
            class("cart-entry-button"),
            attribute("hx-target", "this"),
            attribute(
              "hx-post",
              "/cart/remove/" <> int.to_string(partial_item.id),
            ),
          ],
          [text("<")],
        )
    },
    html.div([class("cart-entry-info")], [
      html.p([], [text(name)]),
      html.p([], [text("Anzahl: " <> int.to_string(count) <> "x")]),
    ]),
    html.button(
      [
        class("cart-entry-button"),
        attribute("hx-target", "this"),
        attribute("hx-post", "/cart/cadd/" <> int.to_string(partial_item.id)),
      ],
      [text(">")],
    ),
  ])
}
