import lustre/element
import lustre/element/html
import webshop/context
import wisp

pub fn other_button() -> String {
  html.button([], [html.text("Click me")])
  |> element.to_document_string
}

pub fn handle(
  path: List(String),
  _ctx: context.Context,
  _request: wisp.Request,
) -> wisp.Response {
  case path {
    ["other_button"] -> wisp.html_response(other_button(), 200)
    _ -> wisp.not_found()
  }
}
