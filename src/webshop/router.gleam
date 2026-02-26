import wisp.{type Request, type Response}

import webshop/context.{type Context}
import webshop/error
import webshop/html/pages
import webshop/router/login
import webshop/router/users
import webshop/sessions

fn middleware(request: Request, continue: fn(Request) -> Response) -> Response {
  let request = wisp.method_override(request)
  use <- wisp.log_request(request)
  use <- wisp.rescue_crashes()
  use request <- wisp.handle_head(request)
  use request <- wisp.csrf_known_header_protection(request)
  continue(request)
}

pub fn handler(ctx: Context, request: Request) -> Response {
  use request <- middleware(request)
  case wisp.path_segments(request) {
    ["login"] -> login.handle(ctx, request)
    ["users", ..] -> users.handle(ctx, request)
    ["cookies", "clear"] -> {
      let assert Ok(_) = sessions.clear(ctx.sessions)
      handle_home_page(ctx, request)
    }
    [] -> handle_home_page(ctx, request)
    _ -> wisp.not_found()
  }
}

/// requires a cookie to be set
fn require_cookie(
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
fn require_logged_in(
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

fn handle_home_page(ctx: Context, request: Request) -> Response {
  use _session_id <- require_logged_in(ctx, request)
  wisp.ok() |> wisp.html_body(pages.index())
}
