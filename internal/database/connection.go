package database

import (
	"context"
	"database/sql"
	"fmt"
	"log"
	"time"

	"github.com/lib/pq"
	_ "github.com/lib/pq" // PostgreSQL driver
)

// DB represents the database connection
type DB struct {
	*sql.DB
}

// NewConnection creates a new database connection
func NewConnection(dbURL string) (*DB, error) {
	if dbURL == "" {
		return nil, fmt.Errorf("database URL is required")
	}

	// Parse the PostgreSQL connection string
	connStr, err := pq.ParseURL(dbURL)
	if err != nil {
		return nil, fmt.Errorf("failed to parse database URL: %w", err)
	}

	// Open database connection
	db, err := sql.Open("postgres", connStr)
	if err != nil {
		return nil, fmt.Errorf("failed to open database: %w", err)
	}

	// Configure connection pool
	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(25)
	db.SetConnMaxLifetime(5 * time.Minute)

	// Test the connection
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := db.PingContext(ctx); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	return &DB{db}, nil
}

// HealthCheck performs a health check on the database
func (db *DB) HealthCheck(ctx context.Context) error {
	if db == nil || db.DB == nil {
		return fmt.Errorf("database connection is nil")
	}

	// Create a context with timeout
	ctx, cancel := context.WithTimeout(ctx, 3*time.Second)
	defer cancel()

	// Execute a simple query to check if the database is responsive
	_, err := db.ExecContext(ctx, "SELECT 1")
	if err != nil {
		return fmt.Errorf("database health check failed: %w", err)
	}

	return nil
}

// Close closes the database connection
func (db *DB) Close() error {
	if db != nil && db.DB != nil {
		return db.DB.Close()
	}
	return nil
}

// BeginTx starts a transaction with the provided context
func (db *DB) BeginTx(ctx context.Context, opts *sql.TxOptions) (*sql.Tx, error) {
	return db.DB.BeginTx(ctx, opts)
}

// ExecContext executes a query that doesn't return rows
func (db *DB) ExecContext(ctx context.Context, query string, args ...interface{}) (sql.Result, error) {
	return db.DB.ExecContext(ctx, query, args...)
}

// QueryContext executes a query that returns rows
func (db *DB) QueryContext(ctx context.Context, query string, args ...interface{}) (*sql.Rows, error) {
	return db.DB.QueryContext(ctx, query, args...)
}

// QueryRowContext executes a query that returns a single row
func (db *DB) QueryRowContext(ctx context.Context, query string, args ...interface{}) *sql.Row {
	return db.DB.QueryRowContext(ctx, query, args...)
}

// PrepareContext creates a prepared statement
func (db *DB) PrepareContext(ctx context.Context, query string) (*sql.Stmt, error) {
	return db.DB.PrepareContext(ctx, query)
}

// WithTransaction executes a function within a transaction
func (db *DB) WithTransaction(ctx context.Context, fn func(*sql.Tx) error) error {
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}

	defer func() {
		if p := recover(); p != nil {
			_ = tx.Rollback()
			log.Printf("Transaction panicked: %v", p)
			panic(p)
		}
		if err != nil {
			_ = tx.Rollback()
		} else {
			err = tx.Commit()
		}
	}()

	if err := fn(tx); err != nil {
		return fmt.Errorf("transaction function failed: %w", err)
	}

	return nil
}
