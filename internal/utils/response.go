package utils

import (
	"net/http"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/utils"
)

// Response represents a standard API response
type Response struct {
	Success   bool        `json:"success"`
	Message   string      `json:"message"`
	Data      interface{} `json:"data,omitempty"`
	Error     string      `json:"error,omitempty"`
	Timestamp time.Time   `json:"timestamp"`
	RequestID string      `json:"request_id,omitempty"`
}

// SuccessResponse creates a success response
func SuccessResponse(c *fiber.Ctx, data interface{}, message string) error {
	return c.JSON(Response{
		Success:   true,
		Message:   message,
		Data:      data,
		Timestamp: time.Now(),
		RequestID: c.Get("X-Request-ID"),
	})
}

// ErrorResponse creates an error response
func ErrorResponse(c *fiber.Ctx, statusCode int, message string, err error) error {
	return c.Status(statusCode).JSON(Response{
		Success:   false,
		Message:   message,
		Error:     err.Error(),
		Timestamp: time.Now(),
		RequestID: c.Get("X-Request-ID"),
	})
}

// BadRequest creates a bad request response
func BadRequest(c *fiber.Ctx, message string) error {
	return ErrorResponse(c, http.StatusBadRequest, message, fiber.NewError(http.StatusBadRequest, message))
}

// Unauthorized creates an unauthorized response
func Unauthorized(c *fiber.Ctx, message string) error {
	return ErrorResponse(c, http.StatusUnauthorized, message, fiber.NewError(http.StatusUnauthorized, message))
}

// Forbidden creates a forbidden response
func Forbidden(c *fiber.Ctx, message string) error {
	return ErrorResponse(c, http.StatusForbidden, message, fiber.NewError(http.StatusForbidden, message))
}

// NotFound creates a not found response
func NotFound(c *fiber.Ctx, message string) error {
	return ErrorResponse(c, http.StatusNotFound, message, fiber.NewError(http.StatusNotFound, message))
}

// InternalServerError creates an internal server error response
func InternalServerError(c *fiber.Ctx, message string) error {
	return ErrorResponse(c, http.StatusInternalServerError, message, fiber.NewError(http.StatusInternalServerError, message))
}

// ValidationError creates a validation error response
func ValidationError(c *fiber.Ctx, errors map[string]string) error {
	return c.Status(http.StatusUnprocessableEntity).JSON(fiber.Map{
		"success":    false,
		"message":    "Validation failed",
		"errors":     errors,
		"timestamp":  time.Now(),
		"request_id": c.Get("X-Request-ID"),
	})
}

// GenerateRandomString generates a random string of the specified length
func GenerateRandomString() string {
	return utils.UUIDv4()
}
