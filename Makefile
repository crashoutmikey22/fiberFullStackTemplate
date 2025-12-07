# Go Fiber Full Stack Template - Docker Makefile

.PHONY: help build run stop logs clean docker-build docker-run docker-stop docker-logs docker-clean

# Default target
help:
	@echo "Available targets:"
	@echo "  docker-build    - Build Docker image"
	@echo "  docker-run      - Run Docker container"
	@echo "  docker-stop     - Stop Docker container"
	@echo "  docker-logs     - Show Docker container logs"
	@echo "  docker-clean    - Remove Docker image"
	@echo "  docker-compose  - Run with docker-compose"
	@echo "  build          - Build Go application"
	@echo "  run            - Run Go application locally"
	@echo "  test           - Run tests"
	@echo "  clean          - Clean build artifacts"

# Docker targets
docker-build:
	@echo "Building Docker image..."
	docker build -t fiber-app .

docker-run:
	@echo "Running Docker container..."
	docker run -p 8080:8080 --env-file .env fiber-app

docker-stop:
	@echo "Stopping Docker container..."
	docker stop $$(docker ps -q --filter ancestor=fiber-app) || true

docker-logs:
	@echo "Showing Docker logs..."
	docker logs -f $$(docker ps -q --filter ancestor=fiber-app) || echo "No running container found"

docker-clean:
	@echo "Removing Docker image..."
	docker rmi fiber-app || true

docker-compose:
	@echo "Running with docker-compose..."
	docker-compose up --build

docker-compose-detached:
	@echo "Running with docker-compose in detached mode..."
	docker-compose up -d --build

docker-compose-logs:
	@echo "Showing docker-compose logs..."
	docker-compose logs -f

docker-compose-down:
	@echo "Stopping docker-compose..."
	docker-compose down

# Local development targets
build:
	@echo "Building Go application..."
	./cmds/build.sh

run:
	@echo "Running Go application..."
	go run main.go

test:
	@echo "Running tests..."
	go test ./...

clean:
	@echo "Cleaning build artifacts..."
	rm -rf ./build ./dist
	docker system prune -f

# Development workflow
dev: build run

# Production deployment
prod: docker-compose-detached
	@echo "Application started in production mode"
	@echo "Access the application at http://localhost:8080"

# Quick start for new developers
setup:
	@echo "Setting up development environment..."
	cp .env.example .env
	go mod tidy
	@echo "Environment setup complete. Edit .env file as needed."