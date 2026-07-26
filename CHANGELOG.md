# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

## [0.1.0] - 2026-07-26

### Added
- SQLite client — `sqlite-open`/`sqlite-close`, DB-API-style cursors
  (`sqlite-cursor`, `sqlite-execute`, `sqlite-fetchone`/`sqlite-fetchall`,
  `sqlite-description`, `sqlite-rowcount`), `sqlite-exec`/`sqlite-query`,
  `sqlite-last-insert-id`, and
  `call-with-sqlite`/`call-with-sqlite-transaction`
- libsqlite3-backed C FFI built via `make`
- CI workflow for automated testing
