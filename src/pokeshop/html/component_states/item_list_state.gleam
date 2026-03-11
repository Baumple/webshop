import pokeshop/data/db/query
import pokeshop/data/types.{type PartialItem, type PartialCategory}

pub type ItemListState {
  ItemListState(
    items: List(PartialItem),
    item_count: Int,
    pagination_index: Int,
    current_query: query.Query,
    categories: List(PartialCategory),
  )
}
