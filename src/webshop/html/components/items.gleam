import gleam/int
import gleam/list
import lustre/attribute.{attribute, class}
import lustre/element
import lustre/element/html.{text}
import webshop/html/components/svgs

import webshop/data/types.{type PartialItem}

pub fn views(items: List(PartialItem)) -> element.Element(a) {
  html.div([class("item-views")], list.map(items, item_view))
}

fn item_view(item: PartialItem) -> element.Element(a) {
  let types.PartialItem(id: _, name:, sprite:, category:, cost:) = item

  html.div([class("item-view")], [
    html.div([class("item-view-info")], [
      html.img([class("item-view-sprite"), attribute.src(sprite)]),
      html.div([], [
        html.h4([], [text(name)]),
        html.p([], [text("Kategorie: " <> category)]),
        html.p([], [text("Preis: " <> cost |> int.to_string() <> "₽")]),
      ]),
    ]),
    html.div([], [
      html.a([class("item-view-cart")], [svgs.shopping_cart()]),
    ]),
  ])
}
