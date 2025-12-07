# Fiber Full Stack Template

(vibe coded -- sorry pureists)
A production-ready Fiber web application template with environment-driven feature flags. Toggle databases, caching, authentication, mail services, AWS integrations, and realtime features directly through environment variables—no code changes required.

## 🚀 Features

### ✅ Core Architecture
- **Environment-Driven Configuration** - Feature toggles via `FEATURE_*` environment variables
- **Multi-Stage Docker Support** - Optimized builds using `golang:1.25-alpine`
- **Graceful Shutdown** - Proper signal handling and resource cleanup
- **Structured Logging** - Zap-based logging with environment-specific configurations
- **Health Monitoring** - Comprehensive health, readiness, and liveness endpoints

### ✅ Feature Toggle System
Toggle optional subsystems without code modifications:
- **Database** - PostgreSQL with SQLC type-safe queries
- **Cache** - Redis/Valkey integration
- **Auth** - Session-based or JWT authentication
- **Mail** - SMTP/Mailpit email services
- **AWS** - S3 storage and IAM credentials
- **Pusher** - Realtime websocket communications

### ✅ Web Framework & Middleware
- **Fiber Framework** - High-performance Go web framework
- **Recovery Middleware** - Panic recovery and error handling
- **CORS Support** - Configurable cross-origin resource sharing
- **Compression** - Response compression with configurable levels
- **Request ID** - Automatic request tracking and correlation
- **Favicon Serving** - Static favicon handling

### ✅ Database & ORM
- **PostgreSQL Integration** - Complete database support when enabled
- **SQLC Integration** - Type-safe database query generation
- **Connection Pooling** - Configurable database connections
- **Migration Support** - Schema management and updates
- **User Management** - Complete user authentication schema

### ✅ Frontend & Templates
- **Templ Integration** - Type-safe HTML templating
- **Tailwind CSS** - Utility-first CSS framework
- **Status Dashboard** - Interactive feature matrix display
- **Responsive Design** - Mobile-first responsive layouts

## 📁 Project Structure

```
├── internal/
│   ├── config/          # Environment configuration & feature flags
│   ├── database/        # PostgreSQL connection & SQLC integration
│   ├── handlers/        # HTTP request handlers & routing
│   ├── logger/          # Zap structured logging
│   ├── middleware/      # Custom middleware (CORS, compression, etc.)
│   ├── models/          # Data models (commented examples)
│   ├── templates/       # Templ HTML templates & components
│   └── utils/           # Response utilities & helpers
├── sql/
│   ├── schema.sql       # PostgreSQL database schema
│   └── queries.sql      # SQLC query definitions
├── statics/             # Static assets (favicon, CSS, JS)
├── cmds/                # Utility scripts & commands
├── Dockerfile           # Multi-stage Docker configuration
├── docker-compose.yml   # Docker Compose setup
├── Makefile            # Development automation
└── main.go             # Application entry point
```

## 🏃‍♂️ Quick Start

### Prerequisites
- Go 1.25.5 or later
- Docker & Docker Compose (for containerized deployment)
- PostgreSQL (only if `FEATURE_DATABASE=true`)
- Redis (only if `FEATURE_CACHE=true`)

### 1. Environment Setup
```bash
# Clone and setup
git clone <your-repo-url>
cd fiberFullStackTemplate

# Copy environment configuration
cp .env.example .env

# Edit configuration as needed
nano .env
```

### 2. Local Development
```bash
# Install dependencies
go mod tidy

# Run development server
go run main.go

# Or use the build script
./cmds/build.sh
./cmds/run.sh
```

### 3. Docker Deployment (Recommended)

#### Using Docker Compose
```bash
# Build and start application
docker-compose up --build

# Run in detached mode
docker-compose up -d --build

# View logs
docker-compose logs -f app

# Stop application
docker-compose down
```

#### Using Docker CLI
```bash
# Build image
docker build -t fiber-app .

# Run container
docker run -p 8080:8080 --env-file .env fiber-app
```

#### Using Makefile
```bash
# Docker operations
make docker-compose    # Start with docker-compose
make docker-build      # Build Docker image
make docker-run        # Run container
make docker-logs       # View logs
make docker-clean      # Clean up

# Local development
make build            # Build Go application
make run              # Run locally
make test             # Run tests
make clean            # Clean artifacts
```

The application will be available at `http://localhost:8080`

## ⚙️ Configuration

### Feature Toggle System
Control optional subsystems through environment variables:

```env
# Enable/disable features (default: all false)
FEATURE_DATABASE=true   # PostgreSQL + SQLC
FEATURE_CACHE=true      # Redis integration
FEATURE_AUTH=true       # Authentication system
FEATURE_MAIL=true       # Email services
FEATURE_AWS=true        # AWS integrations
FEATURE_PUSHER=true     # Realtime features
```

### Server Configuration
```env
PORT=8080              # Server port
HOST=localhost         # Server host
APP_ENV=development    # Environment mode
APP_URL=http://localhost:8080
APP_NAME="FiberTemplate"
```

### Middleware Configuration
```env
CORS=true              # Enable CORS
COMPRESS=true          # Enable compression
COMPRESS_LEVEL=0       # Compression level (0=balanced, 1=fast, 2=best)
```

### Database Configuration
```env
# PostgreSQL (requires FEATURE_DATABASE=true)
DB_URL=postgres://user:password@localhost:5432/dbname
```

### Authentication
```env
# Auth system (requires FEATURE_AUTH=true)
AUTH=JWT               # Options: Disabled, Sessions, JWT
AUTH_SECRET=your-secret-key

# Session configuration
SESSION_HTTPONLY=true
SESSION_SAMESITE=lax
SESSION_EXPIRE=24h

# JWT configuration
JWT_EXPIRE=24h
JWT_REFRESH_EXPIRE=7d
```

### Redis Configuration
```env
# Redis (requires FEATURE_CACHE=true)
REDIS_HOST=localhost
REDIS_PASSWORD=
REDIS_PORT=6379
```

### Email Configuration
```env
# Email (requires FEATURE_MAIL=true)
MAIL_MAILER=smtp
MAIL_HOST=mailpit
MAIL_PORT=1025
MAIL_USERNAME=
MAIL_PASSWORD=
MAIL_ENCRYPTION=
MAIL_FROM_ADDRESS="hello@example.com"
MAIL_FROM_NAME="${APP_NAME}"
```

### AWS Configuration
```env
# AWS (requires FEATURE_AWS=true)
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_DEFAULT_REGION=us-east-1
AWS_BUCKET=
```

### Pusher Configuration
```env
# Pusher (requires FEATURE_PUSHER=true)
PUSHER_APP_ID=
PUSHER_APP_KEY=
PUSHER_APP_SECRET=
PUSHER_APP_CLUSTER=mt1
```

## 🌐 API Endpoints

### Health Checks
- `GET /health` - Basic health check
- `GET /ready` - Readiness probe (database connectivity)
- `GET /live` - Liveness probe (application status)

### Application Routes
- `GET /` - Status dashboard (HTML)
- `GET /api/v1/` - API welcome message (JSON)
- `GET /api/v1/status` - Feature matrix and system status (JSON)

### Static Files
- `GET /static/*` - Serve static assets from `./statics`
- `GET /favicon.ico` - Application favicon

## 🛠️ Development

### Adding New Features
1. **Create feature flag** in `internal/config/env.go`
2. **Add handler logic** in `internal/handlers/`
3. **Update routes** in `main.go`
4. **Configure environment** in `.env.example`

### Database Operations
```bash
# Generate SQLC code
sqlc generate

# Run database migrations
psql your_database < sql/schema.sql

# Use generated queries
# See sql/queries.sql for available operations
```

### Template Development
```bash
# Generate Templ templates
templ generate

# Watch for changes during development
templ generate -watch
```

### Middleware Development
- Add custom middleware in `internal/middleware/`
- Use environment-based configuration for feature toggles
- Follow the existing pattern for consistency

## 🐳 Docker Configuration

### Multi-Stage Build
The Dockerfile uses a two-stage build process:
1. **Builder Stage** - Compiles Go application with dependencies
2. **Runtime Stage** - Minimal Alpine Linux container

### Environment Variables in Docker
```bash
# Set via docker-compose.yml
environment:
  - FEATURE_DATABASE=true
  - PORT=8080
  - APP_ENV=production

# Or via command line
docker run -e FEATURE_DATABASE=true -e PORT=8080 fiber-app
```

### Production Deployment
```bash
# Scale application
docker-compose up -d --scale app=3

# Monitor health
docker-compose ps
docker-compose logs -f --tail=100 app

# Update application
docker-compose pull
docker-compose up -d --build
```

## 🧪 Testing

```bash
# Run all tests
go test ./...

# Run tests with coverage
go test -cover ./...

# Run specific package tests
go test ./internal/handlers/
go test ./internal/config/
```

## 📊 Monitoring & Observability

### Health Checks
The application provides three levels of health monitoring:
- **Health** (`/health`) - Basic application status
- **Ready** (`/ready`) - Dependency readiness (database, cache)
- **Live** (`/live`) - Liveness probe for load balancers

### Logging
- **Structured logging** with Zap
- **Environment-specific** log levels
- **Request correlation** via X-Request-ID
- **JSON format** for log aggregation

### Feature Matrix
Access `/api/v1/status` for real-time feature status:
```json
{
  "features": {
    "database": true,
    "cache": false,
    "auth": true,
    "mail": false,
    "aws": false,
    "pusher": false
  }
}
```

## 🚀 Production Deployment

### Environment Setup
```env
APP_ENV=production
CORS=false                    # Configure for your domain
COMPRESS=true
COMPRESS_LEVEL=2             # Maximum compression
```

### Security Considerations
- Use strong `AUTH_SECRET` keys
- Enable HTTPS in production
- Configure CORS properly for your domain
- Set secure session cookies
- Use connection pooling for database
- Monitor health endpoints

### Performance Optimization
- Enable response compression
- Use connection pooling
- Configure appropriate timeouts
- Monitor memory usage
- Scale horizontally with load balancer

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow Go best practices
- Add tests for new features
- Update documentation
- Use feature flags for optional functionality
- Maintain backward compatibility

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For issues and questions:
1. Check existing [GitHub Issues](../../issues)
2. Create a new issue with detailed information
3. Include environment details and error messages
4. Provide steps to reproduce the problem

---

**Built with ❤️ using Fiber, Go, and modern web technologies**