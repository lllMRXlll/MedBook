package httptransport

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	chimiddleware "github.com/go-chi/chi/v5/middleware"

	"medbook/backend/internal/config"
	"medbook/backend/internal/model"
	"medbook/backend/internal/service"
)

type Handler struct {
	service       *service.Service
	allowedOrigin string
}

type contextKey string

const (
	userContextKey  contextKey = "auth_user"
	tokenContextKey contextKey = "auth_token"
)

func NewRouter(cfg config.Config, svc *service.Service) http.Handler {
	handler := &Handler{
		service:       svc,
		allowedOrigin: cfg.AllowedOrigin,
	}

	router := chi.NewRouter()
	router.Use(chimiddleware.RequestID)
	router.Use(chimiddleware.RealIP)
	router.Use(chimiddleware.Recoverer)
	router.Use(chimiddleware.Timeout(cfg.RequestTimeout))
	router.Use(handler.corsMiddleware)

	router.Get("/health", handler.handleHealth)

	router.Route("/api/v1", func(r chi.Router) {
		r.Post("/auth/login", handler.handleLogin)
		r.Post("/auth/register", handler.handleRegister)

		r.Get("/specializations", handler.handleListSpecializations)
		r.Get("/doctors", handler.handleListDoctors)
		r.Get("/doctors/{doctorID}", handler.handleGetDoctor)
		r.Get("/doctors/{doctorID}/slots", handler.handleGetDoctorSlots)

		r.Group(func(auth chi.Router) {
			auth.Use(handler.authMiddleware)

			auth.Post("/auth/logout", handler.handleLogout)

			auth.Get("/appointments", handler.handleListAppointments)
			auth.Post("/appointments", handler.handleBookAppointment)
			auth.Patch("/appointments/{appointmentID}/cancel", handler.handleCancelAppointment)
			auth.Patch("/appointments/{appointmentID}/reschedule", handler.handleRescheduleAppointment)

			auth.Get("/profile", handler.handleGetProfile)
			auth.Put("/profile", handler.handleUpdateProfile)
		})
	})

	return router
}

func (h *Handler) corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", h.allowedOrigin)
		w.Header().Set("Access-Control-Allow-Headers", "Authorization, Content-Type")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, OPTIONS")

		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}

		next.ServeHTTP(w, r)
	})
}

func (h *Handler) authMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		header := strings.TrimSpace(r.Header.Get("Authorization"))
		if !strings.HasPrefix(strings.ToLower(header), "bearer ") {
			writeError(w, http.StatusUnauthorized, "Требуется авторизация.")
			return
		}

		token := strings.TrimSpace(header[len("Bearer "):])
		user, err := h.service.Authenticate(token)
		if err != nil {
			writeServiceError(w, err)
			return
		}

		ctx := context.WithValue(r.Context(), userContextKey, user)
		ctx = context.WithValue(ctx, tokenContextKey, token)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

func currentUser(ctx context.Context) model.User {
	user, _ := ctx.Value(userContextKey).(model.User)
	return user
}

func currentToken(ctx context.Context) string {
	token, _ := ctx.Value(tokenContextKey).(string)
	return token
}

func decodeJSON(r *http.Request, destination any) error {
	decoder := json.NewDecoder(io.LimitReader(r.Body, 1<<20))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(destination); err != nil {
		return err
	}
	if err := decoder.Decode(&struct{}{}); err != io.EOF {
		return errors.New("multiple json values")
	}
	return nil
}

func writeJSON(w http.ResponseWriter, status int, payload any) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(payload)
}

func writeError(w http.ResponseWriter, status int, message string) {
	writeJSON(w, status, model.ErrorResponse{Message: message})
}

func writeServiceError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, service.ErrInvalidCredentials):
		writeError(w, http.StatusUnauthorized, "Неверный логин или пароль.")
	case errors.Is(err, service.ErrUserAlreadyExists):
		writeError(w, http.StatusConflict, "Пользователь с такими данными уже существует.")
	case errors.Is(err, service.ErrSlotUnavailable):
		writeError(w, http.StatusConflict, "Выбранное время уже занято.")
	case errors.Is(err, service.ErrUnauthorized):
		writeError(w, http.StatusUnauthorized, "Требуется авторизация.")
	case errors.Is(err, service.ErrNotFound):
		writeError(w, http.StatusNotFound, "Ресурс не найден.")
	case errors.Is(err, service.ErrValidation):
		writeError(w, http.StatusBadRequest, "Некорректные данные запроса.")
	default:
		writeError(w, http.StatusInternalServerError, "Внутренняя ошибка сервера.")
	}
}

func parseDateParam(value string) (time.Time, error) {
	if value == "" {
		return time.Time{}, errors.New("empty date")
	}
	return parseFlexibleTimeString(value)
}

func parseFlexibleTimeString(value string) (time.Time, error) {
	layouts := []string{
		time.RFC3339Nano,
		time.RFC3339,
		"2006-01-02T15:04:05.000",
		"2006-01-02T15:04:05",
		"2006-01-02",
	}

	for _, layout := range layouts {
		var (
			parsed time.Time
			err    error
		)
		if strings.Contains(layout, "Z07:00") {
			parsed, err = time.Parse(layout, value)
		} else {
			parsed, err = time.ParseInLocation(layout, value, time.Local)
		}
		if err == nil {
			return parsed, nil
		}
	}

	return time.Time{}, errors.New("invalid date")
}
