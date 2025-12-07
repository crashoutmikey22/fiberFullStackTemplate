# Management Scripts

This directory contains comprehensive scripts for managing your Go/Fiber application across development, security, database, and operational needs.

## Available Scripts

### 🔐 Security Management

#### `security.sh` - Security Scanning & Analysis
Comprehensive security scanning for your application:

```bash
# Basic security scan
./cmds/security.sh

# Full comprehensive scan
./cmds/security.sh --full

# Auto-fix issues where possible
./cmds/security.sh --fix

# Generate detailed security report
./cmds/security.sh --report
```

**Features:**
- Go security analysis (go vet, gosec)
- Dependency vulnerability scanning (nancy)
- Secret detection (TruffleHog, GitLeaks)
- Code quality analysis (golangci-lint)
- Container security (Hadolint, Docker Scout)
- File permission checks
- Git security analysis

### 📊 Log Management

#### `logs.sh` - Log System Management
Complete log management and analysis:

```bash
# Show application logs
./cmds/logs.sh show app

# Follow logs in real-time
./cmds/logs.sh follow error

# Search logs for patterns
./cmds/logs.sh search "ERROR" app

# Analyze log patterns
./cmds/logs.sh analyze

# Rotate and clean logs
./cmds/logs.sh rotate
./cmds/logs.sh clean

# Setup logging configuration
./cmds/logs.sh setup
```

**Features:**
- Log viewing and filtering
- Real-time log following
- Pattern searching and analysis
- Log rotation and compression
- Export functionality
- Disk usage monitoring
- Systemd service integration

### 🗄️ Database Management

#### `migrate.sh` - Database Migration System
Version-controlled database schema changes:

```bash
# Create new migration
./cmds/migrate.sh create "Add user table"

# Run pending migrations
./cmds/migrate.sh up

# Rollback migrations
./cmds/migrate.sh down 2

# Dry run (preview changes)
./cmds/migrate.sh up --dry-run

# Validate migration files
./cmds/migrate.sh validate
```

**Features:**
- Up/down migration pairs
- SQLite and PostgreSQL support
- Dry-run mode for safety
- Batch processing
- Migration validation
- Environment-specific configurations

#### `seed.sh` - Database Seeding System
Populate databases with initial or test data:

```bash
# Create seed file
./cmds/seed.sh create "Initial admin user"

# Run all seeds
./cmds/seed.sh run

# Run specific seeds
./cmds/seed.sh run "*user*"

# Generate sample data
./cmds/seed.sh generate 50

# Clear test data
./cmds/seed.sh clear "test_*"
```

**Features:**
- SQL-based seed files
- Sample data generation
- Environment-specific seeding
- Data clearing with safety checks
- Batch processing
- Seed validation

### 🔑 Authentication Management

#### `rotate-auth-secret.sh` - Auth Secret Rotation
Securely rotate authentication secrets:

```bash
# Basic rotation
./cmds/rotate-auth-secret.sh

# With backup
./cmds/rotate-auth-secret.sh --backup

# Custom environment file
./cmds/rotate-auth-secret.sh --env-file .env.production
```

**Features:**
- Secure secret generation (64-character random)
- Automatic backups with timestamps
- Comment preservation in .env files
- Multiple secret format support
- Safety warnings and instructions

## Original Scripts

### `build.sh` - Application Building
Build and test your Go/Fiber application:

```bash
./cmds/build.sh
```

### `run.sh` - Application Execution
Run your application in different modes:

```bash
# Development mode (with hot reload)
./cmds/run.sh dev

# Production mode
./cmds/run.sh prod

# Run tests
./cmds/run.sh test

# Run linter
./cmds/run.sh lint
```

### `templ.sh` - Template Generation
Generate and run templ templates:

```bash
./cmds/templ.sh
```

## Security Best Practices

### Secret Management
- **Rotate regularly**: Change secrets every 90 days
- **Backup first**: Always create backups before rotation
- **Update deployments**: Ensure all environments use new secrets
- **Test after rotation**: Verify application works with new secrets
- **Never commit secrets**: Keep `.env` files out of version control

### Database Operations
- **Use dry-run**: Always test migrations with `--dry-run` first
- **Backup databases**: Create backups before major changes
- **Version control**: Keep migration files in git
- **Environment separation**: Use different seeds for dev/staging/prod

### Log Management
- **Regular rotation**: Prevent log files from consuming disk space
- **Monitor disk usage**: Use `./cmds/logs.sh status` to check usage
- **Secure log files**: Ensure proper permissions on log directories
- **Log analysis**: Regular analysis helps identify issues early

### Security Scanning
- **Regular scans**: Run security scans weekly or monthly
- **Fix issues promptly**: Address security warnings immediately
- **Keep tools updated**: Ensure security tools are current
- **Integrate in CI/CD**: Add security checks to your pipeline

## Integration Examples

### CI/CD Pipeline
```yaml
# GitHub Actions example
- name: Security Scan
  run: ./cmds/security.sh --full --report

- name: Database Migration
  run: ./cmds/migrate.sh up --env .env.production

- name: Log Analysis
  run: ./cmds/logs.sh analyze
```

### Development Workflow
```bash
# Daily development routine
./cmds/security.sh --fix          # Quick security check
./cmds/logs.sh clean              # Clean old logs
./cmds/migrate.sh status          # Check migration status
./cmds/seed.sh run --dry-run      # Preview seed changes
```

### Production Deployment
```bash
# Pre-deployment checklist
./cmds/rotate-auth-secret.sh --backup    # Backup current secrets
./cmds/migrate.sh up --dry-run          # Preview migrations
./cmds/security.sh --full               # Full security scan
./cmds/logs.sh status                   # Check log system
```

## Environment Configuration

All scripts support environment-specific configuration through:
- Custom `.env` files (`--env` flag)
- Environment names (`--env-name` flag)
- Custom directories (`--dir` flag)
- Verbose output (`--verbose` flag)
- Dry-run mode (`--dry-run` flag)

## Monitoring and Alerts

Consider setting up monitoring for:
- Secret rotation attempts
- Security scan failures
- Database migration errors
- Log system issues
- Disk space usage
- Failed authentication attempts

## Troubleshooting

### Common Issues
1. **Permission errors**: Ensure scripts are executable (`chmod +x`)
2. **Missing dependencies**: Install required tools (gosec, golangci-lint, etc.)
3. **Database connection**: Verify `.env` file has correct `DB_URL`
4. **Log directory**: Create `./logs` directory if it doesn't exist

### Getting Help
All scripts include built-in help:
```bash
./cmds/script-name --help
```

### Debug Mode
Enable verbose output for detailed information:
```bash
./cmds/script-name --verbose
```