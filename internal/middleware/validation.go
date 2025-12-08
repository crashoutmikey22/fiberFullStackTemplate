package middleware

import (
	"encoding/json"
	"fmt"
	"reflect"
	"strings"

	"github.com/gofiber/fiber/v2"

	"main.go/internal/validation"
)

// ValidationMiddleware provides validation for Fiber requests
type ValidationMiddleware struct {
	validator *validation.Validator
}

// NewValidationMiddleware creates a new validation middleware instance
func NewValidationMiddleware() *ValidationMiddleware {
	return &ValidationMiddleware{
		validator: validation.NewValidator(),
	}
}

// ValidateBody validates the request body against a struct
func (vm *ValidationMiddleware) ValidateBody(model interface{}) fiber.Handler {
	return func(c *fiber.Ctx) error {
		// Parse request body
		if err := c.BodyParser(model); err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
				"error":   "Invalid request body",
				"message": "Failed to parse request body",
				"details": err.Error(),
			})
		}

		// Validate the struct
		if err := vm.validator.Validate(model); err != nil {
			return c.Status(fiber.StatusUnprocessableEntity).JSON(fiber.Map{
				"error":   "Validation failed",
				"message": "Request body validation failed",
				"details": vm.formatValidationErrors(err),
			})
		}

		// Store validated model in context for handlers to use
		c.Locals("validated_body", model)
		return c.Next()
	}
}

// ValidateQuery validates query parameters against a struct
func (vm *ValidationMiddleware) ValidateQuery(model interface{}) fiber.Handler {
	return func(c *fiber.Ctx) error {
		// Parse query parameters
		if err := c.QueryParser(model); err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
				"error":   "Invalid query parameters",
				"message": "Failed to parse query parameters",
				"details": err.Error(),
			})
		}

		// Validate the struct
		if err := vm.validator.Validate(model); err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
				"error":   "Validation failed",
				"message": "Query parameter validation failed",
				"details": vm.formatValidationErrors(err),
			})
		}

		// Store validated model in context
		c.Locals("validated_query", model)
		return c.Next()
	}
}

// ValidateParams validates route parameters against a struct
func (vm *ValidationMiddleware) ValidateParams(model interface{}) fiber.Handler {
	return func(c *fiber.Ctx) error {
		// Parse route parameters
		if err := c.ParamsParser(model); err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
				"error":   "Invalid route parameters",
				"message": "Failed to parse route parameters",
				"details": err.Error(),
			})
		}

		// Validate the struct
		if err := vm.validator.Validate(model); err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
				"error":   "Validation failed",
				"message": "Route parameter validation failed",
				"details": vm.formatValidationErrors(err),
			})
		}

		// Store validated model in context
		c.Locals("validated_params", model)
		return c.Next()
	}
}

// ValidateHeaders validates request headers against a struct
func (vm *ValidationMiddleware) ValidateHeaders(model interface{}) fiber.Handler {
	return func(c *fiber.Ctx) error {
		// Get all headers
		headers := c.GetReqHeaders()

		// Create a map for header validation
		headerMap := make(map[string]interface{})
		for key, values := range headers {
			if len(values) > 0 {
				headerMap[strings.ToLower(key)] = values[0]
			}
		}

		// Convert header map to JSON and then to struct
		jsonData, err := json.Marshal(headerMap)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"error":   "Internal server error",
				"message": "Failed to process headers",
			})
		}

		if err := json.Unmarshal(jsonData, model); err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
				"error":   "Invalid headers",
				"message": "Failed to parse headers",
				"details": err.Error(),
			})
		}

		// Validate the struct
		if err := vm.validator.Validate(model); err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
				"error":   "Validation failed",
				"message": "Header validation failed",
				"details": vm.formatValidationErrors(err),
			})
		}

		// Store validated model in context
		c.Locals("validated_headers", model)
		return c.Next()
	}
}

// ValidateCustom provides custom validation logic
func (vm *ValidationMiddleware) ValidateCustom(validatorFunc func(*fiber.Ctx) error) fiber.Handler {
	return func(c *fiber.Ctx) error {
		if err := validatorFunc(c); err != nil {
			return c.Status(fiber.StatusUnprocessableEntity).JSON(fiber.Map{
				"error":   "Validation failed",
				"message": "Custom validation failed",
				"details": vm.formatValidationErrors(err),
			})
		}
		return c.Next()
	}
}

// formatValidationErrors formats validation errors consistently
func (vm *ValidationMiddleware) formatValidationErrors(err error) map[string]string {
	if validationErrors, ok := err.(*validation.ValidationErrors); ok {
		return validationErrors.GetAllErrors()
	}

	// Handle other error types
	return map[string]string{
		"general": err.Error(),
	}
}

// GetValidatedBody retrieves the validated body from context
func GetValidatedBody[T any](c *fiber.Ctx) (*T, bool) {
	if model, ok := c.Locals("validated_body").(*T); ok {
		return model, true
	}
	return nil, false
}

// GetValidatedQuery retrieves the validated query from context
func GetValidatedQuery[T any](c *fiber.Ctx) (*T, bool) {
	if model, ok := c.Locals("validated_query").(*T); ok {
		return model, true
	}
	return nil, false
}

// GetValidatedParams retrieves the validated params from context
func GetValidatedParams[T any](c *fiber.Ctx) (*T, bool) {
	if model, ok := c.Locals("validated_params").(*T); ok {
		return model, true
	}
	return nil, false
}

// GetValidatedHeaders retrieves the validated headers from context
func GetValidatedHeaders[T any](c *fiber.Ctx) (*T, bool) {
	if model, ok := c.Locals("validated_headers").(*T); ok {
		return model, true
	}
	return nil, false
}

// ValidateField validates a single field from request body
func (vm *ValidationMiddleware) ValidateField(fieldName string, value interface{}, tag string) error {
	return vm.validator.ValidateVar(value, tag)
}

// ValidatePartial validates only specified fields of a struct
func (vm *ValidationMiddleware) ValidatePartial(model interface{}, fields ...string) error {
	if len(fields) == 0 {
		return vm.validator.Validate(model)
	}

	// Create a partial validation by checking only specified fields
	v := reflect.ValueOf(model)
	if v.Kind() == reflect.Ptr {
		v = v.Elem()
	}

	if v.Kind() != reflect.Struct {
		return fmt.Errorf("model must be a struct or pointer to struct")
	}

	t := v.Type()
	errors := make(map[string]string)

	for _, fieldName := range fields {
		field, found := t.FieldByName(fieldName)
		if !found {
			errors[fieldName] = "field not found"
			continue
		}

		fieldValue := v.FieldByName(fieldName)
		if tag := field.Tag.Get("validate"); tag != "" {
			if err := vm.validator.ValidateVar(fieldValue.Interface(), tag); err != nil {
				if validationErrors, ok := err.(*validation.ValidationErrors); ok {
					if msg := validationErrors.GetFieldError(fieldName); msg != "" {
						errors[fieldName] = msg
					}
				} else {
					errors[fieldName] = err.Error()
				}
			}
		}
	}

	if len(errors) > 0 {
		return &validation.ValidationErrors{Errors: errors}
	}

	return nil
}
