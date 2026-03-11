import lustre/attribute.{attribute}
import lustre/element
import lustre/element/svg

pub fn shopping_cart() -> element.Element(a) {
  svg.svg(
    [
      attribute("xmlns", "http://www.w3.org/2000/svg"),
      attribute("fill", "none"),
      attribute("viewBox", "0 0 24 24"),
    ],
    [
      svg.g(
        [attribute("stroke-width", "0"), attribute.id("SVGRepo_bgCarrier")],
        [],
      ),
      svg.g(
        [
          attribute("stroke-linejoin", "round"),
          attribute("stroke-linecap", "round"),
          attribute.id("SVGRepo_tracerCarrier"),
        ],
        [],
      ),
      svg.g([attribute.id("SVGRepo_iconCarrier")], [
        svg.path([
          attribute("fill", "#4AF262"),
          attribute(
            "d",
            "M2 1C1.44772 1 1 1.44772 1 2C1 2.55228 1.44772 3 2 3H3.21922L6.78345 17.2569C5.73276 17.7236 5 18.7762 5 20C5 21.6569 6.34315 23 8 23C9.65685 23 11 21.6569 11 20C11 19.6494 10.9398 19.3128 10.8293 19H15.1707C15.0602 19.3128 15 19.6494 15 20C15 21.6569 16.3431 23 18 23C19.6569 23 21 21.6569 21 20C21 18.3431 19.6569 17 18 17H8.78078L8.28078 15H18C20.0642 15 21.3019 13.6959 21.9887 12.2559C22.6599 10.8487 22.8935 9.16692 22.975 7.94368C23.0884 6.24014 21.6803 5 20.1211 5H5.78078L5.15951 2.51493C4.93692 1.62459 4.13696 1 3.21922 1H2ZM18 13H7.78078L6.28078 7H20.1211C20.6742 7 21.0063 7.40675 20.9794 7.81078C20.9034 8.9522 20.6906 10.3318 20.1836 11.3949C19.6922 12.4251 19.0201 13 18 13ZM18 20.9938C17.4511 20.9938 17.0062 20.5489 17.0062 20C17.0062 19.4511 17.4511 19.0062 18 19.0062C18.5489 19.0062 18.9938 19.4511 18.9938 20C18.9938 20.5489 18.5489 20.9938 18 20.9938ZM7.00617 20C7.00617 20.5489 7.45112 20.9938 8 20.9938C8.54888 20.9938 8.99383 20.5489 8.99383 20C8.99383 19.4511 8.54888 19.0062 8 19.0062C7.45112 19.0062 7.00617 19.4511 7.00617 20Z",
          ),
          attribute("clip-rule", "evenodd"),
          attribute("fill-rule", "evenodd"),
        ]),
      ]),
    ],
  )
}

pub fn arrow_right() -> element.Element(a) {
  svg.svg(
    [
      attribute("xmlns", "http://www.w3.org/2000/svg"),
      attribute("fill", "none"),
      attribute("viewBox", "0 0 24 24"),
    ],
    [
      svg.g(
        [attribute("stroke-width", "0"), attribute.id("SVGRepo_bgCarrier")],
        [],
      ),
      svg.g(
        [
          attribute("stroke-linejoin", "round"),
          attribute("stroke-linecap", "round"),
          attribute.id("SVGRepo_tracerCarrier"),
        ],
        [],
      ),
      svg.g([attribute.id("SVGRepo_iconCarrier")], [
        svg.path([
          attribute("data-darkreader-inline-stroke", ""),
          attribute(
            "style",
            "--darkreader-inline-stroke: var(--darkreader-text-4af262, #51f268);",
          ),
          attribute("stroke-linejoin", "round"),
          attribute("stroke-linecap", "round"),
          attribute("stroke-width", "2"),
          attribute("stroke", "#4AF262"),
          attribute("d", "M6 12H18M18 12L13 7M18 12L13 17"),
        ]),
      ]),
    ],
  )
}

pub fn arrow_left() -> element.Element(a) {
  svg.svg(
    [
      attribute("transform", "rotate(180)"),
      attribute("xmlns", "http://www.w3.org/2000/svg"),
      attribute("fill", "none"),
      attribute("viewBox", "0 0 24 24"),
    ],
    [
      svg.g(
        [attribute("stroke-width", "0"), attribute.id("SVGRepo_bgCarrier")],
        [],
      ),
      svg.g(
        [
          attribute("stroke-linejoin", "round"),
          attribute("stroke-linecap", "round"),
          attribute.id("SVGRepo_tracerCarrier"),
        ],
        [],
      ),
      svg.g([attribute.id("SVGRepo_iconCarrier")], [
        svg.path([
          attribute("data-darkreader-inline-stroke", ""),
          attribute(
            "style",
            "--darkreader-inline-stroke: var(--darkreader-text-4af262, #51f268);",
          ),
          attribute("stroke-linejoin", "round"),
          attribute("stroke-linecap", "round"),
          attribute("stroke-width", "2"),
          attribute("stroke", "#4AF262"),
          attribute("d", "M6 12H18M18 12L13 7M18 12L13 17"),
        ]),
      ]),
    ],
  )
}

pub fn cart() -> element.Element(a) {
  svg.svg(
    [
      attribute("data-darkreader-inline-fill", ""),
      attribute(
        "style",
        "--darkreader-inline-fill: var(--darkreader-background-4af262, #0b9c3f);",
      ),
      attribute.id("memory-cart"),
      attribute("xmlns", "http://www.w3.org/2000/svg"),
      attribute("viewBox", "0 0 22 22"),
      attribute("fill", "#4AF262"),
    ],
    [
      svg.g(
        [attribute("stroke-width", "0"), attribute.id("SVGRepo_bgCarrier")],
        [],
      ),
      svg.g(
        [
          attribute("stroke-linejoin", "round"),
          attribute("stroke-linecap", "round"),
          attribute.id("SVGRepo_tracerCarrier"),
        ],
        [],
      ),
      svg.g([attribute.id("SVGRepo_iconCarrier")], [
        svg.path([
          attribute(
            "d",
            "M19 14V16H6V15H5V11H4V8H3V3H1V1H5V4H21V8H20V11H19V12H7V14H19M5 7H6V10H18V7H19V6H5V7M7 17H9V18H10V20H9V21H7V20H6V18H7V17M15 17H17V18H18V20H17V21H15V20H14V18H15V17Z",
          ),
        ]),
      ]),
    ],
  )
}

pub fn login() -> element.Element(a) {
  svg.svg(
    [
      attribute("data-darkreader-inline-fill", ""),
      attribute(
        "style",
        "--darkreader-inline-fill: var(--darkreader-background-4af262, #0b9c3f);",
      ),
      attribute("xmlns", "http://www.w3.org/2000/svg"),
      attribute("viewBox", "0 0 24 24"),
      attribute("fill", "#4AF262"),
    ],
    [
      svg.g(
        [attribute("stroke-width", "0"), attribute.id("SVGRepo_bgCarrier")],
        [],
      ),
      svg.g(
        [
          attribute("stroke-linejoin", "round"),
          attribute("stroke-linecap", "round"),
          attribute.id("SVGRepo_tracerCarrier"),
        ],
        [],
      ),
      svg.g([attribute.id("SVGRepo_iconCarrier")], [
        svg.path([
          attribute(
            "d",
            "M20,21V3H13a1,1,0,0,1,0-2h8a1,1,0,0,1,1,1V22a1,1,0,0,1-1,1H13a1,1,0,0,1,0-2ZM2,12a1,1,0,0,0,1,1H14.586l-2.293,2.293a1,1,0,1,0,1.414,1.414l4-4a1,1,0,0,0,0-1.414l-4-4a1,1,0,1,0-1.414,1.414L14.586,11H3A1,1,0,0,0,2,12Z",
          ),
        ]),
      ]),
    ],
  )
}
