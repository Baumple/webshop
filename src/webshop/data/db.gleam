import cake/adapter/sqlite
import cake/insert
import cake/select
import cake/where
import gleam/dynamic/decode
import gleam/erlang/process
import gleam/result
import sqlight.{type Connection}
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
    count    INT NOT NULL CHECK (count > 0)
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

pub fn get_username_password_hash(
  db: Connection,
  username: String,
) -> DBResult(String) {
  customer.get_username_password_hash(db, username)
}

pub fn username_exists(
  db: Connection,
  username: String,
) -> Result(Bool, sqlight.Error) {
  customer.username_exists(db, username)
}

pub fn insert_customer(
  db: Connection,
  customer: Customer,
) -> Result(Nil, sqlight.Error) {
  customer.insert_customer(customer, db)
}

pub fn get_items(
  db: Connection,
  query: query.Query,
  offset offset: Int,
  count limit: Int,
) -> Result(List(types.PartialItem), sqlight.Error) {
  items.get_partial_items_range(db, query, offset:, count: limit)
}

pub fn get_item_by_id(db: Connection, id: Int) -> db_result.SqlResult(Item) {
  items.get_item_by_id(db, id)
}

pub fn get_item_count(
  db: Connection,
  query: query.Query,
) -> Result(Int, sqlight.Error) {
  items.get_item_count(db, query)
}

pub fn get_categories(db: Connection) {
  category.get_categories(db)
}

pub fn get_user_cart(
  db: Connection,
  username: String,
) -> Result(types.Cart, sqlight.Error) {
  items.get_cart_items(db, username)
}
