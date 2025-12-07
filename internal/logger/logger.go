package logger

import (
	"os"
	"path/filepath"

	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

// Logger represents the application logger
type Logger struct {
	*zap.Logger
}

// New creates a new logger instance
func New(environment string) (*Logger, error) {
	var config zap.Config

	switch environment {
	case "production":
		config = zap.NewProductionConfig()
		config.OutputPaths = []string{"stdout"}
		config.ErrorOutputPaths = []string{"stderr"}
	case "development":
		config = zap.NewDevelopmentConfig()
		config.OutputPaths = []string{"stdout"}
		config.ErrorOutputPaths = []string{"stderr"}
	default:
		config = zap.NewDevelopmentConfig()
		config.OutputPaths = []string{"stdout"}
		config.ErrorOutputPaths = []string{"stderr"}
	}

	// Configure the logger
	config.Level = zap.NewAtomicLevel()
	config.EncoderConfig = zapcore.EncoderConfig{
		TimeKey:        "time",
		LevelKey:       "level",
		NameKey:        "logger",
		CallerKey:      "caller",
		MessageKey:     "msg",
		StacktraceKey:  "stacktrace",
		LineEnding:     zapcore.DefaultLineEnding,
		EncodeLevel:    zapcore.LowercaseLevelEncoder,
		EncodeTime:     zapcore.ISO8601TimeEncoder,
		EncodeDuration: zapcore.SecondsDurationEncoder,
		EncodeCaller:   zapcore.ShortCallerEncoder,
	}

	// Create the logger
	logger, err := config.Build()
	if err != nil {
		return nil, err
	}

	return &Logger{logger}, nil
}

// NewWithFile creates a new logger that also writes to a file
func NewWithFile(environment, logDir string) (*Logger, error) {
	// Ensure log directory exists
	if err := os.MkdirAll(logDir, 0750); err != nil {
		return nil, err
	}

	var config zap.Config

	switch environment {
	case "production":
		config = zap.NewProductionConfig()
		config.OutputPaths = []string{"stdout", filepath.Join(logDir, "app.log")}
		config.ErrorOutputPaths = []string{"stderr", filepath.Join(logDir, "error.log")}
	case "development":
		config = zap.NewDevelopmentConfig()
		config.OutputPaths = []string{"stdout", filepath.Join(logDir, "app.log")}
		config.ErrorOutputPaths = []string{"stderr", filepath.Join(logDir, "error.log")}
	default:
		config = zap.NewDevelopmentConfig()
		config.OutputPaths = []string{"stdout"}
		config.ErrorOutputPaths = []string{"stderr"}
	}

	// Configure the logger
	config.Level = zap.NewAtomicLevel()
	config.EncoderConfig = zapcore.EncoderConfig{
		TimeKey:        "time",
		LevelKey:       "level",
		NameKey:        "logger",
		CallerKey:      "caller",
		MessageKey:     "msg",
		StacktraceKey:  "stacktrace",
		LineEnding:     zapcore.DefaultLineEnding,
		EncodeLevel:    zapcore.LowercaseLevelEncoder,
		EncodeTime:     zapcore.ISO8601TimeEncoder,
		EncodeDuration: zapcore.SecondsDurationEncoder,
		EncodeCaller:   zapcore.ShortCallerEncoder,
	}

	// Create the logger
	logger, err := config.Build()
	if err != nil {
		return nil, err
	}

	return &Logger{logger}, nil
}

// WithFields returns a logger with additional fields
func (l *Logger) WithFields(fields ...zap.Field) *Logger {
	return &Logger{l.With(fields...)}
}

// Info logs an info message
func (l *Logger) Info(msg string, fields ...zap.Field) {
	l.Logger.Info(msg, fields...)
}

// Error logs an error message
func (l *Logger) Error(msg string, fields ...zap.Field) {
	l.Logger.Error(msg, fields...)
}

// Warn logs a warning message
func (l *Logger) Warn(msg string, fields ...zap.Field) {
	l.Logger.Warn(msg, fields...)
}

// Debug logs a debug message
func (l *Logger) Debug(msg string, fields ...zap.Field) {
	l.Logger.Debug(msg, fields...)
}

// Fatal logs a fatal message and exits
func (l *Logger) Fatal(msg string, fields ...zap.Field) {
	l.Logger.Fatal(msg, fields...)
}

// Sync flushes any buffered log entries
func (l *Logger) Sync() error {
	return l.Logger.Sync()
}
