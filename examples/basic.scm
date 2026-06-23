(import (kaappi sqlite))

(call-with-sqlite ":memory:"
  (lambda (db)
    (sqlite-exec db "CREATE TABLE tasks (id INTEGER PRIMARY KEY, title TEXT, done INTEGER)")
    (sqlite-exec db "INSERT INTO tasks (title, done) VALUES (?, ?)" "Buy milk" 0)
    (sqlite-exec db "INSERT INTO tasks (title, done) VALUES (?, ?)" "Write Scheme" 1)
    (sqlite-exec db "INSERT INTO tasks (title, done) VALUES (?, ?)" "Deploy app" 0)

    (display "All tasks:\n")
    (for-each
      (lambda (row)
        (display "  ")
        (display (vector-ref row 0)) (display ". ")
        (display (vector-ref row 1))
        (display (if (= (vector-ref row 2) 1) " [done]" ""))
        (newline))
      (sqlite-query db "SELECT id, title, done FROM tasks ORDER BY id"))

    (display "\nPending tasks: ")
    (display (length (sqlite-query db "SELECT * FROM tasks WHERE done = ?" 0)))
    (display "\n")))
