import gleam/int
import gleam/option.{type Option, None, Some}
import gleam/string
import sqlight

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

pub type ValidationState {
  Valid(RegisterState)
  Invalid
  SQLError(sqlight.Error)
}

pub fn validated(state: RegisterState) -> ValidationState {
  case
    is_valid_username(state.username)
    && is_valid_house_number(state.house_number)
    && is_valid_postal_code(state.postal_code)
    && is_valid_bin(state.bin)
    && is_valid_password(state.password)
  {
    True -> Valid(state)
    False -> Invalid
  }
}

pub fn is_valid_password(pwd: String) -> Bool {
  !string.starts_with(pwd, " ")
  && !string.ends_with(pwd, " ")
  && string.length(pwd) >= 8
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
    Some(x) -> {
      let s = int.to_string(x) |> string.length
      s == 6 || s == 8
    }

    None -> False
  }
}

pub fn is_valid_bin_string(bin: String) -> Bool {
  int.parse(bin)
  |> option.from_result
  |> is_valid_bin
}

pub fn is_valid_postal_code_string(pc: String) -> Bool {
  int.parse(pc)
  |> option.from_result
  |> is_valid_postal_code
}

pub fn is_valid_house_number_string(house_number: String) -> Bool {
  int.parse(house_number)
  |> option.from_result
  |> is_valid_house_number
}
