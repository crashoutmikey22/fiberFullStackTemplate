#!/bin/bash

set -e

# Database Migration Script
# Usage: ./cmds/migrate.sh [command] [options]

# Default values
MIGRATION_DIR="./sql/migrations"
ENV_FILE=".env"
DRY_RUN=false
VERBOSE=false
BATCH_SIZE=10

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Parse arguments
COMMAND=${1:-"help"}
shift || true

while [[ $# -gt 0 ]]; do
    case $1 in
        --dir)
            MIGRATION_DIR="$2"
            shift 2
            ;;
        --env)
            ENV_FILE="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --batch-size)
            BATCH_SIZE="$2"
            shift 2
            ;;
        -h|--help)
            COMMAND="help"
            break
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to print status
print_status() {
    local status=$1
    local message=$2
    case $status in
        "SUCCESS")
            print_color "$GREEN" "✅ $message"
            ;;
        "ERROR")
            print_color "$RED" "❌ $message"
            ;;
        "WARNING")
            print_color "$YELLOW" "⚠️  $message"
            ;;
        "INFO")
            print_color "$BLUE" "ℹ️  $message"
            ;;
        "HEADER")
            print_color "$CYAN" "$message"
            ;;
    esac
}

# Function to load environment variables
load_env() {
    if [ -f "$ENV_FILE" ]; then
        # Export variables from .env file
        set -a
        source "$ENV_FILE"
        set +a
    else
        print_status "WARNING" "Environment file not found: $ENV_FILE"
    fi
}

# Function to get database URL
get_db_url() {
    load_env
    
    if [ -n "$DB_URL" ]; then
        echo "$DB_URL"
    elif [ -n "$DB_PATH" ]; then
        echo "sqlite:$DB_PATH"
    else
        print_status "ERROR" "No database URL found in environment"
        return 1
    fi
}

# Function to ensure migration directory exists
ensure_migration_dir() {
    if [ ! -d "$MIGRATION_DIR" ]; then
        mkdir -p "$MIGRATION_DIR"
        print_status "INFO" "Created migration directory: $MIGRATION_DIR"
    fi
}

# Function to generate migration filename
generate_migration_name() {
    local description="$1"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local safe_desc=$(echo "$description" | tr ' ' '_' | tr -cd 'a-zA-Z0-9_-')
    echo "${timestamp}_${safe_desc}"
}

# Function to create new migration
create_migration() {
    local description="$1"
    
    if [ -z "$description" ]; then
        print_status "ERROR" "Migration description required"
        echo "Usage: $0 create <description>"
        exit 1
    fi
    
    ensure_migration_dir
    
    local migration_name=$(generate_migration_name "$description")
    local up_file="$MIGRATION_DIR/${migration_name}_up.sql"
    local down_file="$MIGRATION_DIR/${migration_name}_down.sql"
    
    # Create up migration
    cat > "$up_file" << EOF
-- Migration: $description
-- Created: $(date)
-- Description: $description

BEGIN;

-- Add your SQL statements here
-- Example:
-- CREATE TABLE example (
--     id SERIAL PRIMARY KEY,
--     name VARCHAR(255) NOT NULL,
--     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
-- );

COMMIT;
EOF
    
    # Create down migration
    cat > "$down_file" << EOF
-- Rollback: $description
-- Created: $(date)
-- Description: $description

BEGIN;

-- Add your rollback SQL statements here
-- Example:
-- DROP TABLE IF EXISTS example;

COMMIT;
EOF
    
    print_status "SUCCESS" "Created migration files:"
    print_status "INFO" "  Up: $up_file"
    print_status "INFO" "  Down: $down_file"
    
    if command_exists "$EDITOR"; then
        print_status "INFO" "Opening files in editor: $EDITOR"
        $EDITOR "$up_file" "$down_file"
    else
        print_status "INFO" "Set EDITOR environment variable to automatically open files"
    fi
}

# Function to list pending migrations
list_pending() {
    print_status "HEADER" "📋 Pending Migrations"
    
    ensure_migration_dir
    
    local db_url=$(get_db_url)
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    # This would typically query the database schema_migrations table
    # For now, we'll show all migration files
    local migration_files=$(find "$MIGRATION_DIR" -name "*_up.sql" | sort)
    
    if [ -z "$migration_files" ]; then
        print_status "INFO" "No migration files found in $MIGRATION_DIR"
        return 0
    fi
    
    print_status "INFO" "Migration files in $MIGRATION_DIR:"
    echo "$migration_files" | while read -r file; do
        local basename=$(basename "$file")
        echo "  $basename"
    done
}

# Function to run migrations
run_migrations() {
    local direction="${1:-up}"
    
    print_status "HEADER" "🚀 Running Migrations ($direction)"
    
    ensure_migration_dir
    
    local db_url=$(get_db_url)
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    if [ "$DRY_RUN" = true ]; then
        print_status "INFO" "DRY RUN MODE - No changes will be applied"
    fi
    
    # Get migration files
    local migration_pattern="*_${direction}.sql"
    local migration_files=$(find "$MIGRATION_DIR" -name "$migration_pattern" | sort)
    
    if [ -z "$migration_files" ]; then
        print_status "INFO" "No migration files found for direction: $direction"
        return 0
    fi
    
    local total_migrations=$(echo "$migration_files" | wc -l)
    print_status "INFO" "Found $total_migrations migration(s)"
    
    local executed=0
    local failed=0
    
    echo "$migration_files" | while read -r migration_file; do
        local basename=$(basename "$migration_file")
        local migration_name="${basename%_${direction}.sql}"
        
        if [ "$VERBOSE" = true ]; then
            print_status "INFO" "Processing: $basename"
        fi
        
        if [ "$DRY_RUN" = true ]; then
            print_status "INFO" "[DRY RUN] Would execute: $basename"
            executed=$((executed + 1))
        else
            # Execute migration (this would use your database tool of choice)
            # Example with psql, mysql, or sqlite3
            if [[ "$db_url" == sqlite:* ]]; then
                local db_path="${db_url#sqlite:}"
                if sqlite3 "$db_path" < "$migration_file"; then
                    print_status "SUCCESS" "Executed: $basename"
                    executed=$((executed + 1))
                else
                    print_status "ERROR" "Failed: $basename"
                    failed=$((failed + 1))
                fi
            elif [[ "$db_url" == postgres:* ]]; then
                if command_exists "psql"; then
                    if psql "$db_url" -f "$migration_file" >/dev/null 2>&1; then
                        print_status "SUCCESS" "Executed: $basename"
                        executed=$((executed + 1))
                    else
                        print_status "ERROR" "Failed: $basename"
                        failed=$((failed + 1))
                    fi
                else
                    print_status "WARNING" "psql not found, skipping PostgreSQL migration"
                fi
            else
                print_status "WARNING" "Unsupported database type: $db_url"
            fi
        fi
        
        # Break after batch size if specified
        if [ "$executed" -ge "$BATCH_SIZE" ] && [ "$BATCH_SIZE" -gt 0 ]; then
            print_status "INFO" "Batch size limit reached: $BATCH_SIZE"
            break
        fi
    done
    
    print_status "INFO" "Migration summary: $executed executed, $failed failed"
}

# Function to rollback migrations
rollback_migrations() {
    local steps="${1:-1}"
    
    print_status "HEADER" "⏪ Rolling Back Migrations ($steps step(s))"
    
    ensure_migration_dir
    
    local db_url=$(get_db_url)
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    if [ "$DRY_RUN" = true ]; then
        print_status "INFO" "DRY RUN MODE - No changes will be applied"
    fi
    
    # Get migration files in reverse order
    local migration_pattern="*_down.sql"
    local migration_files=$(find "$MIGRATION_DIR" -name "$migration_pattern" | sort -r)
    
    if [ -z "$migration_files" ]; then
        print_status "INFO" "No rollback files found"
        return 0
    fi
    
    local rolled_back=0
    local failed=0
    
    echo "$migration_files" | while read -r migration_file; do
        if [ "$rolled_back" -ge "$steps" ]; then
            break
        fi
        
        local basename=$(basename "$migration_file")
        local migration_name="${basename%_down.sql}"
        
        if [ "$VERBOSE" = true ]; then
            print_status "INFO" "Rolling back: $basename"
        fi
        
        if [ "$DRY_RUN" = true ]; then
            print_status "INFO" "[DRY RUN] Would rollback: $basename"
            rolled_back=$((rolled_back + 1))
        else
            # Execute rollback (similar to run_migrations)
            if [[ "$db_url" == sqlite:* ]]; then
                local db_path="${db_url#sqlite:}"
                if sqlite3 "$db_path" < "$migration_file"; then
                    print_status "SUCCESS" "Rolled back: $basename"
                    rolled_back=$((rolled_back + 1))
                else
                    print_status "ERROR" "Rollback failed: $basename"
                    failed=$((failed + 1))
                fi
            else
                print_status "WARNING" "Rollback not implemented for this database type"
            fi
        fi
    done
    
    print_status "INFO" "Rollback summary: $rolled_back rolled back, $failed failed"
}

# Function to show migration status
show_status() {
    print_status "HEADER" "📊 Migration Status"
    
    ensure_migration_dir
    
    print_status "INFO" "Migration directory: $MIGRATION_DIR"
    print_status "INFO" "Environment file: $ENV_FILE"
    print_status "INFO" "Dry run: $DRY_RUN"
    print_status "INFO" "Verbose: $VERBOSE"
    print_status "INFO" "Batch size: $BATCH_SIZE"
    
    # Show database connection
    local db_url=$(get_db_url)
    if [ $? -eq 0 ]; then
        print_status "INFO" "Database URL: ${db_url:0:50}..."
    fi
    
    # Count migration files
    local up_files=$(find "$MIGRATION_DIR" -name "*_up.sql" 2>/dev/null | wc -l)
    local down_files=$(find "$MIGRATION_DIR" -name "*_down.sql" 2>/dev/null | wc -l)
    
    print_status "INFO" "Migration files: $up_files up, $down_files down"
    
    if [ "$up_files" -gt 0 ]; then
        print_status "INFO" "Recent migrations:"
        find "$MIGRATION_DIR" -name "*_up.sql" -type f -exec basename {} \; | sort -r | head -5 | while read -r file; do
            echo "  $file"
        done
    fi
}

# Function to validate migrations
validate_migrations() {
    print_status "HEADER" "🔍 Validating Migrations"
    
    ensure_migration_dir
    
    local errors=0
    
    # Check for matching up/down files
    find "$MIGRATION_DIR" -name "*_up.sql" -type f | while read -r up_file; do
        local basename=$(basename "$up_file")
        local migration_name="${basename%_up.sql}"
        local down_file="$MIGRATION_DIR/${migration_name}_down.sql"
        
        if [ ! -f "$down_file" ]; then
            print_status "ERROR" "Missing down migration: ${migration_name}_down.sql"
            errors=$((errors + 1))
        fi
    done
    
    # Check for SQL syntax errors (basic check)
    find "$MIGRATION_DIR" -name "*.sql" -type f | while read -r sql_file; do
        if grep -q "BEGIN;" "$sql_file" && ! grep -q "COMMIT;" "$sql_file"; then
            print_status "ERROR" "Missing COMMIT in: $(basename "$sql_file")"
            errors=$((errors + 1))
        fi
    done
    
    if [ "$errors" -eq 0 ]; then
        print_status "SUCCESS" "All migrations are valid"
    else
        print_status "ERROR" "Found $errors validation error(s)"
    fi
}

# Function to show help
show_help() {
    print_color "$CYAN" "📋 Database Migration Script"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  help                    Show this help message"
    echo "  status                  Show migration status"
    echo "  create <description>    Create new migration files"
    echo "  list                    List pending migrations"
    echo "  up                      Run pending migrations"
    echo "  down [steps]            Rollback migrations (default: 1 step)"
    echo "  validate                Validate migration files"
    echo ""
    echo "Options:"
    echo "  --dir <path>            Migration directory (default: ./sql/migrations)"
    echo "  --env <file>            Environment file (default: .env)"
    echo "  --dry-run               Show what would be done without executing"
    echo "  --verbose               Show detailed output"
    echo "  --batch-size <number>   Number of migrations to run in batch"
    echo ""
    echo "Examples:"
    echo "  $0 create \"Add user table\""
    echo "  $0 up --dry-run"
    echo "  $0 down 2"
    echo "  $0 validate --verbose"
    echo "  $0 status --env .env.production"
}

# Main command dispatcher
case $COMMAND in
    "help"|"-h"|"--help")
        show_help
        ;;
    "status")
        show_status
        ;;
    "create")
        create_migration "$1"
        ;;
    "list")
        list_pending
        ;;
    "up")
        run_migrations "up"
        ;;
    "down")
        rollback_migrations "${1:-1}"
        ;;
    "validate")
        validate_migrations
        ;;
    *)
        print_status "ERROR" "Unknown command: $COMMAND"
        echo ""
        show_help
        exit 1
        ;;
esac