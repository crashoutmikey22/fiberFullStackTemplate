package handlers

import (
	"net/http"
	"time"

	"github.com/gofiber/fiber/v2"

	"main.go/internal/config"
	"main.go/internal/database"
)

// HealthHandler handles health check requests
type HealthHandler struct {
	cfg *config.Config
	db  *database.DB
}

// NewHealthHandler creates a new health handler
func NewHealthHandler(cfg *config.Config, db *database.DB) *HealthHandler {
	return &HealthHandler{cfg: cfg, db: db}
}

// Check returns a basic health check handler
func (h *HealthHandler) Check(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"status":      "ok",
		"message":     "Service is healthy",
		"timestamp":   time.Now().UTC(),
		"environment": h.environment(),
	})
}

// DetailedCheck returns a detailed health check handler
func (h *HealthHandler) DetailedCheck(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"status":      "ok",
		"message":     "Service is healthy",
		"timestamp":   time.Now().UTC(),
		"environment": h.environment(),
		"checks":      h.featureStatus(),
	})
}

// Ready returns a readiness check handler
func (h *HealthHandler) Ready(c *fiber.Ctx) error {
	status := fiber.Map{
		"status":    "ready",
		"timestamp": time.Now().UTC(),
	}

	if h.cfg != nil && h.cfg.DatabaseEnabled() && h.db == nil {
		status["status"] = "degraded"
		status["details"] = "database required but not connected"
		return c.Status(http.StatusServiceUnavailable).JSON(status)
	}

	return c.JSON(status)
}

// Live returns a liveness check handler
func (h *HealthHandler) Live(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"status":    "alive",
		"timestamp": time.Now().UTC(),
	})
}

func (h *HealthHandler) environment() string {
	if h.cfg == nil {
		return "unknown"
	}
	return h.cfg.AppEnv
}

func (h *HealthHandler) featureStatus() fiber.Map {
	checks := fiber.Map{}

	if h.cfg == nil {
		return checks
	}

	if h.cfg.DatabaseEnabled() {
		if h.db != nil {
			checks["database"] = "connected"
		} else {
			checks["database"] = "unavailable"
		}
	}

	if h.cfg.CacheEnabled() {
		checks["cache"] = "configured"
	}

	if h.cfg.AuthEnabled() {
		checks["auth"] = h.cfg.AuthType
	}

	if h.cfg.MailEnabled() {
		checks["mail"] = h.cfg.MailConfig.Mailer
	}

	if h.cfg.AWSEnabled() {
		checks["aws"] = h.cfg.AWSConfig.DefaultRegion
	}

	if h.cfg.PusherEnabled() {
		checks["pusher"] = h.cfg.PusherConfig.Cluster
	}

	return checks
}
