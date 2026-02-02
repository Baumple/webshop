import webshop/pages
import gleam/result
import webshop/data/db
import webshop/error

import sqlight

pub type Page =
  fn() -> String

pub type Context {
  Context(
    home_page: Page,
    login_page: Page,
    invalid_login_page: Page,
    db: sqlight.Connection,
  )
}

/// Creates a new context record but html pages are cached
pub fn new() -> Result(Context, error.WebshopError) {
  let home_page = pages.login()
  let login_page = pages.login()
  let invalid_page = pages.invalid_login()

  let home_page = fn() { home_page }
  let login_page = fn() { login_page }
  let invalid_login_page = fn() { invalid_page }

  db.open()
  |> result.map(Context(home_page:, login_page:, invalid_login_page:, db: _))
}

/// Creates a new context record but html pages are re-read
pub fn new_with_hot_reload() -> Result(Context, error.WebshopError) {
  let home_page = pages.index
  let login_page = pages.login
  let invalid_login_page = pages.invalid_login

  db.open()
  |> result.map(Context(home_page:, login_page:, invalid_login_page:, db: _))
}
