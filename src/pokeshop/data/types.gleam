import cake/insert
import gleam/dict
import gleam/dynamic/decode.{type Decoder}
import gleam/list
import gleam/option
import gleam/time/timestamp

fn name_pair_decoder() -> Decoder(#(String, String)) {
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

pub type PartialCategory {
  PartialCategory(id_name: String, name: String)
}

pub fn category_decoder() -> Decoder(Category) {
  use id <- decode.field("id", decode.int)
  use name <- decode.field("name", decode.string)
  use names <- decode.field("names", decode.list(name_pair_decoder()))
  let names = dict.from_list(names)
  use pocket <- decode.subfield(["pocket", "name"], decode.string)
  decode.success(Category(id:, name:, names:, pocket:))
}

pub fn partial_category_decoder() -> Decoder(PartialCategory) {
  use id_name <- decode.field(0, decode.string)
  use name <- decode.field(1, decode.string)
  decode.success(PartialCategory(id_name:, name:))
}

pub type EffectEntry {
  EffectEntry(effect: String, short_effect: String)
}

pub type PartialItem {
  PartialItem(
    id: Int,
    name: String,
    sprite: String,
    category: String,
    cost: Int,
  )
}

pub type Item {
  Item(
    id: Int,
    name: String,
    /// Price of the item
    cost: Int,
    // TODO: use category record
    /// Category th elongs into
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

pub fn get_sprite_or_default_sprite(item: Item) -> String {
  option.unwrap(
    item.sprite,
    or: "https://github.com/PokeAPI/sprites/blob/master/sprites/items/data-card-01.png?raw=true",
  )
}

fn decode_effect_entry() {
  use language <- decode.subfield(["language", "name"], decode.string)
  use effect <- decode.field("effect", decode.string)
  use short_effect <- decode.field("short_effect", decode.string)
  decode.success(#(language, EffectEntry(effect, short_effect)))
}

pub fn item_decoder_json() -> Decoder(Item) {
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
  use sprites <- decode.field(
    "sprites",
    decode.dict(decode.string, decode.string),
  )
  case dict.to_list(sprites) {
    [#("default", _)] -> Nil
    _ -> {
      panic
    }
  }
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

pub type Cart {
  Cart(username: String, items: List(#(PartialItem, Int)))
}

pub fn get_cart_item_count(cart: Cart) -> Int {
  list.fold(cart.items, 0, fn(acc, item) {
    let #(_, count) = item
    acc + count
  })
}

pub type Invoice {
  Invoice(
    id: Int,
    username: String,
    date: timestamp.Timestamp,
    entries: List(InvoiceEntry),
  )
}

pub type InvoiceEntry {
  InvoiceEntry(
    item_id: Int,
    item_name: String,
    price_per_item: Int,
    amount: Int,
  )
}

