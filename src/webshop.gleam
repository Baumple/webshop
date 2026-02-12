import webshop/context
import gleam/erlang/process

import mist
import wisp
import wisp/wisp_mist

import webshop/router

pub fn main() -> Nil {
  wisp.configure_logger()

  let assert Ok(context) = context.new_with_hot_reload()
  let assert Ok(_) =
    wisp_mist.handler(router.handler(context, _), wisp.random_string(64))
    |> mist.new()
    |> mist.port(8000)
    |> mist.start()

  process.sleep_forever()
}
