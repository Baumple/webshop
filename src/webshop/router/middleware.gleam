import gleam/int
import gleam/list
import gleam/option
import wisp.{type Request, type Response}

import webshop/context.{type Context}
import webshop/data/db
import webshop/data/db/db_result
import webshop/data/db/query
import webshop/data/types
import webshop/error
import webshop/html/pages
import webshop/sessions

/// requires a cookie to be set
fn require_session_id_cookie(
  request: Request,
  continue: fn(String) -> Response,
) -> Response {
  case wisp.get_cookie(request, "SESSIONID", wisp.PlainText) {
    Error(Nil) ->
      wisp.ok()
      |> wisp.html_body(pages.login())
    Ok(session_id) -> continue(session_id)
  }
}

/// Requires a valid session cookie to be set. If it is not set or otherwise
/// invalid, redirect the user to the login page. 
///
/// If it is set, the session id is passed to the callback parameter.
pub fn require_session_id(
  ctx: Context,
  request: Request,
  continue: fn(String) -> Response,
) -> Response {
  use session_id <- require_session_id_cookie(request)
  case sessions.exists(ctx.sessions, session_id) {
    Ok(True) -> continue(session_id)
    Ok(False) -> wisp.html_response(pages.login(), 200)
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
  case wisp.get_cookie(request, "SESSIONID", wisp.PlainText) {
    Ok(session_id) ->
      case sessions.get(ctx.sessions, session_id) {
        Ok(session) -> continue(session)
        Error(err) -> error.log_ets_error(err)
      }
    Error(Nil) -> continue(option.None)
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

pub fn get_partial_items_query(
  ctx: Context,
  query: query.Query,
  offset offset: Int,
  limit limit: Int,
  continue continue: fn(List(types.PartialItem)) -> Response,
) {
  todo
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
