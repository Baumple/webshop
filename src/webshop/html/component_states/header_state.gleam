import webshop/data/types

pub type HeaderState {
  LoggedIn(
    username: String,
    cart: types.Cart,
  )
  LoggedOut
}

pub fn new() -> HeaderState {
  LoggedOut
}
