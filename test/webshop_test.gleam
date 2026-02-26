import gleam/option
import gleeunit

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
