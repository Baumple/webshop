import gleam/option
import gleeunit
import webshop/data/db
import webshop/data/poke_api

import webshop/sessions

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn session_ets_test() -> Nil {
  let assert Ok(ss) = sessions.new()

  let id = sessions.create_session(ss, username: "test")
  let assert Ok(option.Some(s)) = sessions.get(ss, id)

  assert { id == s.id && s.username == "test" }
}

pub fn fetch_data_test() -> Nil {
  let assert Ok(_) = poke_api.fetch_resource_entries("item-category")

  Nil
}

pub fn get_items_test() -> Nil {
  let assert Ok(db) = db.open()
  let assert Ok(_) = db.get_items(db, offset: 0, count: 20)
  Nil
}
