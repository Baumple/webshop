import sqlight

pub fn require_not_empty(
  l: List(a),
  continue: fn() -> Result(sqlight.Connection, b),
) -> Result(sqlight.Connection, b) {
  case l {
    [] -> Ok(Nil)
    _ -> continue()
  }
}
