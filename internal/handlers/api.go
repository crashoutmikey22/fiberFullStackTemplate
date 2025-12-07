package handlers

import (
	"time"

	"github.com/gofiber/fiber/v2"

	"main.go/internal/config"
	"main.go/internal/templates/pages"
)

// APIHandler handles general API requests
type APIHandler struct {
	cfg *config.Config
}

// NewAPIHandler creates a new API handler
func NewAPIHandler(cfg *config.Config) *APIHandler {
	return &APIHandler{cfg: cfg}
}

// Welcome returns a welcome message
func (h *APIHandler) Welcome(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"message":     "Welcome to the Fiber API",
		"application": h.appName(),
		"environment": h.environment(),
		"status":      "running",
	})
}

// Homepage renders the HTML landing page with health links
func (h *APIHandler) Homepage(c *fiber.Ctx) error {
	c.Set("Content-Type", "text/html; charset=utf-8")
	return pages.HomePage(h.appName(), h.environment(), h.featureStatuses()).Render(c.Context(), c.Response().BodyWriter())
}

// Status returns the API status
func (h *APIHandler) Status(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"status":    "ok",
		"service":   h.appName(),
		"timestamp": time.Now().UTC(),
		"environment": fiber.Map{
			"env":      h.environment(),
			"hostname": c.App().Config().ServerHeader,
		},
		"features": fiber.Map{
			"database": h.cfg != nil && h.cfg.DatabaseEnabled(),
			"cache":    h.cfg != nil && h.cfg.CacheEnabled(),
			"auth":     h.cfg != nil && h.cfg.AuthEnabled(),
			"mail":     h.cfg != nil && h.cfg.MailEnabled(),
			"aws":      h.cfg != nil && h.cfg.AWSEnabled(),
			"pusher":   h.cfg != nil && h.cfg.PusherEnabled(),
		},
		"endpoints": fiber.Map{
			"health": "/health",
			"ready":  "/ready",
			"live":   "/live",
			"api":    "/api/v1",
		},
	})
}

// NotFound returns a 404 handler
func (h *APIHandler) NotFound(c *fiber.Ctx) error {
	return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
		"error":   "Not Found",
		"message": "The requested resource was not found",
		"status":  404,
	})
}

// Error returns a generic error handler
func (h *APIHandler) Error(c *fiber.Ctx, err error) error {
	code := fiber.StatusInternalServerError
	if e, ok := err.(*fiber.Error); ok {
		code = e.Code
	}

	return c.Status(code).JSON(fiber.Map{
		"error":   "Internal Server Error",
		"message": err.Error(),
		"status":  code,
	})
}

func (h *APIHandler) appName() string {
	if h.cfg == nil || h.cfg.AppName == "" {
		return "Fiber API"
	}
	return h.cfg.AppName
}

func (h *APIHandler) environment() string {
	if h.cfg == nil || h.cfg.AppEnv == "" {
		return "development"
	}
	return h.cfg.AppEnv
}

func (h *APIHandler) featureStatuses() []pages.FeatureStatus {
	if h.cfg == nil {
		return nil
	}

	return []pages.FeatureStatus{
		{Label: "Database", Description: "SQL + SQLC integrations", Enabled: h.cfg.DatabaseEnabled()},
		{Label: "Cache", Description: "Redis / Valkey integration", Enabled: h.cfg.CacheEnabled()},
		{Label: "Auth", Description: "Sessions or JWT guards", Enabled: h.cfg.AuthEnabled()},
		{Label: "Mail", Description: "Mailpit/SMTP bindings", Enabled: h.cfg.MailEnabled()},
		{Label: "AWS", Description: "S3 + IAM credentials", Enabled: h.cfg.AWSEnabled()},
		{Label: "Pusher", Description: "Realtime websocket bridge", Enabled: h.cfg.PusherEnabled()},
	}
}
