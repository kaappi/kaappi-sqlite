(import (scheme base) (scheme write)
        (kaappi sqlite types)
        (kaappi sqlite ffi))

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

;; --- Value conversion ---

(display "Type conversion tests\n")

(check (sqlite-convert-value SQLITE_INTEGER "42") => 42)
(check (sqlite-convert-value SQLITE_INTEGER "-7") => -7)
(check (sqlite-convert-value SQLITE_INTEGER "0")  => 0)

(check (sqlite-convert-value SQLITE_FLOAT "3.14")  => 3.14)
(check (sqlite-convert-value SQLITE_FLOAT "-1.5")  => -1.5)

(check (sqlite-convert-value SQLITE_TEXT "hello") => "hello")
(check (sqlite-convert-value SQLITE_TEXT "")      => "")

(check (sqlite-convert-value SQLITE_NULL "")   => #f)
(check (sqlite-convert-value SQLITE_NULL "x")  => #f)

(check (sqlite-convert-value SQLITE_BLOB "data") => "data")

;; --- Param conversion ---

(display "Param conversion tests\n")

(check (sqlite-convert-param "hello") => "hello")
(check (sqlite-convert-param 42)      => "42")
(check (sqlite-convert-param 3.14)    => "3.14")
(check (sqlite-convert-param #t)      => "1")
(check (sqlite-convert-param #f)      => #f)

;; --- Summary ---

(display "\n")
(display pass) (display " passed, ")
(display fail) (display " failed\n")
(when (> fail 0) (exit 1))
