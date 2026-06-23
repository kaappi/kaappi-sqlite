(define-library (kaappi sqlite ffi)
  (import (scheme base) (kaappi ffi))
  (export %sqlite-open %sqlite-close %sqlite-errmsg
          %sqlite-set-sql %sqlite-clear-params
          %sqlite-add-param %sqlite-add-null-param
          %sqlite-add-int-param %sqlite-add-double-param
          %sqlite-exec %sqlite-prepare
          %sqlite-step %sqlite-finalize %sqlite-reset
          %sqlite-column-count %sqlite-column-name
          %sqlite-column-type %sqlite-column-text
          %sqlite-column-int %sqlite-column-double
          %sqlite-changes %sqlite-last-insert-rowid
          %sqlite-ptr-to-str
          SQLITE_OK SQLITE_ROW SQLITE_DONE
          SQLITE_INTEGER SQLITE_FLOAT SQLITE_TEXT
          SQLITE_BLOB SQLITE_NULL)
  (begin

    (define %lib (ffi-open "libkaappi_sqlite"))

    ;; Status constants
    (define SQLITE_OK   0)
    (define SQLITE_ROW  100)
    (define SQLITE_DONE 101)

    ;; Type constants
    (define SQLITE_INTEGER 1)
    (define SQLITE_FLOAT   2)
    (define SQLITE_TEXT    3)
    (define SQLITE_BLOB    4)
    (define SQLITE_NULL    5)

    ;; Connection
    (define %sqlite-open   (ffi-fn %lib "ksql_open" '(string) 'pointer))
    (define %sqlite-close  (ffi-fn %lib "ksql_close" '(pointer) 'void))
    (define %sqlite-errmsg (ffi-fn %lib "ksql_errmsg" '(pointer) 'string))

    ;; Query setup
    (define %sqlite-set-sql       (ffi-fn %lib "ksql_set_sql" '(string) 'void))
    (define %sqlite-clear-params  (ffi-fn %lib "ksql_clear_params" '() 'void))
    (define %sqlite-add-param     (ffi-fn %lib "ksql_add_param" '(string) 'void))
    (define %sqlite-add-null-param (ffi-fn %lib "ksql_add_null_param" '() 'int))
    (define %sqlite-add-int-param  (ffi-fn %lib "ksql_add_int_param" '(long) 'void))
    (define %sqlite-add-double-param (ffi-fn %lib "ksql_add_double_param" '(double) 'void))

    ;; Execution
    (define %sqlite-exec    (ffi-fn %lib "ksql_exec" '(pointer) 'int))
    (define %sqlite-prepare (ffi-fn %lib "ksql_prepare" '(pointer) 'pointer))

    ;; Stepping
    (define %sqlite-step     (ffi-fn %lib "ksql_step" '(pointer) 'int))
    (define %sqlite-finalize (ffi-fn %lib "ksql_finalize" '(pointer) 'void))
    (define %sqlite-reset    (ffi-fn %lib "ksql_reset" '(pointer) 'void))

    ;; Result access (col as pointer — fixnum trick)
    (define %sqlite-column-count  (ffi-fn %lib "ksql_column_count" '(pointer) 'int))
    (define %sqlite-column-name   (ffi-fn %lib "ksql_column_name" '(pointer pointer) 'pointer))
    (define %sqlite-column-type   (ffi-fn %lib "ksql_column_type" '(pointer pointer) 'int))
    (define %sqlite-column-text   (ffi-fn %lib "ksql_column_text" '(pointer pointer) 'pointer))
    (define %sqlite-column-int    (ffi-fn %lib "ksql_column_int" '(pointer pointer) 'long))
    (define %sqlite-column-double (ffi-fn %lib "ksql_column_double" '(pointer pointer) 'double))

    ;; Utility
    (define %sqlite-changes          (ffi-fn %lib "ksql_changes" '(pointer) 'int))
    (define %sqlite-last-insert-rowid (ffi-fn %lib "ksql_last_insert_rowid" '(pointer) 'long))
    (define %sqlite-ptr-to-str       (ffi-fn %lib "ksql_ptr_to_str" '(pointer) 'string))))
