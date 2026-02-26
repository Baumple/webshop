import dream_ets/encoders
import dream_ets/operations
import dream_ets/table.{type Table}
import gleam/dynamic
import gleam/dynamic/decode
import gleam/json
import gleam/option
import gleam/result
import gleam/string
import gleam/time/duration
import gleam/time/timestamp
import glecuid/cuid2
import webshop/error

import dream_ets/config

pub type SessionsTable =
  Table(String, Session)

pub type SessionId =
  String

pub type Session {
  Session(
    id: String,
    username: String,
    created_at: timestamp.Timestamp,
    expires_at: timestamp.Timestamp,
  )
}

fn encode_timestamp(ts: timestamp.Timestamp) -> json.Json {
  let #(seconds, nanos) = timestamp.to_unix_seconds_and_nanoseconds(ts)
  json.object([#("seconds", json.int(seconds)), #("nanos", json.int(nanos))])
}

fn session_to_json(session: Session) -> json.Json {
  let Session(id:, username:, created_at:, expires_at:) = session
  json.object([
    #("id", json.string(id)),
    #("username", json.string(username)),
    #("created_at", encode_timestamp(created_at)),
    #("expires_at", encode_timestamp(expires_at)),
  ])
}

fn encode_session(s: Session) -> dynamic.Dynamic {
  session_to_json(s)
  |> json.to_string
  |> encoders.string_encoder
}

fn decode_timestamp() -> decode.Decoder(timestamp.Timestamp) {
  use seconds <- decode.field("seconds", decode.int)
  use nanos <- decode.field("nanos", decode.int)
  decode.success(timestamp.from_unix_seconds_and_nanoseconds(seconds, nanos))
}

fn session_decoder() -> decode.Decoder(Session) {
  use str <- decode.then(decode.string)
  let decoder = {
    let timestamp_decoder = decode_timestamp()
    use id <- decode.field("id", decode.string)
    use username <- decode.field("username", decode.string)
    use created_at <- decode.field("created_at", timestamp_decoder)
    use expires_at <- decode.field("expires_at", timestamp_decoder)
    decode.success(Session(id:, username:, created_at:, expires_at:))
  }
  let assert Ok(session) = json.parse(str, decoder)
  decode.success(session)
}

pub fn new() -> Result(SessionsTable, error.WebshopInitError) {
  config.new("user_sessions")
  |> config.key_string()
  |> config.value(encode_session, session_decoder())
  |> config.create
  |> result.map_error(error.SessionError)
}

fn new_session(username: String) -> Session {
  let id: SessionId = cuid2.create_id()
  let created_at = timestamp.system_time()
  let expires_at = timestamp.add(created_at, duration.hours(24))
  Session(id:, username:, created_at:, expires_at:)
}

pub fn create_session(st: SessionsTable, username username: String) -> SessionId {
  let s = new_session(username)
  case operations.insert_new(st, s.id, s) {
    Ok(True) -> s.id
    Ok(False) -> create_session(st, username)
    Error(e) -> panic as { "Could not insert into ets: " <> string.inspect(e) }
  }
}

pub fn exists(
  st: SessionsTable,
  session_id: String,
) -> Result(Bool, table.EtsError) {
  use session <- result.map(operations.get(st, session_id))
  case session {
    option.Some(_) -> True
    option.None -> False
  }
}

pub fn get_session(
  table: SessionsTable,
  key: String,
) -> Result(option.Option(Session), table.EtsError) {
  operations.get(table, key)
}

pub fn clear(sessions: SessionsTable) {
  operations.delete_all_objects(sessions)
}
