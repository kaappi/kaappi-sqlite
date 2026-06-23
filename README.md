# kaappi-sqlite

SQLite client library for [Kaappi Scheme](https://github.com/kaappi/kaappi).

## Install

```bash
thottam install kaappi-sqlite
```

Requires SQLite3 development libraries:
- macOS: included with the system
- Linux: `sudo apt install libsqlite3-dev`

## Quick start

```scheme
(import (kaappi sqlite))

(call-with-sqlite ":memory:"
  (lambda (db)
    (sqlite-exec db "CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, age INTEGER)")
    (sqlite-exec db "INSERT INTO users (name, age) VALUES (?, ?)" "Alice" 30)
    (sqlite-exec db "INSERT INTO users (name, age) VALUES (?, ?)" "Bob" 25)

    (for-each
      (lambda (row)
        (display (vector-ref row 0))
        (display " is ")
        (display (vector-ref row 1))
        (display " years old\n"))
      (sqlite-query db "SELECT name, age FROM users ORDER BY name"))))
```

## API

### Connection

```scheme
(sqlite-open path)              ; open database (":memory:" for in-memory)
(sqlite-close conn)             ; close connection
(sqlite-open? conn)             ; check if connection is open
(sqlite-error-message conn)     ; last error message
```

### Convenience (recommended)

```scheme
(sqlite-exec conn sql params...)    ; execute non-query, returns change count
(sqlite-query conn sql params...)   ; execute query, returns list of row vectors
(sqlite-last-insert-id conn)        ; last inserted rowid
```

### Cursor (for streaming large results)

```scheme
(sqlite-cursor conn)                    ; create cursor
(sqlite-execute cursor sql params...)   ; prepare and bind
(sqlite-fetchone cursor)                ; next row as vector, or #f
(sqlite-fetchall cursor)                ; remaining rows as list
(sqlite-description cursor)             ; column names
(sqlite-rowcount cursor)                ; changes count
(sqlite-cursor-close cursor)            ; finalize statement
```

### Resource management

```scheme
(call-with-sqlite path-or-conn proc)           ; auto-close on exit
(call-with-sqlite-transaction conn proc)       ; BEGIN/COMMIT/ROLLBACK
```

### Parameters

Parameters use `?` placeholders. Types are preserved:

```scheme
(sqlite-exec db "INSERT INTO t VALUES (?, ?, ?)" 42 3.14 "hello")
(sqlite-exec db "INSERT INTO t VALUES (?, ?)" #f #t)  ; #f=NULL, #t=1
```

## Type mapping

| SQLite type | Scheme type |
|------------|-------------|
| INTEGER | exact integer |
| REAL | inexact number |
| TEXT | string |
| NULL | #f |
| BLOB | string (raw bytes) |

## License

MIT
