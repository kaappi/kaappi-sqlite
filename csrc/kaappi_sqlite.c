#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <sqlite3.h>

/* Set-then-execute pattern matching kaappi-pg.
   Single-threaded — global state is safe. */

#define MAX_PARAMS 64

static char  stored_sql[16384];
static int   param_count = 0;

/* Parameter types: 0=text, 1=null, 2=int, 3=double */
static int   param_types[MAX_PARAMS];
static char *param_text_values[MAX_PARAMS];
static long  param_int_values[MAX_PARAMS];
static double param_double_values[MAX_PARAMS];

/* ------- Connection ------- */

void *ksql_open(const char *path) {
    sqlite3 *db = NULL;
    int rc = sqlite3_open(path, &db);
    if (rc != SQLITE_OK) {
        if (db) sqlite3_close(db);
        return NULL;
    }
    return (void *)db;
}

void ksql_close(void *db) {
    if (db) sqlite3_close((sqlite3 *)db);
}

const char *ksql_errmsg(void *db) {
    if (!db) return "database not open";
    return sqlite3_errmsg((sqlite3 *)db);
}

/* ------- Query setup ------- */

void ksql_set_sql(const char *sql) {
    strncpy(stored_sql, sql, sizeof(stored_sql) - 1);
    stored_sql[sizeof(stored_sql) - 1] = '\0';
}

void ksql_clear_params(void) {
    for (int i = 0; i < param_count; i++) {
        if (param_types[i] == 0 && param_text_values[i]) {
            free(param_text_values[i]);
            param_text_values[i] = NULL;
        }
    }
    param_count = 0;
}

void ksql_add_param(const char *value) {
    if (param_count >= MAX_PARAMS) return;
    param_types[param_count] = 0;
    param_text_values[param_count] = strdup(value);
    param_count++;
}

int ksql_add_null_param(void) {
    if (param_count >= MAX_PARAMS) return -1;
    param_types[param_count] = 1;
    param_count++;
    return 0;
}

void ksql_add_int_param(long value) {
    if (param_count >= MAX_PARAMS) return;
    param_types[param_count] = 2;
    param_int_values[param_count] = value;
    param_count++;
}

void ksql_add_double_param(double value) {
    if (param_count >= MAX_PARAMS) return;
    param_types[param_count] = 3;
    param_double_values[param_count] = value;
    param_count++;
}

/* ------- Bind staged params to a prepared statement ------- */

static void bind_params(sqlite3_stmt *stmt) {
    for (int i = 0; i < param_count; i++) {
        switch (param_types[i]) {
            case 0: /* text */
                sqlite3_bind_text(stmt, i + 1, param_text_values[i], -1, SQLITE_TRANSIENT);
                break;
            case 1: /* null */
                sqlite3_bind_null(stmt, i + 1);
                break;
            case 2: /* int */
                sqlite3_bind_int64(stmt, i + 1, param_int_values[i]);
                break;
            case 3: /* double */
                sqlite3_bind_double(stmt, i + 1, param_double_values[i]);
                break;
        }
    }
}

/* ------- Execution ------- */

/* Non-query: prepare, bind, step, finalize. Returns changes count as int. */
int ksql_exec(void *db) {
    sqlite3_stmt *stmt = NULL;
    int rc = sqlite3_prepare_v2((sqlite3 *)db, stored_sql, -1, &stmt, NULL);
    if (rc != SQLITE_OK) {
        ksql_clear_params();
        return -1;
    }
    bind_params(stmt);
    ksql_clear_params();
    rc = sqlite3_step(stmt);
    sqlite3_finalize(stmt);
    if (rc != SQLITE_DONE && rc != SQLITE_ROW) return -1;
    return sqlite3_changes((sqlite3 *)db);
}

/* Query: prepare and bind, return stmt pointer for stepping. */
void *ksql_prepare(void *db) {
    sqlite3_stmt *stmt = NULL;
    int rc = sqlite3_prepare_v2((sqlite3 *)db, stored_sql, -1, &stmt, NULL);
    if (rc != SQLITE_OK) {
        ksql_clear_params();
        return NULL;
    }
    bind_params(stmt);
    ksql_clear_params();
    return (void *)stmt;
}

/* ------- Stepping ------- */

int ksql_step(void *stmt) {
    return sqlite3_step((sqlite3_stmt *)stmt);
}

void ksql_finalize(void *stmt) {
    if (stmt) sqlite3_finalize((sqlite3_stmt *)stmt);
}

void ksql_reset(void *stmt) {
    if (stmt) sqlite3_reset((sqlite3_stmt *)stmt);
}

/* ------- Result access (col as pointer — fixnum trick) ------- */

int ksql_column_count(void *stmt) {
    return sqlite3_column_count((sqlite3_stmt *)stmt);
}

void *ksql_column_name(void *stmt, void *col_ptr) {
    int col = (int)(intptr_t)col_ptr;
    return (void *)sqlite3_column_name((sqlite3_stmt *)stmt, col);
}

int ksql_column_type(void *stmt, void *col_ptr) {
    int col = (int)(intptr_t)col_ptr;
    return sqlite3_column_type((sqlite3_stmt *)stmt, col);
}

void *ksql_column_text(void *stmt, void *col_ptr) {
    int col = (int)(intptr_t)col_ptr;
    return (void *)sqlite3_column_text((sqlite3_stmt *)stmt, col);
}

long ksql_column_int(void *stmt, void *col_ptr) {
    int col = (int)(intptr_t)col_ptr;
    return (long)sqlite3_column_int64((sqlite3_stmt *)stmt, col);
}

double ksql_column_double(void *stmt, void *col_ptr) {
    int col = (int)(intptr_t)col_ptr;
    return sqlite3_column_double((sqlite3_stmt *)stmt, col);
}

/* ------- Utility ------- */

int ksql_changes(void *db) {
    return sqlite3_changes((sqlite3 *)db);
}

long ksql_last_insert_rowid(void *db) {
    return (long)sqlite3_last_insert_rowid((sqlite3 *)db);
}

const char *ksql_ptr_to_str(void *ptr) {
    return (const char *)ptr;
}
