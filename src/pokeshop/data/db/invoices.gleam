import cake/adapter/sqlite
import cake/insert
import cake/select
import cake/where
import gleam/dynamic/decode
import gleam/float
import gleam/list
import gleam/result
import gleam/time/timestamp
import sqlight.{type Connection}

import pokeshop/data/types.{type Invoice}

fn do_insert_incoice(
  db: Connection,
  invoice: Invoice,
) -> Result(Int, sqlight.Error) {
  let date = timestamp.to_unix_seconds(invoice.date) |> float.round
  let res =
    insert.from_values(
      table_name: "invoices",
      columns: ["username", "date"],
      values: [
        insert.row([
          insert.string(invoice.username),
          insert.int(date),
        ]),
      ],
    )
    |> insert.returning(["id"])
    |> insert.to_query()
    |> sqlite.run_write_query(
      {
        use id <- decode.field(0, decode.int)
        decode.success(id)
      },
      db,
    )

  case res {
    Ok([id]) -> Ok(id)
    Ok(_) -> panic as "Invalid sql response"
    Error(err) -> Error(err)
  }
}

fn insert_invoice_entries(db: Connection, invoice_id: Int, invoice: Invoice) {
  let rows =
    list.map(invoice.entries, fn(entry) {
      insert.row([
        insert.int(invoice_id),
        insert.int(entry.item_id),
        insert.string(entry.item_name),
        insert.int(entry.price_per_item),
        insert.int(entry.amount),
      ])
    })
  insert.from_values(
    table_name: "invoice_entries",
    columns: ["invoice_id", "item_id", "item_name", "price_per_item", "amount"],
    values: rows,
  )
  |> insert.to_query()
  |> sqlite.run_write_query(decode.dynamic, db)
  |> result.replace(Nil)
}

pub fn insert_invoice(
  db: Connection,
  invoice: Invoice,
) -> Result(Nil, sqlight.Error) {
  use invoice_id <- result.try(do_insert_incoice(db, invoice))
  insert_invoice_entries(db, invoice_id, invoice)
}

fn invoice_decoder() -> decode.Decoder(types.Invoice) {
  use id <- decode.field(0, decode.int)
  use username <- decode.field(1, decode.string)
  use date <- decode.field(2, decode.int)
  let date = timestamp.from_unix_seconds(date)
  decode.success(types.Invoice(id:, username:, date:, entries: []))
}

fn invoice_entry_decoder() -> decode.Decoder(types.InvoiceEntry) {
  use item_id <- decode.field(1, decode.int)
  use item_name <- decode.field(2, decode.string)
  use price_per_item <- decode.field(3, decode.int)
  use amount <- decode.field(4, decode.int)
  decode.success(types.InvoiceEntry(
    item_id:,
    item_name:,
    price_per_item:,
    amount:,
  ))
}

fn get_invoice_entries(
  db: Connection,
  invoice: Invoice,
) -> Result(Invoice, sqlight.Error) {
  select.new()
  |> select.select_cols([
    "invoice_id",
    "item_id",
    "item_name",
    "price_per_item",
    "amount",
  ])
  |> select.from_table("invoice_entries")
  |> select.where(where.eq(where.col("invoice_id"), where.int(invoice.id)))
  |> select.to_query()
  |> sqlite.run_read_query(invoice_entry_decoder(), db)
  |> result.map(fn(x) { types.Invoice(..invoice, entries: x) })
}

pub fn get_user_invoices(
  db: Connection,
  username: String,
) -> Result(List(Invoice), sqlight.Error) {
  let res =
    select.new()
    |> select.from_table("invoices")
    |> select.select_cols(["id", "username", "date"])
    |> select.where(where.eq(where.col("username"), where.string(username)))
    |> select.to_query()
    |> sqlite.run_read_query(invoice_decoder(), db)

  use invoices <- result.try(res)
  list.map(invoices, get_invoice_entries(db, _))
  |> result.all
}
