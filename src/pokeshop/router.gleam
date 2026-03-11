import gleam/int
import gleam/option
import pokeshop/html/component_states/header_state
import pokeshop/router/buy
import wisp.{type Request, type Response}

import pokeshop/context.{type Context}
import pokeshop/data/db/query
import pokeshop/html/component_states/item_list_state
import pokeshop/html/pages
import pokeshop/router/cart
import pokeshop/router/items
import pokeshop/router/login
import pokeshop/router/middleware
import pokeshop/router/users
import pokeshop/sessions

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
    ["login"] -> login.handle(request, ctx)
    ["users", ..] -> users.handle(request, ctx)
    ["items", id] -> items.handle(request, ctx, id)
    ["cart", ..path] -> cart.handle(request, ctx, path)
    ["buy"] -> buy.handle(request, ctx)
    ["cookies", "clear"] -> {
      let assert Ok(_) = sessions.clear(ctx.sessions)
      handle_home_page(request, ctx)
    }
    [] -> handle_home_page(request, ctx)
    _ -> wisp.not_found()
  }
}

fn handle_home_page(request: Request, ctx: Context) -> Response {
  use session <- middleware.get_session_if_exists(ctx, request)

  let query = query.from_request(request)
  use item_count <- middleware.get_item_count(ctx, query)

  let index = query.get_index(query)
  let index = case item_count % 20 == 0 {
    True -> int.clamp(index, 0, item_count / 20 - 1)
    False -> int.clamp(index, 0, item_count / 20)
  }

  use items <- middleware.get_partial_items(
    ctx,
    query,
    offset: index * 20,
    limit: 20,
  )
  use categories <- middleware.get_categories(ctx)

  let state =
    item_list_state.ItemListState(
      items:,
      item_count:,
      pagination_index: index,
      current_query: query,
      categories:,
    )

  case session {
    option.Some(session) -> {
      use cart <- middleware.get_cart(ctx, session.username)
      wisp.html_response(
        pages.index_with_username(
          session.username,
          state,
          header_state.LoggedIn(username: session.username, cart:),
        ),
        200,
      )
    }
    // invalid session or not logged in
    option.None ->
      wisp.html_response(pages.index(state, header_state.LoggedOut), 200)
  }
}
