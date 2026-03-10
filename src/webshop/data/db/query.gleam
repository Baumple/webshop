import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import wisp.{type Request}

pub type Query {
  Query(
    text: Option(String),
    category: Option(String),
    attribute: Option(String),
    index: option.Option(Int),
  )
}

pub fn from_request(request: Request) -> Query {
  let to_option = fn(x) {
    case x {
      Ok("") | Error(Nil) -> None
      Ok(value) -> Some(value)
    }
  }
  let query = wisp.get_query(request)

  let index = case list.key_find(query, "index") {
    Ok(index) ->
      case int.parse(index) {
        Ok(index) -> Some(index)
        Error(Nil) -> None
      }
    Error(Nil) -> None
  }
  let text =
    list.key_find(query, "searchterm")
    |> to_option
  let category =
    list.key_find(query, "category")
    |> to_option

  let attribute = list.key_find(query, "attribute") |> to_option()

  Query(text:, category:, attribute:, index:)
}

pub fn empty() -> Query {
  Query(text: None, attribute: None, category: None, index: None)
}

pub fn to_string(q: Query) -> String {
  let fields = []
  // let fields = case q.index {
  //   Some(index) -> ["index=" <> int.to_string(index), ..fields]
  //   None -> fields
  // }
  let fields = case q.attribute {
    Some(attribute) -> ["attribute=" <> attribute, ..fields]
    None -> fields
  }
  let fields = case q.category {
    Some(category) -> ["category=" <> category, ..fields]
    None -> fields
  }
  let fields = case q.text {
    Some(text) -> ["searchterm=" <> text, ..fields]
    None -> fields
  }
  "?" <> string.join(fields, "&")
}

pub fn get_index(q: Query) -> Int {
  case q.index {
    Some(index) -> index
    None -> 0
  }
}
