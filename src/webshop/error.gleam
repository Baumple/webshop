import sqlight

pub type WebshopError {
  DBError(sqlight.Error)
  InvalidUsername
}
