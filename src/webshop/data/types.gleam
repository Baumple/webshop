import cake/insert
import gleam/dict
import gleam/dynamic/decode
import gleam/option

fn name_pair_decoder() -> decode.Decoder(#(String, String)) {
  use language <- decode.subfield(["language", "name"], decode.string)
  use name <- decode.field("name", decode.string)
  decode.success(#(language, name))
}

pub type Category {
  Category(
    /// The id of the item
    id: Int,
    /// The name of the item
    name: String,
    /// The names of the category in different languages #(language, name)
    names: dict.Dict(String, String),
    /// The pocket the item is stored in
    pocket: String,
  )
}

pub fn category_decoder() -> decode.Decoder(Category) {
  use id <- decode.field("id", decode.int)
  use name <- decode.field("name", decode.string)
  use names <- decode.field("names", decode.list(name_pair_decoder()))
  let names = dict.from_list(names)
  use pocket <- decode.subfield(["pocket", "name"], decode.string)
  decode.success(Category(id:, name:, names:, pocket:))
}

pub type EffectEntry {
  EffectEntry(effect: String, short_effect: String)
}

pub type Item {
  Item(
    id: Int,
    name: String,
    /// Price of the item
    cost: Int,
    /// Category the item belongs into
    category: String,
    /// The item's attributes
    attributes: List(String),
    /// The item's names in different languages
    names: dict.Dict(String, String),
    /// The item's effect descriptions in different languages
    effect_entries: dict.Dict(String, EffectEntry),
    /// The item's default sprite
    sprite: option.Option(String),
  )
}

fn decode_effect_entry() {
  use language <- decode.subfield(["language", "name"], decode.string)
  use effect <- decode.field("effect", decode.string)
  use short_effect <- decode.field("short_effect", decode.string)
  decode.success(#(language, EffectEntry(effect, short_effect)))
}

pub fn item_decoder() -> decode.Decoder(Item) {
  use id <- decode.field("id", decode.int)
  use name <- decode.field("name", decode.string)
  use cost <- decode.field("cost", decode.int)
  use category <- decode.subfield(["category", "name"], decode.string)
  use attributes <- decode.field(
    "attributes",
    decode.list({
      use name <- decode.field("name", decode.string)
      decode.success(name)
    }),
  )
  use names <- decode.field("names", decode.list(name_pair_decoder()))
  let names = dict.from_list(names)
  use effect_entries <- decode.field(
    "effect_entries",
    decode.list(decode_effect_entry()),
  )
  let effect_entries = dict.from_list(effect_entries)
  use sprite <- decode.subfield(
    ["sprites", "default"],
    decode.optional(decode.string),
  )
  decode.success(Item(
    id:,
    name:,
    cost:,
    category:,
    attributes:,
    names:,
    effect_entries:,
    sprite:,
  ))
}

pub type Customer {
  Customer(
    username: String,
    name: String,
    surname: String,
    street: String,
    house_number: Int,
    postal_code: Int,
    location: String,
    bin: Int,
    institution: String,
    password_hash: String,
  )
}

pub fn customer_to_insert_row(c: Customer) -> insert.InsertRow {
  let Customer(
    username:,
    name:,
    surname:,
    street:,
    house_number:,
    postal_code:,
    location:,
    bin:,
    institution:,
    password_hash:,
  ) = c
  insert.row([
    insert.string(username),
    insert.string(name),
    insert.string(surname),
    insert.string(street),
    insert.int(house_number),
    insert.int(postal_code),
    insert.string(location),
    insert.int(bin),
    insert.string(institution),
    insert.string(password_hash),
  ])
}
