import gleam/int
import gleam/list
import gleam/option
import gleam/result
import wisp.{type Request, type Response}

import webshop/context.{type Context}
import webshop/data/db/query
import webshop/html/component_states/item_list_state
import webshop/html/pages
import webshop/router/login
import webshop/router/middleware
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

fn handle_home_page(ctx: Context, request: Request) -> Response {
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
    // valid session
    option.Some(session) -> {
      wisp.html_response(
        pages.index_with_username(session.username, state),
        200,
      )
    }
    // invalid session or not logged in
    option.None -> wisp.html_response(pages.index(state), 200)
  }
}
