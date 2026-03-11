import gleam/erlang/process
import gleam/result
import sqlight.{type Connection}
import webshop/data/db/invoices
import wisp

import webshop/data/db/category
import webshop/data/db/customer
import webshop/data/db/db_result.{type SqlResult as DBResult}
import webshop/data/db/items
import webshop/data/db/query
import webshop/data/types.{type Customer, type Item}
import webshop/error.{type WebshopInitError}

pub fn open() -> Result(Connection, WebshopInitError) {
  use db <- result.try(
    sqlight.open("file:pokeshop.db") |> result.map_error(error.DBError),
  )
  init_scheme(db)
}

pub fn initialize_data_async(db: Connection) -> Connection {
  process.spawn(fn() { update_data(db) })
  db
}

pub fn initialize_data(db: Connection) -> Result(Connection, WebshopInitError) {
  update_data(db)
  |> result.replace(db)
}

const scheme = "
  CREATE TABLE IF NOT EXISTS categories (
    id     INTEGER PRIMARY KEY,
    name   TEXT NOT NULL,
    pocket TEXT NOT NULL
  );
  
  CREATE TABLE IF NOT EXISTS category_names (
    category_id INTEGER NOT NULL REFERENCES categories(id),
    language    TEXT NOT NULL,
    name        TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS items (
    id           INTEGER PRIMARY KEY,
    name         TEXT NOT NULL,
    sprite       TEXT NOT NULL,
    category     TEXT NOT NULL REFERENCES categories(name),
    cost         INTEGER NOT NULL
  );

  CREATE TABLE IF NOT EXISTS item_effect_entries (
    item_id      INTEGER NOT NULL REFERENCES items(id),
    language     TEXT NOT NULL,
    effect       TEXT NOT NULL,
    short_effect TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS item_attributes (
    item_id   INTEGER NOT NULL REFERENCES items(id),
    attribute TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS item_names (
    item_id  INTEGER NOT NULL REFERENCES items(id),
    language TEXT NOT NULL,
    name     TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS customers (
    username     TEXT NOT NULL PRIMARY KEY,
    name         TEXT NOT NULL,
    surname      TEXT NOT NULL,
    street       TEXT NOT NULL,
    house_number INTEGER NOT NULL,
    postal_code  INTEGER NOT NULL,
    location     TEXT NOT NULL,
    bin          INTEGER NOT NULL,
    institution  TEXT NOT NULL,
    hash         TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS cart_items (
    username TEXT NOT NULL REFERENCES customers(username),
    item_id  INT NOT NULL REFERENCES items(id),
    count    INT NOT NULL CHECK (count > 0),
    PRIMARY KEY (username, item_id)
  );

  CREATE TABLE IF NOT EXISTS invoices (
    id       INTEGER PRIMARY KEY,
    username TEXT NOT NULL REFERENCES customers(username),
    date     TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS invoice_entries (
    invoice_id     INTEGER NOT NULL REFERENCES invoices(id),
    item_id        INTEGER NOT NULL REFERENCES items(id),
    item_name      TEXT NOT NULL,
    price_per_item INTEGER NOT NULL,
    amount         INTEGER NOT NULL,

    PRIMARY KEY (invoice_id, item_id)
  );

"

fn init_scheme(db: Connection) -> Result(Connection, WebshopInitError) {
  case sqlight.exec(scheme, db) {
    Error(err) -> Error(error.DBError(err))
    Ok(Nil) -> Ok(db)
  }
}

fn update_data(db: Connection) -> Result(Nil, WebshopInitError) {
  wisp.log_info("Updating database.")
  use _ <- result.try(category.update_categories(db))
  use _ <- result.try(items.update_items(db))
  Ok(Nil)
}

pub const get_username_password_hash = customer.get_username_password_hash

pub const username_exists = customer.username_exists

pub const insert_customer = customer.insert_customer

pub const get_items = items.get_partial_items_range

pub const get_item_by_id = items.get_item_by_id

pub const get_item_count = items.get_item_count

pub const get_categories = category.get_categories

pub const get_user_cart = items.get_cart_items

pub const add_item_to_cart = items.add_item_to_cart

pub const remove_item_from_cart = items.remove_item_from_cart

pub const delete_item_from_cart = items.delete_item_from_cart

pub const clear_item_cart = items.clear_cart

pub const insert_invoice = invoices.insert_invoice
