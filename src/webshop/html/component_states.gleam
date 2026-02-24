import gleam/option.{type Option, None}

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

pub fn new_register_state() -> RegisterState {
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
