#!/bin/bash

set -e

# Log Management Script
# Usage: ./cmds/logs.sh [command] [options]

# Default values
LOG_DIR="./logs"
APP_NAME="fiber-app"
MAX_SIZE="100M"
RETENTION_DAYS=30
TAIL_LINES=100

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
        --log-dir)
            LOG_DIR="$2"
            shift 2
            ;;
        --app-name)
            APP_NAME="$2"
            shift 2
            ;;
        --max-size)
            MAX_SIZE="$2"
            shift 2
            ;;
        --retention)
            RETENTION_DAYS="$2"
            shift 2
            ;;
        --lines)
            TAIL_LINES="$2"
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

# Function to ensure log directory exists
ensure_log_dir() {
    if [ ! -d "$LOG_DIR" ]; then
        mkdir -p "$LOG_DIR"
        print_status "INFO" "Created log directory: $LOG_DIR"
    fi
}

# Function to get log file path
get_log_file() {
    local log_type=$1
    local date_suffix=$(date +%Y%m%d)
    echo "$LOG_DIR/${APP_NAME}-${log_type}-${date_suffix}.log"
}

# Function to rotate logs
rotate_logs() {
    print_status "HEADER" "🔄 Log Rotation"
    
    ensure_log_dir
    
    # Find and compress old logs
    find "$LOG_DIR" -name "${APP_NAME}-*.log" -type f -mtime +1 | while read -r logfile; do
        if [[ ! "$logfile" =~ \.gz$ ]]; then
            gzip "$logfile"
            print_status "SUCCESS" "Compressed: $(basename "$logfile")"
        fi
    done
    
    # Remove old logs based on retention policy
    find "$LOG_DIR" -name "${APP_NAME}-*.log.gz" -type f -mtime +$RETENTION_DAYS | while read -r logfile; do
        rm "$logfile"
        print_status "SUCCESS" "Deleted old log: $(basename "$logfile")"
    done
}

# Function to clean logs
clean_logs() {
    print_status "HEADER" "🧹 Log Cleanup"
    
    ensure_log_dir
    
    # Clean empty log files
    find "$LOG_DIR" -name "${APP_NAME}-*.log" -type f -size 0 -delete
    print_status "SUCCESS" "Removed empty log files"
    
    # Clean old compressed logs
    find "$LOG_DIR" -name "${APP_NAME}-*.log.gz" -type f -mtime +$RETENTION_DAYS -delete
    print_status "SUCCESS" "Removed logs older than $RETENTION_DAYS days"
    
    # Show disk usage
    local total_size=$(du -sh "$LOG_DIR" 2>/dev/null | cut -f1)
    print_status "INFO" "Total log directory size: $total_size"
}

# Function to show logs
show_logs() {
    local log_type=${1:-"app"}
    local lines=${2:-$TAIL_LINES}
    
    print_status "HEADER" "📋 Showing $log_type logs (last $lines lines)"
    
    ensure_log_dir
    
    local log_file=$(get_log_file "$log_type")
    
    if [ -f "$log_file" ]; then
        if command_exists "less"; then
            tail -n "$lines" "$log_file" | less -R
        else
            tail -n "$lines" "$log_file"
        fi
    else
        print_status "WARNING" "Log file not found: $log_file"
        print_status "INFO" "Available log files:"
        ls -la "$LOG_DIR" 2>/dev/null || print_status "INFO" "No log files found"
    fi
}

# Function to follow logs
follow_logs() {
    local log_type=${1:-"app"}
    
    print_status "HEADER" "👀 Following $log_type logs (Ctrl+C to stop)"
    
    ensure_log_dir
    
    local log_file=$(get_log_file "$log_type")
    
    if [ -f "$log_file" ]; then
        if command_exists "tail"; then
            tail -f "$log_file"
        else
            print_status "ERROR" "tail command not available"
        fi
    else
        print_status "WARNING" "Log file not found: $log_file"
        print_status "INFO" "Creating new log file..."
        touch "$log_file"
        tail -f "$log_file"
    fi
}

# Function to search logs
search_logs() {
    local pattern=${1:-""}
    local log_type=${2:-"app"}
    
    if [ -z "$pattern" ]; then
        print_status "ERROR" "Search pattern required"
        echo "Usage: $0 search <pattern> [log-type]"
        exit 1
    fi
    
    print_status "HEADER" "🔍 Searching $log_type logs for: $pattern"
    
    ensure_log_dir
    
    local log_file=$(get_log_file "$log_type")
    
    if [ -f "$log_file" ]; then
        if command_exists "grep"; then
            grep -n --color=always "$pattern" "$log_file"
        else
            grep "$pattern" "$log_file"
        fi
    else
        print_status "WARNING" "Log file not found: $log_file"
    fi
}

# Function to analyze logs
analyze_logs() {
    local log_type=${1:-"app"}
    
    print_status "HEADER" "📊 Analyzing $log_type logs"
    
    ensure_log_dir
    
    local log_file=$(get_log_file "$log_type")
    
    if [ ! -f "$log_file" ]; then
        print_status "WARNING" "Log file not found: $log_file"
        return 1
    fi
    
    # Count total lines
    local total_lines=$(wc -l < "$log_file")
    print_status "INFO" "Total lines: $total_lines"
    
    # Count errors (if applicable)
    if grep -q "ERROR\|error\|Error" "$log_file" 2>/dev/null; then
        local error_count=$(grep -c "ERROR\|error\|Error" "$log_file" 2>/dev/null || echo "0")
        print_status "WARNING" "Error count: $error_count"
    fi
    
    # Count warnings
    if grep -q "WARN\|warn\|Warning" "$log_file" 2>/dev/null; then
        local warn_count=$(grep -c "WARN\|warn\|Warning" "$log_file" 2>/dev/null || echo "0")
        print_status "WARNING" "Warning count: $warn_count"
    fi
    
    # Show log levels distribution
    if command_exists "awk"; then
        print_status "INFO" "Log level distribution:"
        awk '
        /DEBUG/ { debug++ }
        /INFO/ { info++ }
        /WARN/ { warn++ }
        /ERROR/ { error++ }
        /FATAL/ { fatal++ }
        END {
            print "  DEBUG: " (debug+0)
            print "  INFO:  " (info+0)
            print "  WARN:  " (warn+0)
            print "  ERROR: " (error+0)
            print "  FATAL: " (fatal+0)
        }
        ' "$log_file"
    fi
    
    # Show recent activity
    print_status "INFO" "Recent activity (last 10 lines):"
    tail -n 10 "$log_file" | while read -r line; do
        echo "  $line"
    done
}

# Function to export logs
export_logs() {
    local log_type=${1:-"app"}
    local output_file=${2:-"${APP_NAME}-${log_type}-export-$(date +%Y%m%d_%H%M%S).log"}
    
    print_status "HEADER" "📤 Exporting $log_type logs"
    
    ensure_log_dir
    
    local log_file=$(get_log_file "$log_type")
    
    if [ -f "$log_file" ]; then
        cp "$log_file" "$output_file"
        print_status "SUCCESS" "Logs exported to: $output_file"
        
        # Show file size
        local file_size=$(du -h "$output_file" | cut -f1)
        print_status "INFO" "Export file size: $file_size"
    else
        print_status "ERROR" "Log file not found: $log_file"
    fi
}

# Function to show log status
show_status() {
    print_status "HEADER" "📊 Log System Status"
    
    ensure_log_dir
    
    print_status "INFO" "Log directory: $LOG_DIR"
    print_status "INFO" "App name: $APP_NAME"
    print_status "INFO" "Retention days: $RETENTION_DAYS"
    print_status "INFO" "Max size: $MAX_SIZE"
    
    if [ -d "$LOG_DIR" ]; then
        local file_count=$(find "$LOG_DIR" -name "${APP_NAME}-*.log*" | wc -l)
        print_status "INFO" "Total log files: $file_count"
        
        if [ "$file_count" -gt 0 ]; then
            print_status "INFO" "Log files:"
            ls -la "$LOG_DIR" | grep "${APP_NAME}" | while read -r line; do
                echo "  $line"
            done
        fi
    else
        print_status "WARNING" "Log directory does not exist"
    fi
}

# Function to setup logging
setup_logging() {
    print_status "HEADER" "⚙️  Setting up logging system"
    
    ensure_log_dir
    
    # Create sample log configuration
    cat > "$LOG_DIR/log-config.conf" << EOF
# Log Configuration for $APP_NAME
LOG_DIR=$LOG_DIR
APP_NAME=$APP_NAME
MAX_SIZE=$MAX_SIZE
RETENTION_DAYS=$RETENTION_DAYS

# Log levels: DEBUG, INFO, WARN, ERROR, FATAL
LOG_LEVEL=INFO

# Log formats:
# - simple: Simple text format
# - json: JSON format for structured logging
# - detailed: Detailed format with timestamps
LOG_FORMAT=detailed

# Log rotation:
# - size: Rotate when file reaches max size
# - time: Rotate daily
# - both: Rotate by size and time
ROTATION_POLICY=size
EOF
    
    print_status "SUCCESS" "Log configuration created: $LOG_DIR/log-config.conf"
    
    # Create logrotate configuration
    cat > "$LOG_DIR/logrotate.conf" << EOF
$LOG_DIR/${APP_NAME}-*.log {
    daily
    missingok
    rotate $RETENTION_DAYS
    compress
    delaycompress
    notifempty
    create 644 $(whoami) $(whoami)
    postrotate
        # Add post-rotation commands here
        echo "Log rotation completed at \$(date)" >> $LOG_DIR/rotation.log
    endscript
}
EOF
    
    print_status "SUCCESS" "Logrotate configuration created: $LOG_DIR/logrotate.conf"
    
    # Create systemd service example (if systemd is available)
    if command_exists "systemctl"; then
        cat > "$LOG_DIR/${APP_NAME}.service" << EOF
[Unit]
Description=$APP_NAME Application
After=network.target

[Service]
Type=simple
User=$(whoami)
WorkingDirectory=$(pwd)
ExecStart=$(pwd)/build/main
Restart=always
RestartSec=5
StandardOutput=append:$LOG_DIR/${APP_NAME}-stdout.log
StandardError=append:$LOG_DIR/${APP_NAME}-stderr.log

[Install]
WantedBy=multi-user.target
EOF
        print_status "SUCCESS" "Systemd service example created: $LOG_DIR/${APP_NAME}.service"
    fi
}

# Function to show help
show_help() {
    print_color "$CYAN" "📋 Log Management Script"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  help                    Show this help message"
    echo "  status                  Show log system status"
    echo "  show [type] [lines]     Show logs (app, error, access)"
    echo "  follow [type]           Follow logs in real-time"
    echo "  search <pattern> [type] Search logs for pattern"
    echo "  analyze [type]          Analyze log patterns and statistics"
    echo "  export [type] [file]    Export logs to file"
    echo "  rotate                  Rotate and compress old logs"
    echo "  clean                   Clean old and empty log files"
    echo "  setup                   Setup logging configuration"
    echo ""
    echo "Options:"
    echo "  --log-dir <dir>         Log directory (default: ./logs)"
    echo "  --app-name <name>       Application name (default: fiber-app)"
    echo "  --max-size <size>       Maximum log size (default: 100M)"
    echo "  --retention <days>      Retention days (default: 30)"
    echo "  --lines <number>        Lines to show (default: 100)"
    echo ""
    echo "Examples:"
    echo "  $0 show app 50"
    echo "  $0 follow error"
    echo "  $0 search \"ERROR\" app"
    echo "  $0 analyze"
    echo "  $0 export app backup.log"
    echo "  $0 rotate --log-dir /var/log/myapp"
}

# Main command dispatcher
case $COMMAND in
    "help"|"-h"|"--help")
        show_help
        ;;
    "status")
        show_status
        ;;
    "show")
        show_logs "$1" "$2"
        ;;
    "follow")
        follow_logs "$1"
        ;;
    "search")
        search_logs "$1" "$2"
        ;;
    "analyze")
        analyze_logs "$1"
        ;;
    "export")
        export_logs "$1" "$2"
        ;;
    "rotate")
        rotate_logs
        ;;
    "clean")
        clean_logs
        ;;
    "setup")
        setup_logging
        ;;
    *)
        print_status "ERROR" "Unknown command: $COMMAND"
        echo ""
        show_help
        exit 1
        ;;
esac