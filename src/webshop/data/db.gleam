import gleam/dynamic/decode
import gleam/result
import sqlight.{type Connection}

import webshop/error

const scheme = "
  CREATE TABLE IF NOT EXISTS manufacturers (
    name  TEXT PRIMARY KEY,
    web   TEXT NOT NULL,
    email TEXT NOT NULL
  );
  INSERT OR IGNORE INTO manufacturers (name, web, email)
    VALUES ('Hewlett Packard', 'www.hp.de', 'info@hp.de'),
           ('Siemens', 'www.siemens.de', 'support@siemens.de'),
           ('Medion', 'www.medion.de', 'support@medion.de');

  CREATE TABLE IF NOT EXISTS categories (
    name TEXT PRIMARY KEY
  );
  INSERT OR IGNORE INTO categories 
    VALUES ('Scanner'), ('Monitore'), ('Drucker');

  CREATE TABLE IF NOT EXISTS products (
    name         TEXT PRIMARY KEY,
    description  TEXT NOT NULL,
    category     TEXT NOT NULL    REFERENCES categories(name),
    manufacturer INTEGER NOT NULL REFERENCES manufacturers(name),
    price        INTEGER NOT NULL
  );
  INSERT OR IGNORE INTO products (name, description, category, manufacturer, price)
    VALUES 
           ('HP ScanJet3300C', 'Flachbettscanner', 'Scanner', 'Hewlett Packard', 99),
           ('HP ScanJet2220A', 'Flachbettscanner', 'Scanner', 'Hewlett Packard', 56),
           ('HP LaserJet 3477C', 'Laserdrucker', 'Drucker', 'Hewlett Packard', 299),
           ('HP LaserJet 7769C', 'Farblaserdrucker', 'Drucker', 'Hewlett Packard', 1590),
           ('MD 1772 JC', 'Monitor', 'Monitore', 'Medion', 150),
           ('MD 6155 AH', '23 Zoll LC Monitor', 'Monitore', 'Medion', 250),
           ('MD 1334 S', 'Flachbettscanner', 'Scanner', 'Medion', 65),
           ('MD 2443 S', 'Flachbettscanner', 'Scanner', 'Medion', 76),
           ('SI 1221 C', '24 Zoll Monitor', 'Monitor', 'Siemens', 200),
           ('SI 7822 TFT', '27 Zoll TFT-Monitor', 'Monitor', 'Siemens', 369),
           ('SI D1121 C', 'Farblaserdrucker', 'Drucker', 'Siemens', 447);

    CREATE TABLE IF NOT EXISTS customers (
      username     TEXT PRIMARY KEY,
      name         TEXT NOT NULL,
      surname      TEXT NOT NULL,
      street       TEXT NOT NULL,
      house_number INTEGER NOT NULL,
      postal_code  INTEGER NOT NULL,
      location     TEXT NOT NULL,
      bin          INTEGER NOT NULL,
      institute    TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS user_password (
      username TEXT PRIMARY KEY REFERENCES customers(username),
      hash     TEXT NOT NULL
    );

"

fn init_scheme(db: Connection) -> Result(Connection, error.WebshopError) {
  case sqlight.exec(scheme, db) {
    Error(err) -> Error(error.DBError(err))
    Ok(Nil) -> Ok(db)
  }
}

pub fn open() -> Result(Connection, error.WebshopError) {
  use db <- result.try(
    sqlight.open("file:pokeshop.db")
    |> result.map_error(error.DBError),
  )
  init_scheme(db)
}

const username_password_query = "
  SELECT hash FROM username_password WHERE username = ?
"

pub fn get_username_password_hash(
  db: Connection,
  username: String,
) -> Result(String, error.WebshopError) {
  let res =
    sqlight.query(
      username_password_query,
      db,
      [sqlight.text(username)],
      decode.string,
    )

  case res {
    Ok([hash]) -> Ok(hash)
    Ok([]) -> Error(error.InvalidUsername)
    Error(err) -> Error(error.DBError(err))
    _ -> panic as "Invalid server state."
  }
}

pub fn insert_session() {
}
