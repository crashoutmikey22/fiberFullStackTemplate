#!/bin/bash

# Generate Go code from templ files
templ generate

# Format the generated Go code
gofmt -w .

# Run the Go application
go run .