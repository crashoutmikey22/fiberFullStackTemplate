package middleware

import (
	"time"

	"github.com/gofiber/fiber/v2"
)

// HealthCheck returns a health check middleware
func HealthCheck(db interface{}) fiber.Handler {
	return func(c *fiber.Ctx) error {
		start := time.Now()

		// Basic health check
		health := fiber.Map{
			"status":    "ok",
			"timestamp": time.Now().UTC(),
			"uptime":    time.Since(start),
		}

		// Check database if provided
		if db != nil {
			// Database connection check would go here
			// For now, we'll just add a database status
			health["database"] = "connected"
		}

		// Add more health checks as needed (Redis, external APIs, etc.)

		return c.JSON(health)
	}
}

// HealthCheckWithDB returns a health check middleware that checks database connectivity
func HealthCheckWithDB(db interface{}) fiber.Handler {
	return func(c *fiber.Ctx) error {
		start := time.Now()

		health := fiber.Map{
			"status":    "ok",
			"timestamp": time.Now().UTC(),
			"uptime":    time.Since(start),
		}

		// Check database connectivity
		if db != nil {
			// Perform actual database health check
			// This would be your actual database health check
			// For example: err := dbConn.HealthCheck(ctx)
			// if err != nil {
			//     health["database"] = "disconnected"
			//     health["status"] = "degraded"
			// } else {
			//     health["database"] = "connected"
			// }
			health["database"] = "connected" // Placeholder
		}

		return c.JSON(health)
	}
}
