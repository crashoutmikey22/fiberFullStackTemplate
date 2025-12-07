#!/bin/bash

set -e

# Database Seeding Script
# Usage: ./cmds/seed.sh [command] [options]

# Default values
SEED_DIR="./sql/seeds"
ENV_FILE=".env"
DRY_RUN=false
VERBOSE=false
ENVIRONMENT="development"
BATCH_SIZE=100

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
            SEED_DIR="$2"
            shift 2
            ;;
        --env)
            ENV_FILE="$2"
            shift 2
            ;;
        --env-name)
            ENVIRONMENT="$2"
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

# Function to ensure seed directory exists
ensure_seed_dir() {
    if [ ! -d "$SEED_DIR" ]; then
        mkdir -p "$SEED_DIR"
        print_status "INFO" "Created seed directory: $SEED_DIR"
    fi
}

# Function to generate seed filename
generate_seed_name() {
    local description="$1"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local safe_desc=$(echo "$description" | tr ' ' '_' | tr -cd 'a-zA-Z0-9_-')
    echo "${timestamp}_${safe_desc}"
}

# Function to create new seed file
create_seed() {
    local description="$1"
    
    if [ -z "$description" ]; then
        print_status "ERROR" "Seed description required"
        echo "Usage: $0 create <description>"
        exit 1
    fi
    
    ensure_seed_dir
    
    local seed_name=$(generate_seed_name "$description")
    local seed_file="$SEED_DIR/${seed_name}.sql"
    
    # Create seed file
    cat > "$seed_file" << EOF
-- Seed: $description
-- Created: $(date)
-- Environment: $ENVIRONMENT
-- Description: $description

BEGIN;

-- Clear existing data (optional)
-- DELETE FROM table_name WHERE condition;

-- Insert seed data
-- Example:
-- INSERT INTO users (username, email, created_at) VALUES
-- ('admin', 'admin@example.com', NOW()),
-- ('user1', 'user1@example.com', NOW()),
-- ('user2', 'user2@example.com', NOW());

-- Insert configuration data
-- INSERT INTO settings (key, value, description) VALUES
-- ('app_name', 'My Application', 'Application name'),
-- ('max_users', '1000', 'Maximum number of users'),
-- ('maintenance_mode', 'false', 'Maintenance mode status');

COMMIT;
EOF
    
    print_status "SUCCESS" "Created seed file: $seed_file"
    
    if command_exists "$EDITOR"; then
        print_status "INFO" "Opening file in editor: $EDITOR"
        $EDITOR "$seed_file"
    else
        print_status "INFO" "Set EDITOR environment variable to automatically open files"
    fi
}

# Function to list available seeds
list_seeds() {
    print_status "HEADER" "📋 Available Seeds"
    
    ensure_seed_dir
    
    local seed_files=$(find "$SEED_DIR" -name "*.sql" | sort)
    
    if [ -z "$seed_files" ]; then
        print_status "INFO" "No seed files found in $SEED_DIR"
        return 0
    fi
    
    print_status "INFO" "Seed files in $SEED_DIR:"
    echo "$seed_files" | while read -r file; do
        local basename=$(basename "$file")
        local size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0")
        echo "  $basename ($size bytes)"
    done
}

# Function to run seeds
run_seeds() {
    local seed_pattern="${1:-*.sql}"
    
    print_status "HEADER" "🌱 Running Seeds ($seed_pattern)"
    
    ensure_seed_dir
    
    local db_url=$(get_db_url)
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    if [ "$DRY_RUN" = true ]; then
        print_status "INFO" "DRY RUN MODE - No changes will be applied"
    fi
    
    # Get seed files
    local seed_files=$(find "$SEED_DIR" -name "$seed_pattern" | sort)
    
    if [ -z "$seed_files" ]; then
        print_status "INFO" "No seed files found matching: $seed_pattern"
        return 0
    fi
    
    local total_seeds=$(echo "$seed_files" | wc -l)
    print_status "INFO" "Found $total_seeds seed file(s)"
    
    local executed=0
    local failed=0
    
    echo "$seed_files" | while read -r seed_file; do
        local basename=$(basename "$seed_file")
        
        if [ "$VERBOSE" = true ]; then
            print_status "INFO" "Processing: $basename"
        fi
        
        if [ "$DRY_RUN" = true ]; then
            print_status "INFO" "[DRY RUN] Would execute: $basename"
            executed=$((executed + 1))
        else
            # Execute seed
            if [[ "$db_url" == sqlite:* ]]; then
                local db_path="${db_url#sqlite:}"
                if sqlite3 "$db_path" < "$seed_file"; then
                    print_status "SUCCESS" "Executed: $basename"
                    executed=$((executed + 1))
                else
                    print_status "ERROR" "Failed: $basename"
                    failed=$((failed + 1))
                fi
            elif [[ "$db_url" == postgres:* ]]; then
                if command_exists "psql"; then
                    if psql "$db_url" -f "$seed_file" >/dev/null 2>&1; then
                        print_status "SUCCESS" "Executed: $basename"
                        executed=$((executed + 1))
                    else
                        print_status "ERROR" "Failed: $basename"
                        failed=$((failed + 1))
                    fi
                else
                    print_status "WARNING" "psql not found, skipping PostgreSQL seed"
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
    
    print_status "INFO" "Seed summary: $executed executed, $failed failed"
}

# Function to clear data
clear_data() {
    local table_pattern="${1:-*}"
    
    print_status "HEADER" "🗑️  Clearing Data ($table_pattern)"
    
    local db_url=$(get_db_url)
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    if [ "$DRY_RUN" = true ]; then
        print_status "INFO" "DRY RUN MODE - No changes will be applied"
    fi
    
    # This is a dangerous operation - require confirmation
    if [ "$DRY_RUN" = false ]; then
        print_status "WARNING" "This will delete data from tables matching: $table_pattern"
        read -p "Are you sure you want to continue? (yes/no): " -r
        if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
            print_status "INFO" "Operation cancelled"
            return 0
        fi
    fi
    
    # Clear data based on database type
    if [[ "$db_url" == sqlite:* ]]; then
        local db_path="${db_url#sqlite:}"
        if [ "$DRY_RUN" = true ]; then
            print_status "INFO" "[DRY RUN] Would clear tables matching: $table_pattern"
        else
            # Get list of tables and clear them
            local tables=$(sqlite3 "$db_path" "SELECT name FROM sqlite_master WHERE type='table' AND name LIKE '$table_pattern';" 2>/dev/null || echo "")
            if [ -n "$tables" ]; then
                echo "$tables" | while read -r table; do
                    if [ "$VERBOSE" = true ]; then
                        print_status "INFO" "Clearing table: $table"
                    fi
                    sqlite3 "$db_path" "DELETE FROM $table;" 2>/dev/null && \
                        print_status "SUCCESS" "Cleared table: $table" || \
                        print_status "ERROR" "Failed to clear table: $table"
                done
            else
                print_status "INFO" "No tables found matching: $table_pattern"
            fi
        fi
    else
        print_status "WARNING" "Clear operation not implemented for this database type"
    fi
}

# Function to generate sample data
generate_sample_data() {
    local count="${1:-10}"
    
    print_status "HEADER" "🎲 Generating Sample Data ($count records)"
    
    ensure_seed_dir
    
    local sample_file="$SEED_DIR/sample_data_$(date +%Y%m%d_%H%M%S).sql"
    
    cat > "$sample_file" << EOF
-- Sample Data Generation
-- Created: $(date)
-- Environment: $ENVIRONMENT
-- Record count: $count

BEGIN;

-- Sample users
INSERT INTO users (username, email, password_hash, created_at, updated_at) VALUES
EOF
    
    # Generate sample user data
    for i in $(seq 1 "$count"); do
        local username="user$i"
        local email="user$i@example.com"
        local password_hash='$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi'  # password
        
        if [ "$i" -eq "$count" ]; then
            echo "('$username', '$email', '$password_hash', NOW(), NOW());" >> "$sample_file"
        else
            echo "('$username', '$email', '$password_hash', NOW(), NOW())," >> "$sample_file"
        fi
    done
    
    cat >> "$sample_file" << EOF

-- Sample posts (if posts table exists)
-- INSERT INTO posts (title, content, user_id, created_at, updated_at) VALUES
-- ('Sample Post 1', 'This is a sample post content.', 1, NOW(), NOW()),
-- ('Sample Post 2', 'Another sample post for testing.', 2, NOW(), NOW());

-- Sample settings
INSERT INTO settings (key, value, description, created_at, updated_at) VALUES
('sample_data_generated', 'true', 'Indicates sample data has been generated', NOW(), NOW()),
('total_users', '$count', 'Total number of sample users', NOW(), NOW()),
('last_seed_run', '$(date)', 'Last time seed data was generated', NOW(), NOW())
ON CONFLICT (key) DO UPDATE SET
    value = EXCLUDED.value,
    updated_at = EXCLUDED.updated_at;

COMMIT;
EOF
    
    print_status "SUCCESS" "Created sample data file: $sample_file"
    print_status "INFO" "To apply this data, run: $0 run $(basename "$sample_file")"
}

# Function to show seed status
show_status() {
    print_status "HEADER" "📊 Seed Status"
    
    ensure_seed_dir
    
    print_status "INFO" "Seed directory: $SEED_DIR"
    print_status "INFO" "Environment file: $ENV_FILE"
    print_status "INFO" "Environment name: $ENVIRONMENT"
    print_status "INFO" "Dry run: $DRY_RUN"
    print_status "INFO" "Verbose: $VERBOSE"
    print_status "INFO" "Batch size: $BATCH_SIZE"
    
    # Show database connection
    local db_url=$(get_db_url)
    if [ $? -eq 0 ]; then
        print_status "INFO" "Database URL: ${db_url:0:50}..."
    fi
    
    # Count seed files
    local seed_files=$(find "$SEED_DIR" -name "*.sql" 2>/dev/null | wc -l)
    print_status "INFO" "Seed files: $seed_files"
    
    if [ "$seed_files" -gt 0 ]; then
        print_status "INFO" "Recent seeds:"
        find "$SEED_DIR" -name "*.sql" -type f -exec basename {} \; | sort -r | head -5 | while read -r file; do
            echo "  $file"
        done
    fi
}

# Function to validate seeds
validate_seeds() {
    print_status "HEADER" "🔍 Validating Seeds"
    
    ensure_seed_dir
    
    local errors=0
    
    # Check for SQL syntax errors (basic check)
    find "$SEED_DIR" -name "*.sql" -type f | while read -r sql_file; do
        local basename=$(basename "$sql_file")
        
        if grep -q "BEGIN;" "$sql_file" && ! grep -q "COMMIT;" "$sql_file"; then
            print_status "ERROR" "Missing COMMIT in: $basename"
            errors=$((errors + 1))
        fi
        
        # Check for common issues
        if grep -qi "drop.*table" "$sql_file"; then
            print_status "WARNING" "DROP TABLE found in: $basename (be careful!)"
        fi
        
        if grep -qi "delete.*from" "$sql_file" && ! grep -qi "where" "$sql_file"; then
            print_status "WARNING" "DELETE without WHERE in: $basename (dangerous!)"
        fi
    done
    
    if [ "$errors" -eq 0 ]; then
        print_status "SUCCESS" "All seeds are valid"
    else
        print_status "ERROR" "Found $errors validation error(s)"
    fi
}

# Function to show help
show_help() {
    print_color "$CYAN" "📋 Database Seeding Script"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  help                    Show this help message"
    echo "  status                  Show seed status"
    echo "  create <description>    Create new seed file"
    echo "  list                    List available seeds"
    echo "  run [pattern]           Run seed files (default: all)"
    echo "  clear [pattern]         Clear data from tables"
    echo "  generate [count]        Generate sample data"
    echo "  validate                Validate seed files"
    echo ""
    echo "Options:"
    echo "  --dir <path>            Seed directory (default: ./sql/seeds)"
    echo "  --env <file>            Environment file (default: .env)"
    echo "  --env-name <name>       Environment name (default: development)"
    echo "  --dry-run               Show what would be done without executing"
    echo "  --verbose               Show detailed output"
    echo "  --batch-size <number>   Number of seeds to run in batch"
    echo ""
    echo "Examples:"
    echo "  $0 create \"Initial admin user\""
    echo "  $0 run --dry-run"
    echo "  $0 run \"*user*\" --verbose"
    echo "  $0 clear \"test_*\""
    echo "  $0 generate 50"
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
        create_seed "$1"
        ;;
    "list")
        list_seeds
        ;;
    "run")
        run_seeds "${1:-*.sql}"
        ;;
    "clear")
        clear_data "${1:-*}"
        ;;
    "generate")
        generate_sample_data "${1:-10}"
        ;;
    "validate")
        validate_seeds
        ;;
    *)
        print_status "ERROR" "Unknown command: $COMMAND"
        echo ""
        show_help
        exit 1
        ;;
esac