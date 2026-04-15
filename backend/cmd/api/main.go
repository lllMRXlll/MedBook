package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"medbook/backend/internal/config"
	"medbook/backend/internal/service"
	"medbook/backend/internal/store"
	httptransport "medbook/backend/internal/transport/http"
)

func main() {
	cfg := config.Load()

	repo, err := store.Open(cfg.DatabasePath)
	if err != nil {
		log.Fatalf("open store: %v", err)
	}
	defer repo.Close()

	if err := repo.Migrate(); err != nil {
		log.Fatalf("migrate database: %v", err)
	}
	if err := repo.Seed(cfg.SeedDataDir); err != nil {
		log.Fatalf("seed database: %v", err)
	}
	if err := repo.CleanupExpiredSessions(); err != nil {
		log.Printf("cleanup sessions: %v", err)
	}

	svc := service.New(repo, cfg.SessionTTL)
	router := httptransport.NewRouter(cfg, svc)

	server := &http.Server{
		Addr:              ":" + cfg.Port,
		Handler:           router,
		ReadHeaderTimeout: 5 * time.Second,
	}

	go func() {
		log.Printf("backend started on http://localhost:%s", cfg.Port)
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("listen server: %v", err)
		}
	}()

	stop := make(chan os.Signal, 1)
	signal.Notify(stop, syscall.SIGINT, syscall.SIGTERM)
	<-stop

	ctx, cancel := context.WithTimeout(context.Background(), cfg.ShutdownTimeout)
	defer cancel()

	if err := server.Shutdown(ctx); err != nil {
		log.Fatalf("shutdown server: %v", err)
	}

	log.Println("backend stopped")
}
