package main

import (
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/favicon"
	"github.com/gofiber/fiber/v2/middleware/requestid"

	"main.go/internal/config"
	"main.go/internal/database"
	"main.go/internal/handlers"
	"main.go/internal/logger"
	"main.go/internal/middleware"
)

type Services struct {
	Config *config.Config
	Logger *logger.Logger
	DB     *database.DB
}

func (s *Services) Close() {
	if s == nil {
		return
	}
	if s.DB != nil {
		_ = s.DB.Close()
	}
	if s.Logger != nil {
		_ = s.Logger.Sync()
	}
}

func main() {
	// Load configuration
	cfg, err := config.LoadConfig()
	if err != nil {
		log.Fatalf("Failed to load configuration: %v", err)
	}

	// Initialize logger
	zapLogger, err := logger.New(cfg.AppEnv)
	if err != nil {
		log.Fatalf("Failed to initialize logger: %v", err)
	}

	services := &Services{Config: cfg, Logger: zapLogger}
	defer services.Close()

	logFeatureMatrix(services)

	// Initialize optional database connection
	if cfg.DatabaseEnabled() {
		services.DB, err = database.NewConnection(cfg.DBURL)
		if err != nil {
			services.Logger.Warn("Database feature enabled but connection failed; continuing without DB")
		} else {
			services.Logger.Info("Database connected successfully")
		}
	} else {
		services.Logger.Info("Database feature disabled or DB_URL not provided")
	}

	// Create Fiber app
	app := fiber.New(fiber.Config{
		Prefork:       false,
		CaseSensitive: true,
		StrictRouting: false,
		ServerHeader:  "Fiber Server",
		AppName:       cfg.AppName,
		ErrorHandler: func(c *fiber.Ctx, err error) error {
			code := fiber.StatusInternalServerError
			if e, ok := err.(*fiber.Error); ok {
				code = e.Code
			}

			return c.Status(code).JSON(fiber.Map{
				"error":   "Internal Server Error",
				"message": err.Error(),
				"status":  code,
			})
		},
	})

	// Global middleware
	app.Use(middleware.Recover())
	app.Use(requestid.New())
	app.Use(favicon.New(favicon.Config{
		File: "./statics/favicon.ico",
		URL:  "favicon.ico",
	}))

	// Conditional middleware based on configuration
	if cfg.CORS {
		app.Use(middleware.CORS(true))
	}

	if cfg.Compress {
		app.Use(middleware.Compression(true, cfg.CompressLevel))
	}

	if cfg.CSRF {
		app.Use(middleware.CSRF(true))
	}

	// Initialize handlers with configuration-aware dependencies
	healthHandler := handlers.NewHealthHandler(cfg, services.DB)
	apiHandler := handlers.NewAPIHandler(cfg)

	// Routes
	app.Get("/", apiHandler.Homepage)
	apiV1 := app.Group("/api/v1")

	// Health check routes
	app.Get("/health", healthHandler.Check)
	app.Get("/ready", healthHandler.Ready)
	app.Get("/live", healthHandler.Live)

	// API routes
	apiV1.Get("/", apiHandler.Welcome)
	apiV1.Get("/status", apiHandler.Status)

	// Static files
	app.Static("/static", "./statics")

	// 404 handler
	app.Use(func(c *fiber.Ctx) error {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"error":   "Not Found",
			"message": "The requested resource was not found",
			"status":  404,
		})
	})

	// Start server in a goroutine
	addr := fmt.Sprintf(":%s", cfg.Port)
	go func() {
		services.Logger.Info("Starting server on " + addr + " in " + cfg.AppEnv + " mode")

		if err := app.Listen(addr); err != nil {
			services.Logger.Fatal("Failed to start server")
		}
	}()

	// Wait for interrupt signal to gracefully shutdown the server
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	services.Logger.Info("Shutting down server...")

	// Shutdown Fiber app
	if err := app.Shutdown(); err != nil {
		services.Logger.Fatal("Server forced to shutdown")
	}

	services.Logger.Info("Server exited")
}

func logFeatureMatrix(s *Services) {
	if s == nil || s.Logger == nil || s.Config == nil {
		return
	}

	cfg := s.Config
	s.Logger.Info(fmt.Sprintf(
		"Feature toggles -> database=%t cache=%t auth=%t mail=%t aws=%t pusher=%t",
		cfg.Features.Database,
		cfg.Features.Cache,
		cfg.Features.Auth,
		cfg.Features.Mail,
		cfg.Features.AWS,
		cfg.Features.Pusher,
	))

	if cfg.Features.Database && cfg.DBURL == "" {
		s.Logger.Warn("FEATURE_DATABASE is true but DB_URL is empty; database bootstrap skipped")
	}
	if cfg.Features.Auth && cfg.AuthSecret == "" {
		s.Logger.Warn("FEATURE_AUTH is true but AUTH_SECRET is missing")
	}
	if cfg.Features.Mail && cfg.MailConfig.Host == "" {
		s.Logger.Warn("FEATURE_MAIL is true but MAIL_HOST is missing")
	}
	if cfg.Features.AWS && (cfg.AWSConfig.AccessKeyID == "" || cfg.AWSConfig.SecretAccessKey == "") {
		s.Logger.Warn("FEATURE_AWS is true but AWS credentials are incomplete")
	}
	if cfg.Features.Pusher && (cfg.PusherConfig.AppID == "" || cfg.PusherConfig.AppKey == "" || cfg.PusherConfig.AppSecret == "") {
		s.Logger.Warn("FEATURE_PUSHER is true but Pusher credentials are incomplete")
	}
}
