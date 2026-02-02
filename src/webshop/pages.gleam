import simplifile

pub fn index() -> String {
  let assert Ok(index) = simplifile.read("./index.html")
  index
}

pub fn login() -> String {
  let assert Ok(login) = simplifile.read("./login.html")
  login
}

pub fn invalid_login() -> String {
  let assert Ok(login) = simplifile.read("./invalid_login.html")
  login
}
