// fn handle(
//   state: FetchState(a),
//   msg: FetchMessage(a),
// ) -> actor.Next(FetchState(a), FetchMessage(a)) {
//   case msg {
//     Success(entries) -> {
//       let new_process_count = state.process_count - 1
//       log_process(state, new_process_count)
//
//       case state.insert_resource(entries) {
//         Ok(Nil) ->
//           case new_process_count == 0 {
//             False ->
//               actor.continue(
//                 FetchState(..state, process_count: new_process_count),
//               )
//             True -> {
//               actor.send(state.subject, Ok(Nil))
//               actor.stop()
//             }
//           }
//         Error(err) -> {
//           wisp.log_error("Failed to insert fetched resource into database.")
//           actor.send(state.subject, Error(error.DBError(err)))
//           actor.stop_abnormal(
//             "Failed to insert fetched resource into database.",
//           )
//         }
//       }
//     }
//     Failure(err) -> {
//       actor.send(state.subject, Error(err))
//       actor.stop_abnormal("An error occurred while fetching data.")
//     }
//   }
// }
//
// /// Spawns multiple processes which fetch the data in parallel batches
// fn parallel_fetch_resources(
//   entries: List(ResourceEntry),
//   insert_resource: fn(List(a)) -> Result(Nil, sqlight.Error),
//   decoder: decode.Decoder(a),
// ) -> Result(Nil, WebshopInitError) {
//   let entry_count = list.length(entries)
//   let process_count = 5
//   let entries_per_process = entry_count / process_count
//
//   wisp.log_info(
//     "Fetching "
//     <> int.to_string(entry_count)
//     <> " entries on "
//     <> int.to_string(process_count)
//     <> " processes.",
//   )
//
//   let subject = process.new_subject()
//   let assert Ok(started) =
//     actor.new(FetchState(process_count:, insert_resource:, subject:))
//     |> actor.on_message(handle)
//     |> actor.start()
//   let accumulator = started.data
//
//   let chunked_entries = list.sized_chunk(entries, entries_per_process)
//   list.map(chunked_entries, fn(entries) {
//     process.spawn(fn() {
//       let result =
//         list.map(entries, fetch_resource(decoder, _))
//         |> result.all()
//       case result {
//         Ok(res) -> actor.send(accumulator, Success(res))
//         Error(err) -> actor.send(accumulator, Failure(err))
//       }
//     })
//   })
//
//   // wait until all fetching processes concluded or there was an error
//   process.receive_forever(subject)
// }
//
// type FetchMessage(a) {
//   Success(List(a))
//   Failure(WebshopInitError)
// }
//
// type FetchState(a) {
//   FetchState(
//     process_count: Int,
//     insert_resource: fn(List(a)) -> Result(Nil, sqlight.Error),
//     subject: process.Subject(Result(Nil, WebshopInitError)),
//   )
// }
//
