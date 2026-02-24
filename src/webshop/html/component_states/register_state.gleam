import gleam/option.{type Option, None, Some}
import gleam/string

import webshop/context.{type Context}

pub type RegisterState {
  RegisterState(
    username: String,
    name: String,
    surname: String,
    street: String,
    house_number: Option(Int),
    postal_code: Option(Int),
    location: String,
    bin: Option(Int),
    institution: String,
    password: String,
  )
}

pub fn new() -> RegisterState {
  RegisterState(
    username: "",
    name: "",
    surname: "",
    street: "",
    house_number: None,
    postal_code: None,
    location: "",
    bin: None,
    institution: "",
    password: "",
  )
}

pub fn validated(state: RegisterState) -> Result(RegisterState, RegisterState) {
  case
    is_valid_username(state.username)
    && is_valid_house_number(state.house_number)
    && is_valid_postal_code(state.postal_code)
    && is_valid_bin(state.bin)
    && is_valid_password(state.password)
  {
    True -> Ok(state)
    False -> Error(state)
  }
}

pub fn is_valid_password(pwd: String) -> Bool {
  !string.starts_with(pwd, " ") && !string.ends_with(pwd, " ")
}

pub fn is_valid_postal_code(pc: Option(Int)) -> Bool {
  case pc {
    Some(_) -> True
    None -> False
  }
}

pub fn is_valid_house_number(hn: Option(Int)) -> Bool {
  case hn {
    Some(_) -> True
    None -> False
  }
}

pub fn is_valid_username(username: String) -> Bool {
  !string.starts_with(username, " ") && !string.ends_with(username, " ")
}

pub fn is_valid_bin(bin: Option(Int)) -> Bool {
  case bin {
    Some(_) -> True
    None -> False
  }
}
