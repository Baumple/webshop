import gleam/int
import gleam/option
import webshop/error
import webshop/router/middleware
import wisp.{type Request, type Response}

import webshop/context.{type Context}
import webshop/html/pages
import webshop/router/login
import webshop/router/users
import webshop/sessions

fn default_middleware(
  request: Request,
  continue: fn(Request) -> Response,
) -> Response {
  let request = wisp.method_override(request)
  use <- wisp.log_request(request)
  use <- wisp.rescue_crashes()
  use request <- wisp.handle_head(request)
  use request <- wisp.csrf_known_header_protection(request)
  use <- wisp.serve_static(request, under: "/static", from: "./static")
  continue(request)
}

pub fn handler(ctx: Context, request: Request) -> Response {
  use request <- default_middleware(request)
  case wisp.path_segments(request) {
    ["login"] -> login.handle(ctx, request)
    ["users", ..] -> users.handle(ctx, request)
    ["items", id] -> handle_items(ctx, id)
    ["cookies", "clear"] -> {
      let assert Ok(_) = sessions.clear(ctx.sessions)
      handle_home_page(ctx, request)
    }
    [] -> handle_home_page(ctx, request)
    _ -> wisp.not_found()
  }
}

fn require_int_id(id: String, continue) -> Response {
  case int.parse(id) {
    Ok(id) -> continue(id)
    Error(Nil) -> wisp.bad_request("param `id` invalid")
  }
}

fn handle_items(ctx: Context, id: String) -> Response {
  use id <- require_int_id(id)
  use item <- middleware.require_item(ctx, id)
  pages.item(item)
  |> wisp.html_response(200)
}

// TODO: let users view home page without being logged in
fn handle_home_page(ctx: Context, request: Request) -> Response {
  use session_id <- middleware.require_session_id(ctx, request)
  let session = sessions.get(ctx.sessions, session_id)
  case session {
    Ok(session) -> {
      use items <- middleware.require_partial_items(ctx)
      case session {
        option.Some(session) ->
          wisp.html_response(
            pages.index_with_username(session.username, items),
            200,
          )
        option.None -> wisp.html_response(pages.index(items), 200)
      }
    }
    Error(err) -> error.log_ets_error(err)
  }
}
