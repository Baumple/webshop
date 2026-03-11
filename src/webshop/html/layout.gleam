import webshop/html/component_states/header_state
import lustre/attribute.{attribute, class}
import lustre/element
import lustre/element/html.{text}

import webshop/html/components
import webshop/html/components/header

pub fn footer() -> element.Element(a) {
  html.footer([], [
    html.p([], [text("Made with 💖 by Linus")]),
    html.a(
      [
        attribute.target("blank"),
        attribute.href("https://github.com/baumple/webshop"),
        class("link"),
      ],
      [
        text("Source Code (Github)"),
      ],
    ),
    html.a([class("link"), attribute.href("/users/logout")], [text("Log out ➡️")]),
  ])
}

pub fn layout(
  body: List(element.Element(a)),
  title: String,
  subtitle: String,
  header_state: header_state.HeaderState,
) -> String {
  html.html([attribute("lang", "de")], [
    html.head([], [
      html.meta([attribute.charset("UTF-8")]),
      html.meta([
        attribute.content("width=device-width, initial-scale=1"),
        attribute.name("viewport"),
      ]),
      html.title([], title),
      html.link([
        attribute.rel("stylesheet"),
        attribute.href("/static/style.css"),
      ]),
      html.script(
        [
          attribute.src(
            "https://cdn.jsdelivr.net/npm/htmx.org@2.0.8/dist/htmx.min.js",
          ),
        ],
        "",
      ),
    ]),
    html.body([], [
      header.view(title, subtitle, header_state),
      components.separator(),
      html.main([class("crt")], body),
      components.separator(),
      footer(),
    ]),
  ])
  |> element.to_document_string
}
