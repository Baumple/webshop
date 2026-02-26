import lustre/attribute.{class}
import lustre/element
import lustre/element/html

pub fn separator() -> element.Element(a) {
  html.hr([class("separator")])
}
