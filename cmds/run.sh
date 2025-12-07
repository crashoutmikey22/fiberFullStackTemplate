#!/bin/bash

set -e

# Default to development mode
MODE=${1:-dev}

echo "Running Go/Fiber application in $MODE mode..."

# Function to check if binary exists
check_binary() {
    if [ ! -f "./build/main" ]; then
        echo "Binary not found. Building application..."
        ./cmds/build.sh
    fi
}

# Function to run in development mode with hot reload
run_dev() {
    echo "Starting in development mode..."
    
    # Check if air is installed for hot reload
    if command -v air &> /dev/null; then
        echo "Using air for hot reload..."
        air
    else
        echo "Air not found, running with go run..."
        go run ./main.go
    fi
}

# Function to run in production mode
run_prod() {
    echo "Starting in production mode..."
    check_binary
    ./build/main
}

# Function to run tests
run_test() {
    echo "Running tests..."
    go test ./...
}

# Function to run linting
run_lint() {
    echo "Running linter..."
    if command -v golangci-lint &> /dev/null; then
        golangci-lint run
    else
        echo "golangci-lint not found, running go vet..."
        go vet ./...
    fi
}

# Handle different modes
case $MODE in
    dev|development)
        run_dev
        ;;
    prod|production)
        run_prod
        ;;
    test)
        run_test
        ;;
    lint)
        run_lint
        ;;
    build)
        ./cmds/build.sh
        ;;
    help|--help|-h)
        echo "Usage: $0 [MODE]"
        echo ""
        echo "Modes:"
        echo "  dev, development  - Run in development mode (default)"
        echo "  prod, production  - Run in production mode"
        echo "  test              - Run tests"
        echo "  lint              - Run linter"
        echo "  build             - Build the application"
        echo "  help              - Show this help message"
        ;;
    *)
        echo "Unknown mode: $MODE"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac