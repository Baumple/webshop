import wisp
import gleam/result
import sqlight.{type Connection}

import webshop/data/poke_api
import webshop/error.{type WebshopInitError}

pub fn update_items(db: Connection, continue) -> Result(Connection, WebshopInitError) {
  use items <- result.try(poke_api.fetch_items())
  wisp.log_info("Updated items.")
  continue()
}
