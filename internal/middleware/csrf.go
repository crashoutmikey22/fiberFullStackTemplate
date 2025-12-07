package middleware

import (
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/csrf"
	"main.go/internal/utils"
)

// CSRF returns a CSRF middleware with configurable options
func CSRF(enabled bool) fiber.Handler {
	if !enabled {
		// Return a no-op middleware if CSRF is disabled
		return func(c *fiber.Ctx) error {
			return c.Next()
		}
	}

	return csrf.New(csrf.Config{
		KeyLookup:      "header:X-CSRF-Token",
		CookieName:     "csrf_",
		CookieSameSite: "Lax",
		Expiration:     1 * time.Hour,
		KeyGenerator:   utils.GenerateRandomString,
		ErrorHandler: func(c *fiber.Ctx, err error) error {
			return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
				"error":   "Forbidden",
				"message": "CSRF token invalid or missing",
			})
		},
	})
}
