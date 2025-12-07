package middleware

import (
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/recover"
)

// Recover returns a recover middleware that catches panics in HTTP handlers
// and returns a 500 Internal Server Error response.
func Recover() fiber.Handler {
	return recover.New(recover.Config{
		EnableStackTrace: true,
		Next: func(c *fiber.Ctx) bool {
			// Skip recovery for specific routes if needed
			// e.g., return c.Path() == "/health"
			return false
		},
	})
}
