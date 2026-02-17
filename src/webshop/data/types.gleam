import gleam/dynamic/decode

pub type Category {
  Category(
    id: Int,
    name: String,
    names: List(#(String, String)),
    pocket: String,
  )
}

pub fn category_decoder() -> decode.Decoder(Category) {
  use id <- decode.field("id", decode.int)
  use name <- decode.field("name", decode.string)
  use names <- decode.field("names", decode.list({
    use a <- decode.field(0, decode.string)
    use b <- decode.field(1, decode.string)

    decode.success(#(a, b))
  }))
  use pocket <- decode.field("pocket", decode.string)
  decode.success(Category(id:, name:, names:, pocket:))
}
