import gleam/result

import webshop/data/db
import webshop/error

import sqlight

pub type Context {
  Context(db: sqlight.Connection)
}

/// Opens a database connection and creates a new context record
pub fn new() -> Result(Context, error.WebshopInitError) {
  db.open()
  |> result.map(Context(db: _))
}
