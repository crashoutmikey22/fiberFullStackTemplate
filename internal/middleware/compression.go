package middleware

import (
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/compress"
)

// Compression returns a compression middleware with configurable options
func Compression(enabled bool, level int) fiber.Handler {
	if !enabled {
		// Return a no-op middleware if compression is disabled
		return func(c *fiber.Ctx) error {
			return c.Next()
		}
	}

	// Validate compression level
	if level < -1 || level > 2 {
		level = 0 // Default balanced compression
	}

	config := compress.Config{
		Level: compress.Level(level),
		Next: func(c *fiber.Ctx) bool {
			// Skip compression for specific routes if needed
			// e.g., return c.Path() == "/health" || c.Path() == "/metrics"
			return false
		},
	}

	return compress.New(config)
}

// CompressionWithConfig returns a compression middleware with custom configuration
func CompressionWithConfig(config compress.Config) fiber.Handler {
	return compress.New(config)
}
