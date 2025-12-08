package utils

import (
	"fmt"
	"strings"

	"github.com/gofiber/fiber/v2"

	"main.go/internal/validation"
)

// ValidationErrorResponse provides consistent validation error responses
type ValidationErrorResponse struct {
	Error   string            `json:"error"`
	Message string            `json:"message"`
	Details map[string]string `json:"details,omitempty"`
	Status  int               `json:"status"`
}

// ValidationErrorBuilder helps build consistent validation error responses
type ValidationErrorBuilder struct {
	response *ValidationErrorResponse
}

// NewValidationErrorBuilder creates a new validation error builder
func NewValidationErrorBuilder() *ValidationErrorBuilder {
	return &ValidationErrorBuilder{
		response: &ValidationErrorResponse{
			Error:   "Validation failed",
			Message: "Request validation failed",
			Status:  fiber.StatusUnprocessableEntity,
		},
	}
}

// WithError sets the error type
func (b *ValidationErrorBuilder) WithError(error string) *ValidationErrorBuilder {
	b.response.Error = error
	return b
}

// WithMessage sets the error message
func (b *ValidationErrorBuilder) WithMessage(message string) *ValidationErrorBuilder {
	b.response.Message = message
	return b
}

// WithStatus sets the HTTP status code
func (b *ValidationErrorBuilder) WithStatus(status int) *ValidationErrorBuilder {
	b.response.Status = status
	return b
}

// WithDetails adds validation error details
func (b *ValidationErrorBuilder) WithDetails(details map[string]string) *ValidationErrorBuilder {
	b.response.Details = details
	return b
}

// WithValidationErrors adds validation errors from the validation package
func (b *ValidationErrorBuilder) WithValidationErrors(err error) *ValidationErrorBuilder {
	if validationErrors, ok := err.(*validation.ValidationErrors); ok {
		b.response.Details = validationErrors.GetAllErrors()
	} else {
		b.response.Details = map[string]string{
			"general": err.Error(),
		}
	}
	return b
}

// Build creates the final validation error response
func (b *ValidationErrorBuilder) Build() *ValidationErrorResponse {
	return b.response
}

// Send sends the validation error response as JSON
func (b *ValidationErrorBuilder) Send(c *fiber.Ctx) error {
	return c.Status(b.response.Status).JSON(b.response)
}

// ValidationErrorHelper provides utility functions for validation errors
type ValidationErrorHelper struct{}

// NewValidationErrorHelper creates a new validation error helper
func NewValidationErrorHelper() *ValidationErrorHelper {
	return &ValidationErrorHelper{}
}

// HandleValidationError handles validation errors with consistent response format
func (h *ValidationErrorHelper) HandleValidationError(c *fiber.Ctx, err error) error {
	return NewValidationErrorBuilder().
		WithValidationErrors(err).
		Send(c)
}

// HandleCustomValidationError handles custom validation errors
func (h *ValidationErrorHelper) HandleCustomValidationError(c *fiber.Ctx, field, message string) error {
	return NewValidationErrorBuilder().
		WithDetails(map[string]string{field: message}).
		Send(c)
}

// HandleMultipleValidationErrors handles multiple validation errors
func (h *ValidationErrorHelper) HandleMultipleValidationErrors(c *fiber.Ctx, errors map[string]string) error {
	return NewValidationErrorBuilder().
		WithDetails(errors).
		Send(c)
}

// CreateValidationErrorResponse creates a validation error response for testing
func (h *ValidationErrorHelper) CreateValidationErrorResponse(err error) *ValidationErrorResponse {
	return NewValidationErrorBuilder().
		WithValidationErrors(err).
		Build()
}

// FormatValidationErrors formats validation errors into a human-readable string
func (h *ValidationErrorHelper) FormatValidationErrors(err error) string {
	if validationErrors, ok := err.(*validation.ValidationErrors); ok {
		var messages []string
		for field, message := range validationErrors.GetAllErrors() {
			messages = append(messages, fmt.Sprintf("%s: %s", field, message))
		}
		return strings.Join(messages, "; ")
	}
	return err.Error()
}

// GetFieldError gets the error message for a specific field
func (h *ValidationErrorHelper) GetFieldError(err error, field string) string {
	if validationErrors, ok := err.(*validation.ValidationErrors); ok {
		return validationErrors.GetFieldError(field)
	}
	return ""
}

// HasFieldError checks if a specific field has validation errors
func (h *ValidationErrorHelper) HasFieldError(err error, field string) bool {
	if validationErrors, ok := err.(*validation.ValidationErrors); ok {
		return validationErrors.HasFieldError(field)
	}
	return false
}

// ValidationMiddleware provides additional validation middleware utilities
type ValidationMiddleware struct {
	errorHelper *ValidationErrorHelper
}

// NewValidationMiddleware creates a new validation middleware utility
func NewValidationMiddleware() *ValidationMiddleware {
	return &ValidationMiddleware{
		errorHelper: NewValidationErrorHelper(),
	}
}

// ErrorHandler returns a Fiber error handler for validation errors
func (m *ValidationMiddleware) ErrorHandler() fiber.ErrorHandler {
	return func(c *fiber.Ctx, err error) error {
		// Check if it's a validation error
		if _, ok := err.(*validation.ValidationErrors); ok {
			return m.errorHelper.HandleValidationError(c, err)
		}

		// Check if it's a Fiber error with validation-related status
		if e, ok := err.(*fiber.Error); ok {
			if e.Code == fiber.StatusUnprocessableEntity || e.Code == fiber.StatusBadRequest {
				return NewValidationErrorBuilder().
					WithError("Request Error").
					WithMessage(e.Message).
					WithStatus(e.Code).
					Send(c)
			}
		}

		// Not a validation error, let the next handler handle it
		return err
	}
}

// Global validation error handler that can be used in Fiber app configuration
func GlobalValidationErrorHandler(c *fiber.Ctx, err error) error {
	helper := NewValidationErrorHelper()

	// Check if it's a validation error
	if _, ok := err.(*validation.ValidationErrors); ok {
		return helper.HandleValidationError(c, err)
	}

	// Check if it's a Fiber error with validation-related status
	if e, ok := err.(*fiber.Error); ok {
		if e.Code == fiber.StatusUnprocessableEntity || e.Code == fiber.StatusBadRequest {
			return NewValidationErrorBuilder().
				WithError("Request Error").
				WithMessage(e.Message).
				WithStatus(e.Code).
				Send(c)
		}
	}

	// Not a validation error, return default error response
	return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
		"error":   "Internal Server Error",
		"message": "An unexpected error occurred",
		"status":  fiber.StatusInternalServerError,
	})
}

// ValidationResponseBuilder provides a fluent interface for building validation responses
type ValidationResponseBuilder struct {
	c *fiber.Ctx
}

// NewValidationResponseBuilder creates a new validation response builder
func NewValidationResponseBuilder(c *fiber.Ctx) *ValidationResponseBuilder {
	return &ValidationResponseBuilder{c: c}
}

// ValidationError sends a validation error response
func (b *ValidationResponseBuilder) ValidationError(err error) error {
	return NewValidationErrorBuilder().
		WithValidationErrors(err).
		Send(b.c)
}

// BadRequest sends a bad request error response
func (b *ValidationResponseBuilder) BadRequest(message string) error {
	return NewValidationErrorBuilder().
		WithError("Bad Request").
		WithMessage(message).
		WithStatus(fiber.StatusBadRequest).
		Send(b.c)
}

// Unauthorized sends an unauthorized error response
func (b *ValidationResponseBuilder) Unauthorized(message string) error {
	return NewValidationErrorBuilder().
		WithError("Unauthorized").
		WithMessage(message).
		WithStatus(fiber.StatusUnauthorized).
		Send(b.c)
}

// Forbidden sends a forbidden error response
func (b *ValidationResponseBuilder) Forbidden(message string) error {
	return NewValidationErrorBuilder().
		WithError("Forbidden").
		WithMessage(message).
		WithStatus(fiber.StatusForbidden).
		Send(b.c)
}

// NotFound sends a not found error response
func (b *ValidationResponseBuilder) NotFound(message string) error {
	return NewValidationErrorBuilder().
		WithError("Not Found").
		WithMessage(message).
		WithStatus(fiber.StatusNotFound).
		Send(b.c)
}

// Conflict sends a conflict error response
func (b *ValidationResponseBuilder) Conflict(message string) error {
	return NewValidationErrorBuilder().
		WithError("Conflict").
		WithMessage(message).
		WithStatus(fiber.StatusConflict).
		Send(b.c)
}

// InternalServerError sends an internal server error response
func (b *ValidationResponseBuilder) InternalServerError(message string) error {
	return NewValidationErrorBuilder().
		WithError("Internal Server Error").
		WithMessage(message).
		WithStatus(fiber.StatusInternalServerError).
		Send(b.c)
}
