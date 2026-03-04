import webshop/data/db
import webshop/data/types
import wisp.{type Request, type Response}

import webshop/context.{type Context}
import webshop/error
import webshop/html/pages
import webshop/sessions

/// requires a cookie to be set
pub fn require_cookie(
  request: Request,
  name: String,
  continue: fn(String) -> Response,
) -> Response {
  case wisp.get_cookie(request, name, wisp.PlainText) {
    Error(Nil) ->
      wisp.ok()
      |> wisp.html_body(pages.login())
    Ok(session_id) -> continue(session_id)
  }
}

/// confirms whether the user has a valid session id, 
/// otherwise prompts them redirects them to the login page
pub fn require_session_id(
  ctx: Context,
  request: Request,
  continue: fn(String) -> Response,
) -> Response {
  use session_id <- require_cookie(request, "SESSIONID")
  case sessions.exists(ctx.sessions, session_id) {
    Ok(True) -> continue(session_id)
    Ok(False) -> wisp.html_response(pages.login(), 200)
    Error(err) -> error.log_ets_error(err)
  }
}

pub fn require_partial_items(
  ctx: Context,
  continue: fn(List(types.PartialItem)) -> Response,
) -> Response {
  case db.get_items(ctx.db, 0, 20) {
    Ok(items) -> continue(items)
    Error(err) -> error.log_sql_error(err)
  }
}
