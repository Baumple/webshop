import gleam/dict
import gleam/int
import gleam/list
import gleam/result
import lustre/attribute.{attribute, class}
import lustre/element
import lustre/element/html.{text}

import pokeshop/data/types.{type Item}
import pokeshop/html/components/svgs

pub fn view(item: Item) -> element.Element(a) {
  let types.Item(
    id:,
    name: _,
    cost:,
    category:,
    attributes:,
    names:,
    effect_entries:,
    sprite: _,
  ) = item

  let effect_entry =
    effect_entries
    |> dict.get("en")
    |> result.unwrap(types.EffectEntry(
      effect: "Beschreibung fehlt",
      short_effect: "Beschreibung fehlt",
    ))

  let name =
    names
    |> dict.get("en")
    |> result.unwrap("kein Name")

  html.div([], [
    html.div([class("item-display")], [
      html.img([
        class("item-display-sprite"),
        attribute.src(types.get_sprite_or_default_sprite(item)),
      ]),

      html.div([class("item-display-info")], [
        info_row("Item", text(name)),
        info_row("Kategorie", category_view(category)),
        info_row("Preis", cost_text(cost)),
        info_row(
          "Kurzbeschreibung",
          html.p([], [text(effect_entry.short_effect)]),
        ),
        info_row("Attribute", attribute_list(attributes)),
      ]),
      html.div([class("item-display-desc")], [effect_entry_view(effect_entry)]),
    ]),
    add_to_cart_button(id),
  ])
}

fn cost_text(cost: Int) -> element.Element(a) {
  let cost = case cost {
    0 -> "unverkäuflich/auffindbar"
    x -> int.to_string(x) <> "₽"
  }
  text(cost)
}

fn info_row(name: String, info: element.Element(a)) -> element.Element(a) {
  html.div([class("info-row")], [
    html.p([class("info-header")], [text(name <> ":")]),
    html.div([class("info-info")], [info]),
  ])
}

fn add_to_cart_button(id: Int) -> element.Element(a) {
  html.div([class("cart-button")], [
    html.a(
      [
        attribute("hx-post", "/cart/add/" <> int.to_string(id)),
        attribute("hx-target", ".header-comp"),
        class("cart-button-image"),
      ],
      [svgs.shopping_cart()],
    ),
  ])
}

fn attribute_list(attrs: List(String)) -> element.Element(a) {
  case attrs {
    [_, ..] -> html.div([class("attributes")], list.map(attrs, attribute_view))
    [] ->
      html.div([class("attributes")], [html.p([], [text("keine Attribute")])])
  }
}

fn category_view(category: String) -> element.Element(a) {
  html.div([class("category-view")], [
    html.a([attribute.href("/?category=" <> category), class("link-view")], [
      text(category),
    ]),
  ])
}

fn attribute_view(attr: String) -> element.Element(a) {
  html.a([attribute.href("/?attribute=" <> attr), class("link-view")], [
    text(attr),
  ])
}

fn effect_entry_view(effect_entry: types.EffectEntry) -> element.Element(a) {
  html.div([], [
    html.p([class("info-header")], [text("Beschreibung")]),
    html.p([], [text(effect_entry.effect)]),
  ])
}
