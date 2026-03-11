import gleam/option
import webshop/html/component_states/header_state
import webshop/html/pages
import wisp.{type Request, type Response}

import webshop/context.{type Context}
import webshop/router/middleware

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
