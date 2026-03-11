import gleam/list
import gleam/option
import gleam/result
import gleeunit
import webshop/data/db
import webshop/data/db/query
import webshop/data/poke_api
import webshop/data/types

import webshop/sessions

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn session_ets_test() -> Nil {
  let assert Ok(ss) = sessions.new()

  let id = sessions.create_session(ss, username: "test")
  let assert Ok(option.Some(s)) = sessions.get(ss, id)

  let assert True = {
    id == s.id && s.username == "test"
  }
  Nil
}

pub fn fetch_data_test() -> Nil {
  let assert Ok(_) = poke_api.fetch_resource_entries("item-category")

  Nil
}

pub fn get_items_test() -> Nil {
  let assert Ok(db) = db.open()
  let assert Ok(_) = db.get_items(db, query.empty(), 0, 20)
  Nil
}

pub fn get_categories_test() -> Nil {
  let assert Ok(db) = db.open()
  let assert Ok(_) = db.get_categories(db)
  Nil
}

pub fn add_item_to_cart_test() -> Nil {
  let assert Ok(db) = db.open()

  let assert Ok(start) = db.get_user_cart(db, "testuser")
  let start_count = get_item_count(start.items, 6)

  let assert Ok(Nil) = db.add_item_to_cart(db, "testuser", 6)
  let assert Ok(end) = db.get_user_cart(db, "testuser")

  let end_count = get_item_count(end.items, 6)

  let assert True = {
    end_count == start_count + 1
  }
  Nil
}

fn get_item_count(items: List(#(types.PartialItem, Int)), item_id) {
  list.find(items, fn(item) {
    let #(partial_item, _) = item
    partial_item.id == item_id
  })
  |> result.map(fn(item) {
    let #(_, count) = item
    count
  })
  |> result.unwrap(0)
}

pub fn delete_item_from_cart_test() {
  let assert Ok(db) = db.open()
  let assert Ok(Nil) = db.delete_item_from_cart(db, "testuser", 1)
}

pub fn remove_item_from_cart_test() {
  let assert Ok(db) = db.open()
  let assert Ok(Nil) = db.delete_item_from_cart(db, "testuser", 1)
  let assert Ok(_) = db.add_item_to_cart(db, "testuser", 1)
  let assert Ok(_) = db.add_item_to_cart(db, "testuser", 1)
  let assert Ok(Nil) = db.remove_item_from_cart(db, "testuser", 1)
  let assert Ok(cart) = db.get_user_cart(db, "testuser")
  let assert 1 = get_item_count(cart.items, 1)
  let assert Ok(Nil) = db.delete_item_from_cart(db, "testuser", 1)
}
