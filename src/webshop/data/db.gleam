import gleam/dynamic/decode
import gleam/result
import sqlight.{type Connection}
import wisp

import webshop/data/db/category
import webshop/data/db/items
import webshop/error.{type WebshopInitError}

pub type DBResult(a) {
  Found(a)
  NotFound
  SqlightError(sqlight.Error)
}

pub fn open() -> Result(Connection, WebshopInitError) {
  use db <- result.try(
    sqlight.open("file:pokeshop.db") |> result.map_error(error.DBError),
  )
  result.try(init_scheme(db), init_data)
}

const scheme = "
  CREATE TABLE IF NOT EXISTS categories (
    id     INTEGER PRIMARY KEY,
    name   TEXT NOT NULL,
    pocket TEXT NOT NULL
  );
  
  CREATE TABLE IF NOT EXISTS category_names (
    category_id INTEGER REFERENCES categories(id),
    language    TEXT NOT NULL,
    name        TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS items (
    id           INTEGER PRIMARY KEY,
    name         TEXT NOT NULL,
    sprite       TEXT NOT NULL,
    category     TEXT NOT NULL    REFERENCES categories(name),
    cost         INTEGER NOT NULL
  );

  CREATE TABLE IF NOT EXISTS item_effect_entries (
    item_id      INTEGER REFERENCES items(id),
    language     TEXT NOT NULL,
    effect       TEXT NOT NULL,
    short_effect TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS item_attributes (
    item_id   INTEGER REFERENCES items(id),
    attribute TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS item_names (
    item_id INTEGER REFERENCES items(id),
    name    TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS item_attributes (
    item_id   INTEGER REFERENCES items(id),
    attribute TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS customers (
    username     TEXT PRIMARY KEY,
    name         TEXT NOT NULL,
    surname      TEXT NOT NULL,
    street       TEXT NOT NULL,
    house_number INTEGER NOT NULL,
    postal_code  INTEGER NOT NULL,
    location     TEXT NOT NULL,
    bin          INTEGER NOT NULL,
    institute    TEXT NOT NULL,
    hash         TEXT NOT NULL
  );

"

fn init_scheme(db: Connection) -> Result(Connection, WebshopInitError) {
  case sqlight.exec(scheme, db) {
    Error(err) -> Error(error.DBError(err))
    Ok(Nil) -> Ok(db)
  }
}

fn init_data(db: Connection) -> Result(Connection, WebshopInitError) {
  case
    sqlight.query("SELECT COUNT(*) FROM items", db, [], decode.list(decode.int))
  {
    // no data in database
    Ok([[count]]) if count == 0 -> update_database(db)

    // database has data
    Ok([_]) -> Ok(db)

    // database did not return expected data
    Ok(..) -> panic as "Invalid sql data."

    // some other sql error
    Error(err) -> Error(error.DBError(err))
  }
}

fn clear_database(
  db: Connection,
  continue,
) -> Result(Connection, WebshopInitError) {
  let stmts =
    "
  DELETE FROM categories;
  DELETE FROM item_names;
  DELETE FROM item_attributes;
  DELETE FROM categories;
  DELETE FROM category_names;
  DELETE FROM customers;
  "

  case sqlight.exec(stmts, db) {
    Ok(_) -> {
      wisp.log_info("Cleared database.")
      continue()
    }
    Error(err) -> Error(error.DBError(err))
  }
}

fn update_database(db: Connection) -> Result(Connection, WebshopInitError) {
  wisp.log_info("Updating database.")
  use <- clear_database(db)
  use <- category.update_categories(db)
  use <- items.update_items(db)
  todo
}

const username_password_query = "
  SELECT hash FROM username_password WHERE username = ?
"

pub fn get_username_password_hash(
  db: Connection,
  username: String,
) -> DBResult(String) {
  let res =
    sqlight.query(
      username_password_query,
      db,
      [sqlight.text(username)],
      decode.string,
    )

  case res {
    Ok([hash]) -> Found(hash)
    Ok([]) -> NotFound
    Error(err) -> SqlightError(err)
    _ -> panic as "Invalid sql data."
  }
}

pub fn insert_session() {
  todo
}
