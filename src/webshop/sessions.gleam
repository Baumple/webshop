import dream_ets/encoders
import dream_ets/operations
import dream_ets/table.{type Table}
import gleam/dynamic
import gleam/dynamic/decode
import gleam/json
import gleam/option
import gleam/order
import gleam/result
import gleam/string
import gleam/time/duration
import gleam/time/timestamp as ts
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
    created_at: ts.Timestamp,
    expires_at: ts.Timestamp,
  )
}

fn encode_ts(ts: ts.Timestamp) -> json.Json {
  let #(seconds, nanos) = ts.to_unix_seconds_and_nanoseconds(ts)
  json.object([#("seconds", json.int(seconds)), #("nanos", json.int(nanos))])
}

fn session_to_json(session: Session) -> json.Json {
  let Session(id:, username:, created_at:, expires_at:) = session
  json.object([
    #("id", json.string(id)),
    #("username", json.string(username)),
    #("created_at", encode_ts(created_at)),
    #("expires_at", encode_ts(expires_at)),
  ])
}

fn encode_session(s: Session) -> dynamic.Dynamic {
  session_to_json(s)
  |> json.to_string
  |> encoders.string_encoder
}

fn decode_ts() -> decode.Decoder(ts.Timestamp) {
  use seconds <- decode.field("seconds", decode.int)
  use nanos <- decode.field("nanos", decode.int)
  decode.success(ts.from_unix_seconds_and_nanoseconds(seconds, nanos))
}

fn session_decoder() -> decode.Decoder(Session) {
  use str <- decode.then(decode.string)
  let decoder = {
    let ts_decoder = decode_ts()
    use id <- decode.field("id", decode.string)
    use username <- decode.field("username", decode.string)
    use created_at <- decode.field("created_at", ts_decoder)
    use expires_at <- decode.field("expires_at", ts_decoder)
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
  let created_at = ts.system_time()
  let expires_at = ts.add(created_at, duration.hours(24))
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

/// check whether a session exists
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

/// get a session if it exists and has not yet expired, otherwise return
/// `option.None`
pub fn get(
  st: SessionsTable,
  key: String,
) -> Result(option.Option(Session), table.EtsError) {
  use s <- result.try(operations.get(st, key))
  case s {
    option.Some(s) -> delete_if_expired(st, s)
    option.None -> Ok(option.None)
  }
}

/// deletes the session from the table if it has expired.
/// If it has returns `Ok(option.None)`, if it has not `Ok(option.Some(Session)))`
fn delete_if_expired(
  st: SessionsTable,
  s: Session,
) -> Result(option.Option(Session), table.EtsError) {
  case ts.compare(ts.system_time(), s.expires_at) {
    order.Lt -> Ok(option.Some(s))
    _ -> remove(st, s.id) |> result.replace(option.None)
  }
}

/// remove a session
pub fn remove(
  table: SessionsTable,
  id: SessionId,
) -> Result(Nil, table.EtsError) {
  operations.delete(table, id)
}

/// clear all sessions
pub fn clear(sessions: SessionsTable) {
  operations.delete_all_objects(sessions)
}
