import lustre/attribute.{attribute}
import lustre/element
import lustre/element/html

pub fn layout(body: List(element.Element(a)), title: String) -> String {
  html.html([attribute("lang", "de")], [
    html.head([], [
      html.meta([attribute.charset("UTF-8")]),
      html.meta([
        attribute.content("width=device-width, initial-scale=1"),
        attribute.name("viewport"),
      ]),
      html.title([], title),
      html.link([attribute.rel("stylesheet"), attribute.href("css/style.css")]),
      html.script(
        [
          attribute.src(
            "https://cdn.jsdelivr.net/npm/htmx.org@2.0.8/dist/htmx.min.js",
          ),
        ],
        "",
      ),
    ]),
    html.body([], body),
  ])
  |> element.to_document_string
}
