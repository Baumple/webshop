import gleam/result
import webshop/sessions

import webshop/data/db
import webshop/error

import dream_ets/table
import sqlight

pub type Context {
  Context(
    db: sqlight.Connection,
    sessions: table.Table(String, sessions.Session),
  )
}

/// Opens a database connection and creates a new context record
pub fn new() -> Result(Context, error.WebshopInitError) {
  use sessions <- result.try(sessions.new())
  use db <- result.try(
    db.open()
    |> result.map(db.initialize_data_async),
  )

  Ok(Context(db:, sessions:))
}
