package validation

import (
	"fmt"
	"reflect"
	"strings"

	"github.com/go-playground/validator/v10"
)

// Validator wraps the go-playground validator
type Validator struct {
	validate *validator.Validate
}

// NewValidator creates a new validator instance
func NewValidator() *Validator {
	v := validator.New()

	// Register custom validators
	if err := v.RegisterValidation("password", validatePassword); err != nil {
		return &Validator{validate: v}
	}
	if err := v.RegisterValidation("username", validateUsername); err != nil {
		return &Validator{validate: v}
	}
	if err := v.RegisterValidation("slug", validateSlug); err != nil {
		return &Validator{validate: v}
	}

	// Register custom field name extractor
	v.RegisterTagNameFunc(func(fld reflect.StructField) string {
		name := strings.SplitN(fld.Tag.Get("json"), ",", 2)[0]
		if name == "" {
			name = fld.Name
		}
		return name
	})

	return &Validator{validate: v}
}

// Validate validates a struct and returns validation errors
func (v *Validator) Validate(s interface{}) error {
	if err := v.validate.Struct(s); err != nil {
		return v.formatValidationError(err)
	}
	return nil
}

// ValidateVar validates a single field
func (v *Validator) ValidateVar(field interface{}, tag string) error {
	if err := v.validate.Var(field, tag); err != nil {
		return v.formatValidationError(err)
	}
	return nil
}

// formatValidationError formats validation errors into a consistent format
func (v *Validator) formatValidationError(err error) error {
	if validationErrors, ok := err.(validator.ValidationErrors); ok {
		formattedErrors := make(map[string]string)
		for _, e := range validationErrors {
			formattedErrors[e.Field()] = v.getErrorMessage(e)
		}
		return &ValidationErrors{Errors: formattedErrors}
	}
	return err
}

// getErrorMessage returns user-friendly error messages
func (v *Validator) getErrorMessage(e validator.FieldError) string {
	switch e.Tag() {
	case "required":
		return fmt.Sprintf("%s is required", e.Field())
	case "email":
		return fmt.Sprintf("%s must be a valid email address", e.Field())
	case "min":
		return fmt.Sprintf("%s must be at least %s characters", e.Field(), e.Param())
	case "max":
		return fmt.Sprintf("%s must be at most %s characters", e.Field(), e.Param())
	case "len":
		return fmt.Sprintf("%s must be exactly %s characters", e.Field(), e.Param())
	case "numeric":
		return fmt.Sprintf("%s must contain only numbers", e.Field())
	case "alphanum":
		return fmt.Sprintf("%s must contain only letters and numbers", e.Field())
	case "alpha":
		return fmt.Sprintf("%s must contain only letters", e.Field())
	case "url":
		return fmt.Sprintf("%s must be a valid URL", e.Field())
	case "uuid":
		return fmt.Sprintf("%s must be a valid UUID", e.Field())
	case "password":
		return "password must be at least 8 characters and contain uppercase, lowercase, number, and special character"
	case "username":
		return "username must be 3-30 characters, alphanumeric with optional underscores and hyphens"
	case "slug":
		return "slug must contain only lowercase letters, numbers, and hyphens"
	case "oneof":
		return fmt.Sprintf("%s must be one of: %s", e.Field(), e.Param())
	case "gte":
		return fmt.Sprintf("%s must be greater than or equal to %s", e.Field(), e.Param())
	case "lte":
		return fmt.Sprintf("%s must be less than or equal to %s", e.Field(), e.Param())
	case "gt":
		return fmt.Sprintf("%s must be greater than %s", e.Field(), e.Param())
	case "lt":
		return fmt.Sprintf("%s must be less than %s", e.Field(), e.Param())
	default:
		return fmt.Sprintf("%s is invalid", e.Field())
	}
}

// Custom validators

// validatePassword validates password strength
func validatePassword(fl validator.FieldLevel) bool {
	password := fl.Field().String()
	if len(password) < 8 {
		return false
	}

	hasUpper := false
	hasLower := false
	hasNumber := false
	hasSpecial := false

	for _, char := range password {
		switch {
		case char >= 'A' && char <= 'Z':
			hasUpper = true
		case char >= 'a' && char <= 'z':
			hasLower = true
		case char >= '0' && char <= '9':
			hasNumber = true
		case strings.ContainsRune("!@#$%^&*()_+-=[]{}|;:,.<>?", char):
			hasSpecial = true
		}
	}

	return hasUpper && hasLower && hasNumber && hasSpecial
}

// validateUsername validates username format
func validateUsername(fl validator.FieldLevel) bool {
	username := fl.Field().String()
	if len(username) < 3 || len(username) > 30 {
		return false
	}

	for _, char := range username {
		if !((char >= 'a' && char <= 'z') ||
			(char >= 'A' && char <= 'Z') ||
			(char >= '0' && char <= '9') ||
			char == '_' || char == '-') {
			return false
		}
	}

	return true
}

// validateSlug validates slug format
func validateSlug(fl validator.FieldLevel) bool {
	slug := fl.Field().String()
	if len(slug) == 0 {
		return false
	}

	for _, char := range slug {
		if !((char >= 'a' && char <= 'z') ||
			(char >= '0' && char <= '9') ||
			char == '-') {
			return false
		}
	}

	// Cannot start or end with hyphen
	return slug[0] != '-' && slug[len(slug)-1] != '-'
}

// ValidationErrors represents a collection of validation errors
type ValidationErrors struct {
	Errors map[string]string
}

// Error implements the error interface
func (ve *ValidationErrors) Error() string {
	if len(ve.Errors) == 0 {
		return "validation failed"
	}

	var messages []string
	for field, message := range ve.Errors {
		messages = append(messages, fmt.Sprintf("%s: %s", field, message))
	}

	return strings.Join(messages, "; ")
}

// GetFieldError returns the error message for a specific field
func (ve *ValidationErrors) GetFieldError(field string) string {
	if ve.Errors == nil {
		return ""
	}
	return ve.Errors[field]
}

// HasFieldError checks if a specific field has validation errors
func (ve *ValidationErrors) HasFieldError(field string) bool {
	if ve.Errors == nil {
		return false
	}
	_, exists := ve.Errors[field]
	return exists
}

// GetAllErrors returns all validation errors
func (ve *ValidationErrors) GetAllErrors() map[string]string {
	if ve.Errors == nil {
		return make(map[string]string)
	}
	return ve.Errors
}
