#!/bin/bash

set -e

echo "Building Go/Fiber application..."

# Clean previous builds
echo "Cleaning previous builds..."
rm -rf ./build ./dist

# Create build directory
mkdir -p ./build

# Generate templ templates
echo "Generating templ templates..."
if command -v templ &> /dev/null; then
    templ generate
else
    echo "Warning: templ command not found, skipping template generation"
fi

# Run tests
echo "Running tests..."
go test ./...

# Build the application
echo "Building application..."
go build -o ./build/main ./main.go

echo "Build completed successfully!"
echo "Binary location: ./build/main"
