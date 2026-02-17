import lustre/attribute.{attribute}
import lustre/element/html
import webshop/html/layout

pub fn index() -> String {
  [
    html.h1([], [html.text("Hello")]),
    html.button(
      [attribute("hx-get", "/hx/other_button"), attribute.type_("button")],
      [],
    ),
  ]
  |> layout.layout("Webshop")
}

pub fn login() -> String {
  [
    html.h1([], [html.text("Hello - Please log in")]),
    html.form([attribute.action("/login"), attribute.method("post")], [
      html.input([
        attribute.placeholder("Nutzername"),
        attribute.value(""),
        attribute.name("username"),
        attribute.type_("text"),
      ]),
      html.input([
        attribute.placeholder("Passwort"),
        attribute.value(""),
        attribute.name("password"),
        attribute.type_("password"),
      ]),
      html.button([attribute.type_("submit")], [html.text("Jap")]),
    ]),
    html.button(
      [attribute("hx-get", "/hx/other_button"), attribute.type_("button")],
      [],
    ),
  ]
  |> layout.layout("Webshop - Login")
}

pub fn invalid_login() -> String {
  [html.p([], [html.text("Nutzername oder Passwort falsch.")])]
  |> layout.layout("Webshop - Invalid login")
}
