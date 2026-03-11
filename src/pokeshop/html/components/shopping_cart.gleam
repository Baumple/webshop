import gleam/int
import gleam/list
import gleam/time/calendar
import gleam/time/duration
import gleam/time/timestamp
import lustre/attribute.{attribute, class}
import lustre/element
import lustre/element/html.{text}

import pokeshop/data/types.{type Cart}

pub fn view(
  username _username: String,
  cart cart: Cart,
  invoices invoices: List(types.Invoice),
) -> element.Element(a) {
  html.div([class("cart-view")], [
    html.h2([], [text("Warenkorb")]),
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
    html.h2([], [text("Rechnungen")]),
    html.div(
      [class("invoices")],
      list.map(list.reverse(invoices), invoice_view),
    ),
  ])
}

fn invoice_view(invoice: types.Invoice) -> element.Element(a) {
  let #(date, time_of_day) =
    timestamp.to_calendar(invoice.date, duration.seconds(0))
  let date =
    int.to_string(date.day)
    <> "."
    <> calendar.month_to_int(date.month) |> int.to_string
    <> "."
    <> int.to_string(date.year)
    <> " "
    <> int.to_string(time_of_day.hours)
    <> ":"
    <> int.to_string(time_of_day.minutes)

  let total_price =
    list.fold(invoice.entries, 0, fn(acc, entry) {
      acc + entry.price_per_item * entry.amount
    })
    |> int.to_string
    <> "₽"

  html.div([class("invoice")], [
    html.h3(
      [class("invoice-title"), attribute.style("border-bottom", "dotted 1px")],
      [
        text("Rechnung vom: " <> date),
      ],
    ),
    html.div(
      [class("invoice-entries")],
      list.map(invoice.entries, invoice_entry_view),
    ),
    html.p([class("invoice-total")], [text("Gesamtpreis: " <> total_price)]),
  ])
}

fn invoice_entry_view(invoice_entry: types.InvoiceEntry) -> element.Element(a) {
  html.div([class("invoice-entry")], [
    html.p([], [text("Positionsname: " <> invoice_entry.item_name)]),
    html.p([], [
      text("Stückpreis: " <> int.to_string(invoice_entry.price_per_item) <> "₽"),
    ]),
    html.p([], [
      text("Anzahl: " <> int.to_string(invoice_entry.amount) <> "x"),
    ]),
    html.p([], [
      text(
        "Position gesamt: "
        <> int.to_string(invoice_entry.amount * invoice_entry.price_per_item)
        <> "₽",
      ),
    ]),
  ])
}

pub fn item_view(entry: #(types.PartialItem, Int)) -> element.Element(a) {
  let #(partial_item, count) = entry
  let types.PartialItem(id: _, name:, sprite: _, category: _, cost: _) =
    partial_item

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
