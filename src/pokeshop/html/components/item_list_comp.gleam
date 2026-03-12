import gleam/int
import gleam/list
import gleam/option
import lustre/attribute.{attribute, class}
import lustre/element
import lustre/element/html.{text}

import pokeshop/data/db/query
import pokeshop/data/types.{type PartialCategory, type PartialItem}
import pokeshop/html/component_states/item_list_state.{type ItemListState}
import pokeshop/html/components/svgs

fn searchbar(
  index: Int,
  item_count: Int,
  query: query.Query,
  categories: List(PartialCategory),
) -> element.Element(a) {
  let index = int.clamp(index, 0, item_count / 20)
  let left_index = int.max(index - 1, 0)
  let right_index = int.clamp(index + 1, 0, item_count / 20)

  let base_query = query.to_string(query)
  let search_term = case query.text {
    option.Some(text) -> text
    option.None -> ""
  }

  html.div([class("searchbar")], [
    html.a(
      [
        class("page-arrow"),
        attribute.href(base_query <> "&index=" <> int.to_string(left_index)),
      ],
      [
        svgs.arrow_left(),
      ],
    ),

    html.form(
      [
        class("search-form"),
        attribute.action("/"),
      ],
      [
        html.div(
          [
            class("terminal-input"),
          ],
          [
            html.input([
              class("search-input"),
              attribute.type_("text"),
              attribute.name("searchterm"),
              attribute.placeholder("Suchen"),
              attribute.value(search_term),
            ]),
          ],
        ),
        category_select_view(categories, query.category),
        html.button([class("search-submit"), attribute.type_("submit")], [
          text("Suchen"),
        ]),
      ],
    ),

    page_view(index, item_count),

    html.a(
      [
        class("page-arrow"),
        attribute.href(base_query <> "&index=" <> int.to_string(right_index)),
      ],
      [
        svgs.arrow_right(),
      ],
    ),
  ])
}

fn page_view(index: Int, item_count: Int) -> element.Element(a) {
  let page_count = case item_count % 20 == 0 {
    True -> item_count / 20 + 1
    False -> item_count / 20 + 1
  }
  html.p([class("page-view")], [
    text(
      int.to_string(index + 1) <> "/" <> int.to_string(page_count) <> " pages",
    ),
  ])
}

fn option_view(category: PartialCategory, selected: option.Option(String)) {
  let is_selected = case selected {
    option.Some(selected) if category.id_name == selected -> True
    _ -> False
  }
  html.option(
    [
      attribute.value(category.id_name),
      attribute.selected(is_selected),
    ],
    category.name,
  )
}

fn category_select_view(
  categories: List(PartialCategory),
  selected: option.Option(String),
) -> element.Element(a) {
  let attrs = [
    attribute.id("category"),
    attribute.name("category"),
  ]
  let options = list.map(categories, option_view(_, selected))
  let options = [
    html.option([attribute.value("")], "-- keine Auswahl --"),
    ..options
  ]
  html.div([class("category-search")], [
    html.label([attribute.for("#category")], [text("Kategoriefilter:")]),
    html.select(attrs, options),
  ])
}

pub fn views(state: ItemListState) -> element.Element(a) {
  let item_list_state.ItemListState(
    items:,
    item_count:,
    pagination_index: index,
    current_query:,
    categories:,
  ) = state

  html.div([], [
    searchbar(index, item_count, current_query, categories),
    html.div([class("item-views")], list.map(items, item_view)),
  ])
}

fn cost_view(cost: Int) -> element.Element(a) {
  let cost = case cost {
    0 -> "Preis: unverkäuflich/auffindbar"
    x -> "Preis: " <> int.to_string(x) <> "₽"
  }
  html.p([], [text(cost)])
}

fn item_view(item: PartialItem) -> element.Element(a) {
  let types.PartialItem(id:, name:, sprite:, category:, cost:) = item
  let id = int.to_string(id)
  html.div([class("item-view")], [
    html.a(
      [
        class("item-view-info"),
        attribute.href("/items/" <> id),
      ],
      [
        html.img([class("item-view-sprite"), attribute.src(sprite)]),
        html.div([], [
          html.h4([], [text(name)]),
          html.p([], [text("Kategorie: " <> category)]),
          cost_view(cost),
        ]),
      ],
    ),
    html.div([], [
      html.a(
        [
          class("item-view-cart"),
          attribute("hx-target", ".header-comp"),
          attribute("hx-post", "/cart/add/" <> id),
        ],
        [
          svgs.shopping_cart(),
        ],
      ),
    ]),
  ])
}
