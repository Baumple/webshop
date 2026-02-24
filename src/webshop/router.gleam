import webshop/router/register
import webshop/router/validate
import wisp.{type Request, type Response}

import webshop/context.{type Context}
import webshop/html/pages
import webshop/router/components
import webshop/router/login

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
    ["register", ..] -> register.handle(ctx, request)
    ["validate", field] -> validate.handle(ctx, request, field)
    [] -> handle_home_page(ctx, request)
    _ -> wisp.not_found()
  }
}

/// confirms whether the user has a valid session id, 
/// otherwise prompts them to log in/create an account
fn confirm_logged_in(
  _ctx: Context,
  request: Request,
  continue: fn(String) -> Response,
) -> Response {
  case wisp.get_cookie(request, "SESSIONID", wisp.Signed) {
    Error(Nil) ->
      wisp.ok()
      |> wisp.html_body(pages.login())

    Ok(session_id) -> continue(session_id)
  }
}

fn handle_home_page(ctx: Context, request: Request) -> Response {
  use _session_id <- confirm_logged_in(ctx, request)
  wisp.ok() |> wisp.html_body(pages.index())
}
