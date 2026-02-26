import lustre/attribute.{class}
import lustre/element
import lustre/element/html.{text}

pub fn separator() -> element.Element(a) {
  html.hr([class("separator")])
}

pub fn section_header(t: String) -> element.Element(a) {
  html.h2([], [text(t)])
}
