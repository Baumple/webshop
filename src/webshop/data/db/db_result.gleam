import sqlight

pub type SqlResult(a) {
  Success(a)
  NotFound
  FailedQuery(sqlight.Error)
}

pub fn try(res: SqlResult(a), map: fn(a) -> SqlResult(b)) -> SqlResult(b) {
  case res {
    Success(a) -> map(a)
    NotFound -> NotFound
    FailedQuery(err) -> FailedQuery(err)
  }
}
