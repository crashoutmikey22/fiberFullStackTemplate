# Input Validation System

This document describes the comprehensive input validation system implemented in the Fiber Full Stack Template.

## Overview

The validation system provides:
- **Struct-based validation** using `go-playground/validator/v10`
- **Custom validators** for common patterns (passwords, usernames, slugs)
- **Fiber middleware integration** for seamless request validation
- **Consistent error responses** with detailed field-level errors
- **Flexible validation patterns** for body, query, params, and headers

## Quick Start

### 1. Define Validation Structs

```go
type UserRegistration struct {
    Email     string `json:"email" validate:"required,email,max=255"`
    Username  string `json:"username" validate:"required,username,min=3,max=30"`
    FirstName string `json:"first_name" validate:"required,alpha,min=2,max=50"`
    Password  string `json:"password" validate:"required,password,min=8,max=128"`
}
```

### 2. Add Validation Middleware

```go
v1.Post("/users/register", 
    validationMiddleware.ValidateBody(&UserRegistration{}), 
    registerUserHandler)
```

### 3. Use Validated Data

```go
func registerUserHandler(c *fiber.Ctx) error {
    user, ok := middleware.GetValidatedBody[UserRegistration](c)
    if !ok {
        return c.Status(500).JSON(fiber.Map{"error": "Validation failed"})
    }
    
    // user is now validated and ready to use
    return c.JSON(fiber.Map{"message": "User registered", "email": user.Email})
}
```

## Available Validators

### Built-in Validators

| Validator | Description | Example |
|-----------|-------------|---------|
| `required` | Field must be present and non-empty | `validate:"required"` |
| `email` | Valid email format | `validate:"email"` |
| `min` | Minimum length/value | `validate:"min=8"` |
| `max` | Maximum length/value | `validate:"max=255"` |
| `alpha` | Letters only | `validate:"alpha"` |
| `alphanum` | Letters and numbers only | `validate:"alphanum"` |
| `numeric` | Numbers only | `validate:"numeric"` |
| `uuid` | Valid UUID format | `validate:"uuid"` |
| `url` | Valid URL format | `validate:"url"` |
| `oneof` | Value must be one of specified options | `validate:"oneof=draft published archived"` |
| `eqfield` | Must equal another field | `validate:"eqfield=Password"` |
| `gtfield` | Must be greater than another field | `validate:"gtfield=StartDate"` |

### Custom Validators

| Validator | Description | Requirements |
|-----------|-------------|-------------|
| `password` | Strong password validation | 8+ chars, uppercase, lowercase, number, special |
| `username` | Username format validation | 3-30 chars, alphanumeric, underscores, hyphens |
| `slug` | URL slug validation | Lowercase, numbers, hyphens only |

## Validation Patterns

### 1. Request Body Validation

```go
// Define struct
type PostCreate struct {
    Title   string `json:"title" validate:"required,min=3,max=200"`
    Content string `json:"content" validate:"required,min=10,max=50000"`
    Status  string `json:"status" validate:"required,oneof=draft published"`
}

// Add middleware
v1.Post("/posts", validationMiddleware.ValidateBody(&PostCreate{}), createPostHandler)

// Use validated data
func createPostHandler(c *fiber.Ctx) error {
    post, ok := middleware.GetValidatedBody[PostCreate](c)
    // post is validated and ready
}
```

### 2. Query Parameter Validation

```go
// Define struct
type SearchQuery struct {
    Query string `json:"query" validate:"required,min=2,max=100"`
    Page  int    `json:"page" validate:"omitempty,min=1,max=100"`
    Limit int    `json:"limit" validate:"omitempty,min=1,max=100"`
}

// Add middleware
v1.Get("/search", validationMiddleware.ValidateQuery(&SearchQuery{}), searchHandler)

// Use validated data
func searchHandler(c *fiber.Ctx) error {
    query, ok := middleware.GetValidatedQuery[SearchQuery](c)
    // query is validated and ready
}
```

### 3. Route Parameter Validation

```go
// Define struct
type IDParam struct {
    ID string `json:"id" validate:"required,uuid"`
}

// Add middleware
v1.Get("/posts/:id", validationMiddleware.ValidateParams(&IDParam{}), getPostHandler)

// Use validated data
func getPostHandler(c *fiber.Ctx) error {
    params, ok := middleware.GetValidatedParams[IDParam](c)
    // params.ID is validated and ready
}
```

### 4. Header Validation

```go
// Define struct
type AuthHeaders struct {
    Authorization string `json:"authorization" validate:"required,min=10"`
    ContentType   string `json:"content-type" validate:"required,oneof=application/json"`
}

// Add middleware
v1.Post("/protected", validationMiddleware.ValidateHeaders(&AuthHeaders{}), protectedHandler)

// Use validated data
func protectedHandler(c *fiber.Ctx) error {
    headers, ok := middleware.GetValidatedHeaders[AuthHeaders](c)
    // headers are validated and ready
}
```

### 5. Custom Validation

```go
// Custom validation function
func customValidation(c *fiber.Ctx) error {
    // Custom logic here
    if someCondition {
        return fiber.NewError(422, "Custom validation failed")
    }
    return c.Next()
}

// Add middleware
v1.Post("/custom", validationMiddleware.ValidateCustom(customValidation), customHandler)
```

### 6. Partial Validation

```go
// Validate only specific fields
func partialUpdateHandler(c *fiber.Ctx) error {
    // Get fields to validate from query param
    fields := strings.Split(c.Query("fields"), ",")
    
    // Validate only specified fields
    err := validationMiddleware.ValidatePartial(&UserUpdate{}, fields...)
    if err != nil {
        return c.Status(422).JSON(err)
    }
    
    // Process partial update
}
```

## Error Handling

### Validation Error Response Format

```json
{
  "error": "Validation failed",
  "message": "Request validation failed",
  "details": {
    "email": "email must be a valid email address",
    "password": "password must be at least 8 characters and contain uppercase, lowercase, number, and special character",
    "username": "username must be 3-30 characters, alphanumeric with optional underscores and hyphens"
  },
  "status": 422
}
```

### Error Response Helpers

```go
// Using the validation response builder
func handler(c *fiber.Ctx) error {
    return utils.NewValidationResponseBuilder(c).
        ValidationError(err).
        Send(c)
}

// Direct error handling
func handler(c *fiber.Ctx) error {
    helper := utils.NewValidationErrorHelper()
    return helper.HandleValidationError(c, err)
}
```

## Example Implementations

### User Registration

```go
type UserRegistration struct {
    Email           string `json:"email" validate:"required,email,max=255"`
    Username        string `json:"username" validate:"required,username,min=3,max=30"`
    FirstName       string `json:"first_name" validate:"required,alpha,min=2,max=50"`
    LastName        string `json:"last_name" validate:"required,alpha,min=2,max=50"`
    Password        string `json:"password" validate:"required,password,min=8,max=128"`
    ConfirmPassword string `json:"confirm_password" validate:"required,eqfield=Password"`
}

v1.Post("/users/register", 
    validationMiddleware.ValidateBody(&UserRegistration{}), 
    registerUserHandler)
```

### Blog Post Management

```go
type PostCreate struct {
    Title       string    `json:"title" validate:"required,min=3,max=200"`
    Slug        string    `json:"slug" validate:"required,slug,min=3,max=100"`
    Content     string    `json:"content" validate:"required,min=10,max=50000"`
    Status      string    `json:"status" validate:"required,oneof=draft published archived"`
    PublishedAt *time.Time `json:"published_at,omitempty"`
    Tags        []string  `json:"tags,omitempty" validate:"omitempty,dive,alpha,min=2,max=30"`
    CategoryID  string    `json:"category_id" validate:"required,uuid"`
}

v1.Post("/posts", validationMiddleware.ValidateBody(&PostCreate{}), createPostHandler)
v1.Put("/posts/:id", 
    validationMiddleware.ValidateParams(&IDParam{}),
    validationMiddleware.ValidateBody(&PostUpdate{}), 
    updatePostHandler)
```

### Search and Pagination

```go
type SearchQuery struct {
    Query    string `json:"query" validate:"required,min=2,max=100"`
    Type     string `json:"type,omitempty" validate:"omitempty,oneof=posts users tags"`
    Page     int    `json:"page,omitempty" validate:"omitempty,min=1,max=1000"`
    Limit    int    `json:"limit,omitempty" validate:"omitempty,min=1,max=100"`
    SortBy   string `json:"sort_by,omitempty" validate:"omitempty,oneof=relevance date title"`
    SortDesc bool   `json:"sort_desc,omitempty"`
}

v1.Get("/search", validationMiddleware.ValidateQuery(&SearchQuery{}), searchHandler)
```

## Testing Validation

### Unit Testing Validation

```go
func TestUserRegistrationValidation(t *testing.T) {
    validator := validation.NewValidator()
    
    // Valid case
    validUser := &validation.UserRegistration{
        Email:     "test@example.com",
        Username:  "testuser",
        FirstName: "Test",
        LastName:  "User",
        Password:  "SecurePass123!",
        ConfirmPassword: "SecurePass123!",
    }
    
    err := validator.Validate(validUser)
    assert.NoError(t, err)
    
    // Invalid case
    invalidUser := &validation.UserRegistration{
        Email:     "invalid-email",
        Username:  "a", // too short
        FirstName: "Test",
        LastName:  "User",
        Password:  "weak", // too weak
        ConfirmPassword: "different",
    }
    
    err = validator.Validate(invalidUser)
    assert.Error(t, err)
    
    // Check specific field errors
    if validationErrors, ok := err.(*validation.ValidationErrors); ok {
        assert.True(t, validationErrors.HasFieldError("email"))
        assert.True(t, validationErrors.HasFieldError("username"))
        assert.True(t, validationErrors.HasFieldError("password"))
        assert.True(t, validationErrors.HasFieldError("confirm_password"))
    }
}
```

### Integration Testing

```go
func TestUserRegistrationEndpoint(t *testing.T) {
    app := fiber.New()
    validationMiddleware := middleware.NewValidationMiddleware()
    
    app.Post("/users/register", 
        validationMiddleware.ValidateBody(&validation.UserRegistration{}),
        func(c *fiber.Ctx) error {
            return c.JSON(fiber.Map{"message": "success"})
        })
    
    // Test valid request
    validBody := map[string]interface{}{
        "email":             "test@example.com",
        "username":          "testuser",
        "first_name":        "Test",
        "last_name":         "User",
        "password":          "SecurePass123!",
        "confirm_password":  "SecurePass123!",
    }
    
    req := httptest.NewRequest("POST", "/users/register", strings.NewReader(json.Marshal(validBody)))
    req.Header.Set("Content-Type", "application/json")
    
    resp, err := app.Test(req)
    assert.NoError(t, err)
    assert.Equal(t, 200, resp.StatusCode)
    
    // Test invalid request
    invalidBody := map[string]interface{}{
        "email": "invalid-email",
        // missing required fields
    }
    
    req = httptest.NewRequest("POST", "/users/register", strings.NewReader(json.Marshal(invalidBody)))
    req.Header.Set("Content-Type", "application/json")
    
    resp, err = app.Test(req)
    assert.NoError(t, err)
    assert.Equal(t, 422, resp.StatusCode)
}
```

## Best Practices

### 1. Struct Organization

```go
// Group related validation structs
package validation

// User-related validations
type UserRegistration struct { ... }
type UserLogin struct { ... }
type UserUpdate struct { ... }

// Post-related validations
type PostCreate struct { ... }
type PostUpdate struct { ... }
type CommentCreate struct { ... }
```

### 2. Error Handling

```go
// Always check validation results
func handler(c *fiber.Ctx) error {
    data, ok := middleware.GetValidatedBody[MyStruct](c)
    if !ok {
        return utils.NewValidationResponseBuilder(c).
            InternalServerError("Failed to process request").
            Send(c)
    }
    
    // Use validated data
}
```

### 3. Custom Validators

```go
// Create reusable custom validators
func validateBusinessLogic(fl validator.FieldLevel) bool {
    // Custom validation logic
    return true
}

// Register in validator constructor
func NewValidator() *Validator {
    v := validator.New()
    v.RegisterValidation("business_logic", validateBusinessLogic)
    return &Validator{validate: v}
}
```

### 4. Performance Considerations

```go
// Use pointer receivers for large structs
type LargeStruct struct {
    // many fields
}

// Validate with pointer
validationMiddleware.ValidateBody(&LargeStruct{})

// Use partial validation for updates
validationMiddleware.ValidatePartial(&UserUpdate{}, "email", "username")
```

## Available Endpoints

The validation system includes example endpoints at `/api/v1/examples/`:

- `POST /users/register` - User registration validation
- `POST /users/login` - User login validation
- `PUT /users/:id` - User update validation
- `POST /users/change-password` - Password change validation
- `POST /posts` - Post creation validation
- `PUT /posts/:id` - Post update validation
- `POST /posts/:id/comments` - Comment creation validation
- `GET /search` - Search query validation
- `GET /posts` - Pagination validation
- `GET /reports` - Date range validation
- `POST /contact` - Contact form validation
- `POST /newsletter` - Newsletter subscription validation
- `POST /upload` - File upload validation
- `POST /custom` - Custom validation example
- `PATCH /users/:id/partial` - Partial validation example

## Configuration

### Environment Variables

No additional environment variables are required for the validation system. It works out of the box with the existing configuration.

### Customization

You can customize validation behavior by:

1. **Adding custom validators** in `internal/validation/validator.go`
2. **Creating validation structs** for your specific use cases
3. **Modifying error responses** in `internal/utils/validation_errors.go`
4. **Extending middleware** in `internal/middleware/validation.go`

## Security Considerations

1. **Input Sanitization**: Validation ensures data format but doesn't sanitize content
2. **SQL Injection**: Use parameterized queries (SQLC helps with this)
3. **XSS Protection**: Sanitize user-generated content before rendering
4. **Rate Limiting**: Combine validation with rate limiting for protection
5. **File Uploads**: Validate file types, sizes, and scan for malware

## Troubleshooting

### Common Issues

1. **Import Errors**: Run `go mod tidy` to ensure dependencies are downloaded
2. **Validation Not Working**: Ensure middleware is applied before handlers
3. **Custom Validators Not Found**: Register validators in the constructor
4. **Error Response Format**: Check the validation error helper configuration

### Debug Tips

```go
// Enable verbose logging for validation
validator := validation.NewValidator()
err := validator.Validate(data)
if err != nil {
    log.Printf("Validation errors: %+v", err)
}
```

## Migration Guide

### From Manual Validation

```go
// Before: Manual validation
func handler(c *fiber.Ctx) error {
    var user UserRegistration
    if err := c.BodyParser(&user); err != nil {
        return c.Status(400).JSON(fiber.Map{"error": "Invalid JSON"})
    }
    
    if user.Email == "" {
        return c.Status(400).JSON(fiber.Map{"error": "Email required"})
    }
    
    if !strings.Contains(user.Email, "@") {
        return c.Status(400).JSON(fiber.Map{"error": "Invalid email"})
    }
    
    // ... more manual validation
}

// After: Struct-based validation
func handler(c *fiber.Ctx) error {
    user, ok := middleware.GetValidatedBody[UserRegistration](c)
    if !ok {
        return // validation middleware already sent error response
    }
    
    // user is validated and ready to use
}
```

This validation system provides a robust, maintainable, and secure foundation for input validation in your Fiber application.