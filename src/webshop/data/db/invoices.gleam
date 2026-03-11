import cake/adapter/sqlite
import cake/insert
import gleam/dynamic/decode
import gleam/float
import gleam/list
import gleam/result
import gleam/time/timestamp
import sqlight.{type Connection}

import webshop/data/types

fn do_insert_incoice(
  db: Connection,
  invoice: types.Invoice,
) -> Result(Int, sqlight.Error) {
  let int = timestamp.to_unix_seconds(invoice.date) |> float.round
  let res =
    insert.from_values(
      table_name: "invoices",
      columns: ["username", "date"],
      values: [
        insert.row([
          insert.string(invoice.username),
          insert.int(int),
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

fn insert_invoice_entries(
  db: Connection,
  invoice_id: Int,
  invoice: types.Invoice,
) {
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
  invoice: types.Invoice,
) -> Result(Nil, sqlight.Error) {
  use invoice_id <- result.try(do_insert_incoice(db, invoice))
  insert_invoice_entries(db, invoice_id, invoice)
}
