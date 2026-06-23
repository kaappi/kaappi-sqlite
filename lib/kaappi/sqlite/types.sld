(define-library (kaappi sqlite types)
  (import (scheme base)
          (kaappi sqlite ffi))
  (export sqlite-convert-value sqlite-convert-param)
  (begin

    (define (sqlite-convert-value type-id text)
      (cond
        ((= type-id SQLITE_NULL) #f)
        ((= type-id SQLITE_INTEGER)
         (or (string->number text) text))
        ((= type-id SQLITE_FLOAT)
         (or (string->number text) text))
        ((= type-id SQLITE_TEXT) text)
        ((= type-id SQLITE_BLOB) text)
        (else text)))

    (define (sqlite-convert-param value)
      (cond
        ((eq? value #f) #f)
        ((eq? value #t) "1")
        ((string? value) value)
        ((number? value) (number->string value))
        (else (error "unsupported parameter type" value))))))
