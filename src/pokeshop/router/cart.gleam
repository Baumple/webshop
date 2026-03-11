import lustre/element
import pokeshop/html/components
import pokeshop/html/pages
import pokeshop/router/middleware
import wisp.{type Request, type Response}

import pokeshop/context.{type Context}

pub fn handle(request: Request, ctx: Context, path: List(String)) -> Response {
  case path {
    ["add", id] -> add_item_to_cart(request, ctx, id)
    ["cadd", id] -> add_item_to_cart_count(request, ctx, id)
    ["remove", id] -> remove_item_from_cart(request, ctx, id)
    ["delete", id] -> delete_item_from_cart(request, ctx, id)
    ["view"] -> display_cart(ctx, request)
    _ -> wisp.not_found()
  }
}

fn delete_item_from_cart(request: Request, ctx: Context, id: String) -> Response {
  use session <- middleware.require_session(ctx, request)
  use id <- middleware.require_int_id(id)
  use <- middleware.require_delete_item_from_cart(ctx, session.username, id)
  use cart <- middleware.get_cart(ctx, session.username)
  use invoices <- middleware.require_user_invoices(ctx, session.username)

  pages.shopping_cart(cart.username, cart, invoices)
  |> wisp.html_response(200)
  |> wisp.set_header("Hx-Redirect", "/cart/view")
}

fn remove_item_from_cart(request: Request, ctx: Context, id: String) -> Response {
  use session <- middleware.require_session(ctx, request)
  use id <- middleware.require_int_id(id)
  use <- middleware.require_remove_item_from_cart(ctx, session.username, id)
  use cart <- middleware.get_cart(ctx, session.username)
  use invoices <- middleware.require_user_invoices(ctx, session.username)

  pages.shopping_cart(cart.username, cart, invoices)
  |> wisp.html_response(200)
  |> wisp.set_header("Hx-Redirect", "/cart/view")
}

fn do_add_item(request: Request, ctx: Context, id: String, continue) -> Response {
  use session <- middleware.require_session(ctx, request)
  use id <- middleware.require_int_id(id)
  use <- middleware.require_add_item_to_cart(ctx, session.username, id)
  use cart <- middleware.get_cart(ctx, session.username)
  use invoices <- middleware.require_user_invoices(ctx, session.username)
  continue(cart, invoices)
}

fn add_item_to_cart_count(
  request: Request,
  ctx: Context,
  id: String,
) -> Response {
  use cart, invoices <- do_add_item(request, ctx, id)
  pages.shopping_cart(cart.username, cart, invoices)
  |> wisp.html_response(200)
  |> wisp.set_header("Hx-Redirect", "/cart/view")
}

fn add_item_to_cart(request: Request, ctx: Context, id: String) -> Response {
  use cart, _ <- do_add_item(request, ctx, id)
  components.shopping_cart(cart:)
  |> element.to_document_string()
  |> wisp.html_response(200)
}

fn display_cart(ctx: Context, request: Request) -> Response {
  use session <- middleware.require_session(ctx, request)
  use cart <- middleware.get_cart(ctx, session.username)
  use invoices <- middleware.require_user_invoices(ctx, session.username)

  pages.shopping_cart(username: session.username, cart:, invoices:)
  |> wisp.html_response(200)
}
