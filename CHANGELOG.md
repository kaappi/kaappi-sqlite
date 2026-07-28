# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

### Fixed
- `sqlite-execute` now steps statements that produce no result columns
  (INSERT/UPDATE/DELETE/DDL) immediately, instead of deferring
  `sqlite3_step` until a fetch that never comes. Previously such writes
  through a cursor were silently lost and `sqlite-rowcount` reported
  stale counts left over from whatever statement last actually ran.
  `SELECT`-shaped statements are unaffected and still step lazily via
  `sqlite-fetchone`/`sqlite-fetchall`.
- `sqlite-convert-param` now accepts `'()` as a NULL bind parameter, in
  addition to `#f`.

## [0.1.0] - 2026-07-26

### Added
- SQLite client — `sqlite-open`/`sqlite-close`, DB-API-style cursors
  (`sqlite-cursor`, `sqlite-execute`, `sqlite-fetchone`/`sqlite-fetchall`,
  `sqlite-description`, `sqlite-rowcount`), `sqlite-exec`/`sqlite-query`,
  `sqlite-last-insert-id`, and
  `call-with-sqlite`/`call-with-sqlite-transaction`
- libsqlite3-backed C FFI built via `make`
- CI workflow for automated testing
