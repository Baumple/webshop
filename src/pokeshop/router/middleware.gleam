import dream_ets/table
import gleam/int
import gleam/list
import gleam/option
import wisp.{type Request, type Response}

import pokeshop/context.{type Context}
import pokeshop/data/db
import pokeshop/data/db/db_result
import pokeshop/data/db/query
import pokeshop/data/types
import pokeshop/error
import pokeshop/sessions

fn get_session_or_none(
  ctx: Context,
  request: Request,
) -> Result(option.Option(sessions.Session), table.EtsError) {
  case wisp.get_cookie(request, "SESSIONID", wisp.PlainText) {
    Ok(session_id) ->
      case sessions.get(ctx.sessions, session_id) {
        Ok(maybe_session) -> Ok(maybe_session)
        Error(err) -> Error(err)
      }
    Error(Nil) -> Ok(option.None)
  }
}

/// Requires a user to be logged in, otherwise redirects them to login.
pub fn require_session(
  ctx: Context,
  request: Request,
  continue: fn(sessions.Session) -> Response,
) -> Response {
  let session = get_session_or_none(ctx, request)
  case session {
    Ok(option.Some(session)) -> continue(session)
    Ok(option.None) ->
      wisp.response(200)
      |> wisp.set_header("Hx-Redirect", "/login")
    Error(err) -> error.log_ets_error(err)
  }
}

/// Gets the session if it exists, otherwise passes `option.None` to the given
/// callback
pub fn get_session_if_exists(
  ctx: Context,
  request: Request,
  continue,
) -> Response {
  case get_session_or_none(ctx, request) {
    Ok(session) -> continue(session)
    Error(err) -> error.log_ets_error(err)
  }
}

pub fn get_partial_items(
  ctx: Context,
  query: query.Query,
  offset offset: Int,
  limit limit: Int,
  continue continue: fn(List(types.PartialItem)) -> Response,
) -> Response {
  case db.get_items(ctx.db, query, offset, limit) {
    Ok(items) -> continue(items)
    Error(err) -> error.log_sql_error(err)
  }
}

pub fn require_item(ctx: Context, id: Int, continue) -> Response {
  case db.get_item_by_id(ctx.db, id) {
    db_result.Success(item) -> continue(item)
    db_result.NotFound -> wisp.not_found()
    db_result.FailedQuery(err) -> error.log_sql_error(err)
  }
}

pub fn get_pagination_index(request: Request, continue) -> Response {
  case list.key_find(wisp.get_query(request), "index") {
    Ok(index) ->
      case int.parse(index) {
        Ok(index) -> continue(index)
        Error(Nil) -> wisp.bad_request("Parameter `index` is invalid")
      }
    Error(Nil) -> continue(0)
  }
}

pub fn get_item_count(ctx: Context, query: query.Query, continue) -> Response {
  case db.get_item_count(ctx.db, query) {
    Ok(count) -> continue(count)
    Error(err) -> error.log_sql_error(err)
  }
}

pub fn get_categories(
  ctx: Context,
  continue: fn(List(types.PartialCategory)) -> Response,
) -> Response {
  case db.get_categories(ctx.db) {
    Ok(categories) -> continue(categories)
    Error(err) -> error.log_sql_error(err)
  }
}

pub fn get_cart(ctx: Context, username: String, continue) -> Response {
  case db.get_user_cart(ctx.db, username) {
    Ok(cart) -> continue(cart)
    Error(err) -> error.log_sql_error(err)
  }
}

pub fn require_int_id(id: String, continue) -> Response {
  case int.parse(id) {
    Ok(id) -> continue(id)
    Error(Nil) -> wisp.bad_request("param `id` invalid")
  }
}

pub fn require_add_item_to_cart(
  ctx: Context,
  username: String,
  item_id: Int,
  continue,
) -> Response {
  case db.add_item_to_cart(ctx.db, username, item_id) {
    Ok(Nil) -> continue()
    Error(err) -> error.log_sql_error(err)
  }
}

pub fn require_remove_item_from_cart(
  ctx: Context,
  username: String,
  item_id: Int,
  continue,
) -> Response {
  case db.remove_item_from_cart(ctx.db, username, item_id) {
    Ok(Nil) -> continue()
    Error(err) -> error.log_sql_error(err)
  }
}

pub fn require_delete_item_from_cart(
  ctx: Context,
  username: String,
  item_id: Int,
  continue,
) {
  case db.delete_item_from_cart(ctx.db, username, item_id) {
    Ok(Nil) -> continue()
    Error(err) -> error.log_sql_error(err)
  }
}

pub fn require_clear_cart(ctx: Context, username: String, continue) {
  case db.clear_item_cart(ctx.db, username) {
    Ok(Nil) -> continue()
    Error(err) -> error.log_sql_error(err)
  }
}

pub fn require_user_invoices(ctx: Context, username: String, continue) {
  case db.get_user_invoices(ctx.db, username) {
    Ok(invoices) -> continue(invoices)
    Error(err) -> error.log_sql_error(err)
  }
}
