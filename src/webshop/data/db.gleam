import gleam/dynamic/decode
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import sqlight.{type Connection}
import webshop/data/poke_api
import webshop/error.{type WebshopInitError}


pub type DBResult(a) {
  Found(a)
  NotFound
  SqlightError(sqlight.Error)
}

const scheme = "
  CREATE TABLE IF NOT EXISTS categories (
    id   INTEGER PRIMARY KEY,
    name TEXT NOT NULL
  );
  
  CREATE TABLE IF NOT EXISTS category_names (
    id   INTEGER REFERENCES categories(id),
    name TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS items (
    id           INTEGER PRIMARY KEY,
    name         TEXT NOT NULL,
    description  TEXT NOT NULL,
    sprite       TEXT NOT NULL,
    category     TEXT NOT NULL    REFERENCES categories(name),
    manufacturer INTEGER NOT NULL REFERENCES manufacturers(name),
    cost         INTEGER NOT NULL
  );

  CREATE TABLE IF NOT EXISTS item_names (
    id   INTEGER REFERENCES items(id),
    name TEXT NOT NULL
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
  case sqlight.query("SELECT COUNT (*) FROM items", db, [], decode.int) {
    // no data in database
    Ok([count]) if count == 0 -> update_database(db)

    // database has data
    Ok([_]) -> Ok(db)

    // database did not return expected data
    Ok(..) -> panic as "Invalid sql data."

    // some other sql error
    Error(err) -> Error(error.DBError(err))
  }
}

fn update_database(db: Connection) -> Result(Connection, WebshopInitError) {
  update_categories(db)
}

fn update_categories(db: Connection) -> Result(Connection, WebshopInitError) {
  use categories <- result.try(poke_api.fetch_categories())
  let insert_category_base = "INSERT INTO categories (id, name) VALUES\n"
  let statement =
    echo insert_category_base
      <> string.join(
        list.map(categories, fn(c) {
          "(" <> int.to_string(c.id) <> ", " <> c.name <> ")"
        }),
        ",",
      )
  sqlight.exec(statement, db)
  |> result.map_error(error.DBError)
  |> result.replace(db)
}

pub fn open() -> Result(Connection, WebshopInitError) {
  use db <- result.try(
    sqlight.open("file:pokeshop.db") |> result.map_error(error.DBError),
  )
  result.try(init_scheme(db), init_data)
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
