import gleam/option
import pokeshop/html/component_states/header_state
import pokeshop/html/pages
import wisp.{type Request, type Response}

import pokeshop/context.{type Context}
import pokeshop/router/middleware

pub fn handle(request: Request, ctx: Context, id: String) -> Response {
  use id <- middleware.require_int_id(id)
  use item <- middleware.require_item(ctx, id)
  use session <- middleware.get_session_if_exists(ctx, request)
  case session {
    option.Some(session) -> {
      use cart <- middleware.get_cart(ctx, session.username)
      pages.item(item, header_state.LoggedIn(username: session.username, cart:))
      |> wisp.html_response(200)
    }
    option.None ->
      pages.item(item, header_state.LoggedOut)
      |> wisp.html_response(200)
  }
}
