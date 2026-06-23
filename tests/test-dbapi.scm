(import (scheme base) (scheme write) (scheme file)
        (kaappi sqlite))

(define pass 0)
(define fail 0)

(define-syntax check
  (syntax-rules (=>)
    ((_ expr => expected)
     (let ((result expr) (exp expected))
       (if (equal? result exp)
           (set! pass (+ pass 1))
           (begin
             (set! fail (+ fail 1))
             (display "FAIL: ") (write 'expr)
             (display " => ") (write result)
             (display ", expected ") (write exp)
             (newline)))))))

(define-syntax check-true
  (syntax-rules ()
    ((_ expr)
     (if expr
         (set! pass (+ pass 1))
         (begin
           (set! fail (+ fail 1))
           (display "FAIL: ") (write 'expr) (display " is false\n"))))))

;; Use in-memory database — no cleanup needed
(define db (sqlite-open ":memory:"))
(check-true (sqlite-open? db))

;; --- CREATE TABLE ---
(display "CREATE TABLE\n")
(sqlite-exec db "CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, age INTEGER, score REAL)")

;; --- INSERT ---
(display "INSERT\n")
(sqlite-exec db "INSERT INTO users (name, age, score) VALUES (?, ?, ?)" "Alice" 30 9.5)
(check (sqlite-last-insert-id db) => 1)

(sqlite-exec db "INSERT INTO users (name, age, score) VALUES (?, ?, ?)" "Bob" 25 8.0)
(check (sqlite-last-insert-id db) => 2)

(sqlite-exec db "INSERT INTO users (name, age, score) VALUES (?, ?, ?)" "Charlie" 35 7.5)

;; --- SELECT with fetchall ---
(display "SELECT fetchall\n")
(let ((rows (sqlite-query db "SELECT name, age FROM users ORDER BY id")))
  (check (length rows) => 3)
  (check (vector-ref (car rows) 0) => "Alice")
  (check (vector-ref (car rows) 1) => 30)
  (check (vector-ref (cadr rows) 0) => "Bob"))

;; --- SELECT with cursor ---
(display "SELECT cursor\n")
(let ((cur (sqlite-cursor db)))
  (sqlite-execute cur "SELECT name FROM users WHERE age > ?" 26)
  (let ((r1 (sqlite-fetchone cur)))
    (check-true r1)
    (check (vector-ref r1 0) => "Alice"))
  (let ((r2 (sqlite-fetchone cur)))
    (check-true r2)
    (check (vector-ref r2 0) => "Charlie"))
  (check (sqlite-fetchone cur) => #f)
  (sqlite-cursor-close cur))

;; --- NULL handling ---
(display "NULL handling\n")
(sqlite-exec db "INSERT INTO users (name, age, score) VALUES (?, ?, ?)" "Dave" #f #f)
(let ((rows (sqlite-query db "SELECT age, score FROM users WHERE name = ?" "Dave")))
  (check (length rows) => 1)
  (check (vector-ref (car rows) 0) => #f)
  (check (vector-ref (car rows) 1) => #f))

;; --- UPDATE + rowcount ---
(display "UPDATE\n")
(let ((n (sqlite-exec db "UPDATE users SET age = ? WHERE name = ?" 31 "Alice")))
  (check n => 1))

;; --- Description ---
(display "Description\n")
(let ((cur (sqlite-cursor db)))
  (sqlite-execute cur "SELECT name, age, score FROM users LIMIT 1")
  (let ((desc (sqlite-description cur)))
    (check (length desc) => 3)
    (check (car (car desc)) => "name")
    (check (car (cadr desc)) => "age"))
  (sqlite-cursor-close cur))

;; --- Transactions ---
(display "Transactions\n")
(call-with-sqlite-transaction db
  (lambda ()
    (sqlite-exec db "DELETE FROM users WHERE name = ?" "Dave")))
(let ((rows (sqlite-query db "SELECT * FROM users WHERE name = ?" "Dave")))
  (check (length rows) => 0))

;; --- call-with-sqlite ---
(display "call-with-sqlite\n")
(let ((result (call-with-sqlite ":memory:"
                (lambda (conn)
                  (sqlite-exec conn "CREATE TABLE t (x INTEGER)")
                  (sqlite-exec conn "INSERT INTO t VALUES (?)" 42)
                  (sqlite-query conn "SELECT x FROM t")))))
  (check (length result) => 1)
  (check (vector-ref (car result) 0) => 42))

;; --- Cleanup ---
(sqlite-close db)
(check-true (not (sqlite-open? db)))

;; --- Summary ---
(newline)
(display pass) (display " passed, ")
(display fail) (display " failed\n")
(when (> fail 0) (exit 1))
