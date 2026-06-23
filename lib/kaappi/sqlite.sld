(define-library (kaappi sqlite)
  (import (scheme base)
          (kaappi sqlite ffi)
          (kaappi sqlite types))
  (export sqlite-open sqlite-close sqlite-open? sqlite-error-message
          sqlite-cursor sqlite-execute sqlite-fetchone sqlite-fetchall
          sqlite-description sqlite-rowcount sqlite-cursor-close
          sqlite-exec sqlite-query sqlite-last-insert-id
          call-with-sqlite call-with-sqlite-transaction)
  (begin

    ;; --- Connection record ---

    (define-record-type <sqlite-connection>
      (%make-sqlite-connection ptr path)
      sqlite-connection?
      (ptr  sqlite-conn-ptr set-sqlite-conn-ptr!)
      (path sqlite-conn-path))

    (define (sqlite-open path)
      (let ((ptr (%sqlite-open path)))
        (when (= ptr 0)
          (error "sqlite-open failed" path))
        (%make-sqlite-connection ptr path)))

    (define (sqlite-close conn)
      (when (sqlite-open? conn)
        (%sqlite-close (sqlite-conn-ptr conn))
        (set-sqlite-conn-ptr! conn 0)))

    (define (sqlite-open? conn)
      (not (= (sqlite-conn-ptr conn) 0)))

    (define (sqlite-error-message conn)
      (%sqlite-errmsg (sqlite-conn-ptr conn)))

    ;; --- Cursor record ---

    (define-record-type <sqlite-cursor>
      (%make-sqlite-cursor conn stmt ncols types done?)
      sqlite-cursor?
      (conn   cursor-conn)
      (stmt   cursor-stmt   set-cursor-stmt!)
      (ncols  cursor-ncols  set-cursor-ncols!)
      (types  cursor-types  set-cursor-types!)
      (done?  cursor-done?  set-cursor-done?!))

    (define (sqlite-cursor conn)
      (%make-sqlite-cursor conn 0 0 '() #t))

    (define (sqlite-cursor-close cursor)
      (when (not (= (cursor-stmt cursor) 0))
        (%sqlite-finalize (cursor-stmt cursor))
        (set-cursor-stmt! cursor 0)
        (set-cursor-done?! cursor #t)))

    ;; --- Execute ---

    (define (sqlite-execute cursor sql . params)
      (sqlite-cursor-close cursor)
      (let ((conn-ptr (sqlite-conn-ptr (cursor-conn cursor))))
        (%sqlite-set-sql sql)
        (%sqlite-clear-params)
        (for-each
          (lambda (p)
            (let ((converted (sqlite-convert-param p)))
              (cond
                ((eq? converted #f) (%sqlite-add-null-param))
                ((and (number? p) (exact? p) (integer? p))
                 (%sqlite-add-int-param p))
                ((and (number? p) (not (exact? p)))
                 (%sqlite-add-double-param p))
                (else (%sqlite-add-param converted)))))
          params)
        (let ((stmt (%sqlite-prepare conn-ptr)))
          (when (= stmt 0)
            (error "sqlite: query failed" (sqlite-error-message (cursor-conn cursor))))
          (set-cursor-stmt! cursor stmt)
          (let ((ncols (%sqlite-column-count stmt)))
            (set-cursor-ncols! cursor ncols)
            (set-cursor-done?! cursor #f)
            ;; Cache column types after first step if it's a query
            (set-cursor-types! cursor '())))))

    ;; --- Fetch ---

    (define (sqlite-fetchone cursor)
      (if (cursor-done? cursor)
          #f
          (let* ((stmt  (cursor-stmt cursor))
                 (rc    (%sqlite-step stmt))
                 (ncols (cursor-ncols cursor)))
            (if (= rc SQLITE_ROW)
                (let ((row (make-vector ncols)))
                  (let loop ((col 0))
                    (when (< col ncols)
                      (let ((type-id (%sqlite-column-type stmt col)))
                        (if (= type-id SQLITE_NULL)
                            (vector-set! row col #f)
                            (let* ((ptr  (%sqlite-column-text stmt col))
                                   (text (%sqlite-ptr-to-str ptr)))
                              (vector-set! row col
                                (sqlite-convert-value type-id text)))))
                      (loop (+ col 1))))
                  row)
                (begin
                  (set-cursor-done?! cursor #t)
                  #f)))))

    (define (sqlite-fetchall cursor)
      (let loop ((acc '()))
        (let ((row (sqlite-fetchone cursor)))
          (if (eq? row #f)
              (reverse acc)
              (loop (cons row acc))))))

    ;; --- Description ---

    (define (sqlite-description cursor)
      (let ((stmt  (cursor-stmt cursor))
            (ncols (cursor-ncols cursor)))
        (if (= stmt 0)
            '()
            (let loop ((i 0) (acc '()))
              (if (= i ncols)
                  (reverse acc)
                  (let* ((name-ptr (%sqlite-column-name stmt i))
                         (name (%sqlite-ptr-to-str name-ptr)))
                    (loop (+ i 1) (cons (list name) acc))))))))

    ;; --- Rowcount ---

    (define (sqlite-rowcount cursor)
      (%sqlite-changes (sqlite-conn-ptr (cursor-conn cursor))))

    ;; --- Convenience ---

    (define (sqlite-last-insert-id conn)
      (%sqlite-last-insert-rowid (sqlite-conn-ptr conn)))

    (define (sqlite-exec conn sql . params)
      (let ((conn-ptr (sqlite-conn-ptr conn)))
        (%sqlite-set-sql sql)
        (%sqlite-clear-params)
        (for-each
          (lambda (p)
            (let ((converted (sqlite-convert-param p)))
              (cond
                ((eq? converted #f) (%sqlite-add-null-param))
                ((and (number? p) (exact? p) (integer? p))
                 (%sqlite-add-int-param p))
                ((and (number? p) (not (exact? p)))
                 (%sqlite-add-double-param p))
                (else (%sqlite-add-param converted)))))
          params)
        (%sqlite-exec conn-ptr)))

    (define (sqlite-query conn sql . params)
      (let ((cur (sqlite-cursor conn)))
        (apply sqlite-execute cur sql params)
        (let ((rows (sqlite-fetchall cur)))
          (sqlite-cursor-close cur)
          rows)))

    (define (call-with-sqlite path-or-conn proc)
      (if (sqlite-connection? path-or-conn)
          (proc path-or-conn)
          (let ((conn (sqlite-open path-or-conn)))
            (guard (exn
                    (#t (sqlite-close conn) (raise exn)))
              (let ((result (proc conn)))
                (sqlite-close conn)
                result)))))

    (define (call-with-sqlite-transaction conn proc)
      (sqlite-exec conn "BEGIN")
      (guard (exn
              (#t (sqlite-exec conn "ROLLBACK") (raise exn)))
        (let ((result (proc)))
          (sqlite-exec conn "COMMIT")
          result)))))
