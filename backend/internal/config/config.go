package config

import (
	"os"
	"path/filepath"
	"strconv"
	"time"
)

type Config struct {
	Port            string
	DatabasePath    string
	SeedDataDir     string
	SessionTTL      time.Duration
	AllowedOrigin   string
	RequestTimeout  time.Duration
	ShutdownTimeout time.Duration
}

func Load() Config {
	return Config{
		Port:            envOrDefault("PORT", "8080"),
		DatabasePath:    envOrDefault("DATABASE_PATH", filepath.Join("data", "medbook.db")),
		SeedDataDir:     envOrDefault("SEED_DATA_DIR", filepath.Join("..", "assets", "mock")),
		SessionTTL:      envDurationHours("SESSION_TTL_HOURS", 72),
		AllowedOrigin:   envOrDefault("ALLOWED_ORIGIN", "*"),
		RequestTimeout:  envDurationSeconds("REQUEST_TIMEOUT_SECONDS", 10),
		ShutdownTimeout: envDurationSeconds("SHUTDOWN_TIMEOUT_SECONDS", 10),
	}
}

func envOrDefault(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return fallback
}

func envDurationHours(key string, fallback int) time.Duration {
	value, err := strconv.Atoi(envOrDefault(key, strconv.Itoa(fallback)))
	if err != nil || value <= 0 {
		return time.Duration(fallback) * time.Hour
	}
	return time.Duration(value) * time.Hour
}

func envDurationSeconds(key string, fallback int) time.Duration {
	value, err := strconv.Atoi(envOrDefault(key, strconv.Itoa(fallback)))
	if err != nil || value <= 0 {
		return time.Duration(fallback) * time.Second
	}
	return time.Duration(value) * time.Second
}
