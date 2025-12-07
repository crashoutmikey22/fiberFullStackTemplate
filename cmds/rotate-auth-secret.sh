#!/bin/bash

set -e

# Auth Secret Rotation Script
# Usage: ./cmds/rotate-auth-secret.sh [--backup] [--env-file .env]

# Default values
ENV_FILE=".env"
BACKUP=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --backup)
            BACKUP=true
            shift
            ;;
        --env-file)
            ENV_FILE="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [--backup] [--env-file .env]"
            echo ""
            echo "Options:"
            echo "  --backup        Create backup of current .env file"
            echo "  --env-file      Specify custom .env file path (default: .env)"
            echo "  -h, --help      Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use '$0 --help' for usage information"
            exit 1
            ;;
    esac
done

# Check if .env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: .env file not found at $ENV_FILE"
    echo "Please ensure the .env file exists or specify the correct path with --env-file"
    exit 1
fi

# Function to generate secure random string
generate_secret() {
    # Generate a 64-character random string using base64
    openssl rand -base64 48 | tr -d "=+/" | cut -c1-64
}

# Function to backup .env file
backup_env() {
    local backup_file="${ENV_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$ENV_FILE" "$backup_file"
    echo "✅ Backup created: $backup_file"
}

# Function to extract current auth secret
get_current_secret() {
    grep "^AUTH_SECRET=" "$ENV_FILE" | cut -d'=' -f2 | cut -d' ' -f1
}

# Function to update auth secret in .env file
update_secret() {
    local new_secret="$1"
    local temp_file=$(mktemp)
    
    # Replace the AUTH_SECRET line while preserving comments
    awk -v new_secret="$new_secret" '
    /^AUTH_SECRET=/ {
        # Find the comment part (everything after the first space)
        comment = ""
        for (i=2; i<=NF; i++) {
            if (i > 2) comment = comment " "
            comment = comment $i
        }
        # Print the new secret line with original comment
        print "AUTH_SECRET=" new_secret " " comment
        next
    }
    { print }
    ' "$ENV_FILE" > "$temp_file"
    
    # Replace the original file
    mv "$temp_file" "$ENV_FILE"
}

echo "🔐 Auth Secret Rotation Script"
echo "==============================="

# Check if AUTH_SECRET exists in .env file
if ! grep -q "^AUTH_SECRET=" "$ENV_FILE"; then
    echo "❌ Error: AUTH_SECRET not found in $ENV_FILE"
    echo "Please ensure AUTH_SECRET is defined in your .env file"
    exit 1
fi

# Get current secret
CURRENT_SECRET=$(get_current_secret)
if [ -z "$CURRENT_SECRET" ]; then
    echo "❌ Error: AUTH_SECRET is empty in $ENV_FILE"
    exit 1
fi

echo "📋 Current setup:"
echo "   Environment file: $ENV_FILE"
echo "   Current secret: ${CURRENT_SECRET:0:20}..."
echo ""

# Create backup if requested
if [ "$BACKUP" = true ]; then
    backup_env
    echo ""
fi

# Generate new secret
echo "🔄 Generating new auth secret..."
NEW_SECRET=$(generate_secret)
echo "✅ New secret generated: ${NEW_SECRET:0:20}..."
echo ""

# Update the .env file
echo "📝 Updating $ENV_FILE..."
update_secret "$NEW_SECRET"
echo "✅ Auth secret rotated successfully!"
echo ""

# Instructions for next steps
echo "📋 Next Steps:"
echo "1. Update any services that use the old auth secret"
echo "2. Test your application to ensure it works with the new secret"
echo "3. If using sessions, existing user sessions will be invalidated"
echo "4. If using JWTs, existing tokens will be invalidated"
echo "5. Update any deployment environments with the new secret"
echo ""

# Show the new secret (for manual copying if needed)
echo "🔑 New AUTH_SECRET for manual configuration:"
echo "AUTH_SECRET=$NEW_SECRET"
echo ""

echo "⚠️  IMPORTANT SECURITY NOTES:"
echo "- Store the new secret securely"
echo "- Update all deployment environments"
echo "- Consider using environment-specific secrets"
echo "- Rotate secrets regularly (every 90 days recommended)"
echo "- Never commit secrets to version control"

# Optional: Generate a secure secret using different methods
echo ""
echo "🔧 Alternative secret generation methods:"
echo "If you prefer different secret formats:"
echo "  32 chars: $(openssl rand -base64 32 | tr -d \"=+/\")"
echo "  UUID: $(uuidgen)"
echo "  Hex: $(openssl rand -hex 32)"