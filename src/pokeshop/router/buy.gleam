import gleam/list
import gleam/time/timestamp
import pokeshop/context.{type Context}
import pokeshop/data/db
import pokeshop/data/types
import pokeshop/error
import pokeshop/router/middleware
import wisp.{type Response}

fn require_insert_invoice(
  ctx: Context,
  username: String,
  cart: types.Cart,
  continue,
) -> Response {
  let entries =
    list.fold(cart.items, [], fn(acc, item) {
      let #(partial_item, count) = item
      [
        types.InvoiceEntry(
          item_id: partial_item.id,
          item_name: partial_item.name,
          price_per_item: partial_item.cost,
          amount: count,
        ),
        ..acc
      ]
    })

  let res =
    db.insert_invoice(
      ctx.db,
      types.Invoice(id: -1, username: username, date: timestamp.system_time(), entries:),
    )
  case res {
    Ok(Nil) -> continue()
    Error(err) -> error.log_sql_error(err)
  }
}

pub fn handle(request: wisp.Request, ctx: Context) -> Response {
  use session <- middleware.require_session(ctx, request)
  use cart <- middleware.get_cart(ctx, session.username)

  use <- require_insert_invoice(ctx, session.username, cart)
  use <- middleware.require_clear_cart(ctx, session.username)

  wisp.ok()
  |> wisp.set_header("Hx-Redirect", "/cart/view")
}
