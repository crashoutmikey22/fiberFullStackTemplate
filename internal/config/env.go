package config

import (
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/joho/godotenv"
)

// Config holds all application configuration
type Config struct {
	// Server
	Port    string
	Host    string
	AppEnv  string
	AppURL  string
	AppName string

	// Middleware
	CORS          bool
	Compress      bool
	CompressLevel int

	// Feature flags (component toggles)
	Features FeatureFlags

	// Database
	DBURL string

	// Authentication
	AuthType      string
	AuthSecret    string
	SessionConfig SessionConfig
	JWTConfig     JWTConfig

	// Redis
	RedisHost     string
	RedisPassword string
	RedisPort     string

	// Mail
	MailConfig MailConfig

	// AWS
	AWSConfig AWSConfig

	// Pusher
	PusherConfig PusherConfig
}

// FeatureFlags declares the high-level pluggable components supported by the template
// so features can be toggled on/off purely through environment variables.
type FeatureFlags struct {
	Database bool
	Auth     bool
	Cache    bool
	Mail     bool
	AWS      bool
	Pusher   bool
}

// SessionConfig holds session-related configuration
type SessionConfig struct {
	HTTPOnly bool
	SameSite string
	Expire   time.Duration
}

// JWTConfig holds JWT-related configuration
type JWTConfig struct {
	Expire        time.Duration
	RefreshExpire time.Duration
}

// MailConfig holds mail-related configuration
type MailConfig struct {
	Mailer      string
	Host        string
	Port        int
	Username    string
	Password    string
	Encryption  string
	FromAddress string
	FromName    string
}

// AWSConfig holds AWS-related configuration
type AWSConfig struct {
	AccessKeyID     string
	SecretAccessKey string
	DefaultRegion   string
	Bucket          string
}

// PusherConfig holds Pusher-related configuration
type PusherConfig struct {
	AppID     string
	AppKey    string
	AppSecret string
	Cluster   string
}

// LoadConfig loads configuration from environment variables
func LoadConfig() (*Config, error) {
	// Load .env file if it exists
	if err := godotenv.Load(); err != nil {
		// It's okay if .env doesn't exist
		if !os.IsNotExist(err) {
			return nil, err
		}
	}

	cfg := &Config{
		// Server
		Port:    getEnv("PORT", "3000"),
		Host:    getEnv("HOST", "localhost"),
		AppEnv:  getEnv("APP_ENV", "development"),
		AppURL:  getEnv("APP_URL", "http://localhost:3000"),
		AppName: getEnv("APP_NAME", "Fiber App"),

		// Middleware
		CORS:          getEnvAsBool("CORS", true),
		Compress:      getEnvAsBool("COMPRESS", true),
		CompressLevel: getEnvAsInt("COMPRESS_LEVEL", 0),

		// Feature flags
		Features: FeatureFlags{
			Database: getEnvAsBool("FEATURE_DATABASE", false),
			Auth:     getEnvAsBool("FEATURE_AUTH", false),
			Cache:    getEnvAsBool("FEATURE_CACHE", false),
			Mail:     getEnvAsBool("FEATURE_MAIL", false),
			AWS:      getEnvAsBool("FEATURE_AWS", false),
			Pusher:   getEnvAsBool("FEATURE_PUSHER", false),
		},

		// Database
		DBURL: getEnv("DB_URL", ""),

		// Authentication
		AuthType:   getEnv("AUTH", "Disabled"),
		AuthSecret: getEnv("AUTH_SECRET", ""),

		// Redis
		RedisHost:     getEnv("REDIS_HOST", "localhost"),
		RedisPassword: getEnv("REDIS_PASSWORD", ""),
		RedisPort:     getEnv("REDIS_PORT", "6379"),

		// Mail
		MailConfig: MailConfig{
			Mailer:      getEnv("MAIL_MAILER", "smtp"),
			Host:        getEnv("MAIL_HOST", "mailpit"),
			Port:        getEnvAsInt("MAIL_PORT", 1025),
			Username:    getEnv("MAIL_USERNAME", ""),
			Password:    getEnv("MAIL_PASSWORD", ""),
			Encryption:  getEnv("MAIL_ENCRYPTION", ""),
			FromAddress: getEnv("MAIL_FROM_ADDRESS", "hello@example.com"),
			FromName:    getEnv("MAIL_FROM_NAME", "Fiber App"),
		},

		// AWS
		AWSConfig: AWSConfig{
			AccessKeyID:     getEnv("AWS_ACCESS_KEY_ID", ""),
			SecretAccessKey: getEnv("AWS_SECRET_ACCESS_KEY", ""),
			DefaultRegion:   getEnv("AWS_DEFAULT_REGION", "us-east-1"),
			Bucket:          getEnv("AWS_BUCKET", ""),
		},

		// Pusher
		PusherConfig: PusherConfig{
			AppID:     getEnv("PUSHER_APP_ID", ""),
			AppKey:    getEnv("PUSHER_APP_KEY", ""),
			AppSecret: getEnv("PUSHER_APP_SECRET", ""),
			Cluster:   getEnv("PUSHER_APP_CLUSTER", "mt1"),
		},
	}

	// Parse session configuration
	cfg.SessionConfig = SessionConfig{
		HTTPOnly: getEnvAsBool("SESSION_HTTPONLY", true),
		SameSite: getEnv("SESSION_SAMESITE", "lax"),
		Expire:   getEnvAsDuration("SESSION_EXPIRE", 24*time.Hour),
	}

	// Parse JWT configuration
	cfg.JWTConfig = JWTConfig{
		Expire:        getEnvAsDuration("JWT_EXPIRE", 24*time.Hour),
		RefreshExpire: getEnvAsDuration("JWT_REFRESH_EXPIRE", 7*24*time.Hour),
	}

	return cfg, nil
}

// IsDevelopment returns true if the application is running in development mode
func (c *Config) IsDevelopment() bool {
	return strings.ToLower(c.AppEnv) == "development"
}

// IsProduction returns true if the application is running in production mode
func (c *Config) IsProduction() bool {
	return strings.ToLower(c.AppEnv) == "production"
}

// IsTesting returns true if the application is running in testing mode
func (c *Config) IsTesting() bool {
	return strings.ToLower(c.AppEnv) == "testing"
}

// DatabaseEnabled returns true when database integrations should be bootstrapped
func (c *Config) DatabaseEnabled() bool {
	return c != nil && c.Features.Database && c.DBURL != ""
}

// CacheEnabled returns true when Redis/Valkey integrations should be bootstrapped
func (c *Config) CacheEnabled() bool {
	return c != nil && c.Features.Cache && c.RedisHost != ""
}

// AuthEnabled returns true when session/JWT middlewares should be wired
func (c *Config) AuthEnabled() bool {
	if c == nil || !c.Features.Auth {
		return false
	}
	return strings.ToLower(c.AuthType) != "disabled" && c.AuthSecret != ""
}

// MailEnabled indicates whether outbound mailers should be initialised
func (c *Config) MailEnabled() bool {
	return c != nil && c.Features.Mail && c.MailConfig.Host != ""
}

// AWSEnabled indicates whether AWS SDK clients should be initialised
func (c *Config) AWSEnabled() bool {
	if c == nil || !c.Features.AWS {
		return false
	}
	return c.AWSConfig.AccessKeyID != "" && c.AWSConfig.SecretAccessKey != ""
}

// PusherEnabled indicates whether realtime adapters should be initialised
func (c *Config) PusherEnabled() bool {
	if c == nil || !c.Features.Pusher {
		return false
	}
	return c.PusherConfig.AppID != "" && c.PusherConfig.AppKey != "" && c.PusherConfig.AppSecret != ""
}

// getEnv gets an environment variable or returns a default value
func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

// getEnvAsBool gets an environment variable as a boolean
func getEnvAsBool(key string, defaultValue bool) bool {
	if value := os.Getenv(key); value != "" {
		if parsed, err := strconv.ParseBool(value); err == nil {
			return parsed
		}
	}
	return defaultValue
}

// getEnvAsInt gets an environment variable as an integer
func getEnvAsInt(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		if parsed, err := strconv.Atoi(value); err == nil {
			return parsed
		}
	}
	return defaultValue
}

// getEnvAsDuration gets an environment variable as a duration
func getEnvAsDuration(key string, defaultValue time.Duration) time.Duration {
	if value := os.Getenv(key); value != "" {
		if parsed, err := time.ParseDuration(value); err == nil {
			return parsed
		}
	}
	return defaultValue
}
