package middleware

import (
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
)

// CORS returns a CORS middleware with configurable options
func CORS(enabled bool) fiber.Handler {
	if !enabled {
		// Return a no-op middleware if CORS is disabled
		return func(c *fiber.Ctx) error {
			return c.Next()
		}
	}

	return cors.New(cors.Config{
		AllowOrigins:     "*",
		AllowCredentials: false,
		AllowHeaders:     "Origin, Content-Type, Accept, Authorization, X-Requested-With, X-CSRF-Token",
		AllowMethods:     "GET, POST, PUT, DELETE, OPTIONS, PATCH",
		ExposeHeaders:    "Content-Length, Content-Type, Authorization",
		MaxAge:           86400, // 24 hours
		Next: func(c *fiber.Ctx) bool {
			// Skip CORS for specific routes if needed
			return c.Path() == "/health"
		},
	})
}

// CORSWithConfig returns a CORS middleware with custom configuration
func CORSWithConfig(config cors.Config) fiber.Handler {
	// Set default values if not provided
	if config.AllowOrigins == "" {
		config.AllowOrigins = "*"
	}

	if len(config.AllowHeaders) == 0 {
		config.AllowHeaders = "Origin, Content-Type, Accept, Authorization, X-Requested-With, X-CSRF-Token"
	}

	if len(config.AllowMethods) == 0 {
		config.AllowMethods = "GET, POST, PUT, DELETE, OPTIONS, PATCH"
	}

	if len(config.ExposeHeaders) == 0 {
		config.ExposeHeaders = "Content-Length, Content-Type, Authorization"
	}

	if config.MaxAge == 0 {
		config.MaxAge = 86400 // 24 hours
	}

	return cors.New(config)
}
