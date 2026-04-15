package httptransport

import (
	"net/http"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"

	"medbook/backend/internal/model"
)

type bookAppointmentPayload struct {
	DoctorID    string `json:"doctorId"`
	ScheduledAt string `json:"scheduledAt"`
}

type rescheduleAppointmentPayload struct {
	ScheduledAt string `json:"scheduledAt"`
}

type updateProfilePayload struct {
	FullName  string  `json:"fullName"`
	Email     string  `json:"email"`
	Phone     string  `json:"phone"`
	BirthDate *string `json:"birthDate"`
	City      *string `json:"city"`
}

func (h *Handler) handleHealth(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

func (h *Handler) handleLogin(w http.ResponseWriter, r *http.Request) {
	var request model.LoginRequest
	if err := decodeJSON(r, &request); err != nil {
		writeError(w, http.StatusBadRequest, "Не удалось прочитать тело запроса.")
		return
	}

	session, err := h.service.Login(request)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, session)
}

func (h *Handler) handleRegister(w http.ResponseWriter, r *http.Request) {
	var request model.RegisterRequest
	if err := decodeJSON(r, &request); err != nil {
		writeError(w, http.StatusBadRequest, "Не удалось прочитать тело запроса.")
		return
	}

	session, err := h.service.Register(request)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusCreated, session)
}

func (h *Handler) handleLogout(w http.ResponseWriter, r *http.Request) {
	if err := h.service.Logout(currentToken(r.Context())); err != nil {
		writeServiceError(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) handleListSpecializations(w http.ResponseWriter, _ *http.Request) {
	items, err := h.service.ListSpecializations()
	if err != nil {
		writeServiceError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, items)
}

func (h *Handler) handleListDoctors(w http.ResponseWriter, r *http.Request) {
	items, err := h.service.ListDoctors(
		r.URL.Query().Get("specializationId"),
		r.URL.Query().Get("query"),
	)
	if err != nil {
		writeServiceError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, items)
}

func (h *Handler) handleGetDoctor(w http.ResponseWriter, r *http.Request) {
	doctor, err := h.service.GetDoctor(chi.URLParam(r, "doctorID"))
	if err != nil {
		writeServiceError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, doctor)
}

func (h *Handler) handleGetDoctorSlots(w http.ResponseWriter, r *http.Request) {
	date, err := parseDateParam(strings.TrimSpace(r.URL.Query().Get("date")))
	if err != nil {
		writeError(w, http.StatusBadRequest, "Параметр date должен быть в формате RFC3339 или YYYY-MM-DD.")
		return
	}

	slots, err := h.service.GetAvailableSlots(
		chi.URLParam(r, "doctorID"),
		date,
		strings.TrimSpace(r.URL.Query().Get("ignoreAppointmentId")),
	)
	if err != nil {
		writeServiceError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, slots)
}

func (h *Handler) handleListAppointments(w http.ResponseWriter, r *http.Request) {
	items, err := h.service.ListAppointments(currentUser(r.Context()).ID)
	if err != nil {
		writeServiceError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, items)
}

func (h *Handler) handleBookAppointment(w http.ResponseWriter, r *http.Request) {
	var payload bookAppointmentPayload
	if err := decodeJSON(r, &payload); err != nil {
		writeError(w, http.StatusBadRequest, "Не удалось прочитать тело запроса.")
		return
	}

	scheduledAt, err := parseFlexibleTimeString(strings.TrimSpace(payload.ScheduledAt))
	if err != nil {
		writeError(w, http.StatusBadRequest, "Поле scheduledAt должно быть в ISO-формате даты.")
		return
	}

	request := model.BookAppointmentRequest{
		DoctorID:    strings.TrimSpace(payload.DoctorID),
		ScheduledAt: scheduledAt,
	}

	appointment, err := h.service.BookAppointment(currentUser(r.Context()).ID, request)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusCreated, appointment)
}

func (h *Handler) handleCancelAppointment(w http.ResponseWriter, r *http.Request) {
	if err := h.service.CancelAppointment(currentUser(r.Context()).ID, chi.URLParam(r, "appointmentID")); err != nil {
		writeServiceError(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) handleRescheduleAppointment(w http.ResponseWriter, r *http.Request) {
	var payload rescheduleAppointmentPayload
	if err := decodeJSON(r, &payload); err != nil {
		writeError(w, http.StatusBadRequest, "Не удалось прочитать тело запроса.")
		return
	}

	scheduledAt, err := parseFlexibleTimeString(strings.TrimSpace(payload.ScheduledAt))
	if err != nil {
		writeError(w, http.StatusBadRequest, "Поле scheduledAt должно быть в ISO-формате даты.")
		return
	}

	request := model.RescheduleAppointmentRequest{ScheduledAt: scheduledAt}
	appointment, err := h.service.RescheduleAppointment(
		currentUser(r.Context()).ID,
		chi.URLParam(r, "appointmentID"),
		request,
	)
	if err != nil {
		writeServiceError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, appointment)
}

func (h *Handler) handleGetProfile(w http.ResponseWriter, r *http.Request) {
	profile, err := h.service.GetProfile(currentUser(r.Context()).ID)
	if err != nil {
		writeServiceError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, profile)
}

func (h *Handler) handleUpdateProfile(w http.ResponseWriter, r *http.Request) {
	var payload updateProfilePayload
	if err := decodeJSON(r, &payload); err != nil {
		writeError(w, http.StatusBadRequest, "Не удалось прочитать тело запроса.")
		return
	}

	birthDate, err := parseOptionalPayloadTime(payload.BirthDate)
	if err != nil {
		writeError(w, http.StatusBadRequest, "Поле birthDate должно быть в ISO-формате даты.")
		return
	}

	request := model.UpdateProfileRequest{
		FullName:  payload.FullName,
		Email:     payload.Email,
		Phone:     payload.Phone,
		BirthDate: birthDate,
		City:      payload.City,
	}

	profile, err := h.service.UpdateProfile(currentUser(r.Context()).ID, request)
	if err != nil {
		writeServiceError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, profile)
}

func parseOptionalPayloadTime(value *string) (*time.Time, error) {
	if value == nil || strings.TrimSpace(*value) == "" {
		return nil, nil
	}
	parsed, err := parseFlexibleTimeString(strings.TrimSpace(*value))
	if err != nil {
		return nil, err
	}
	return &parsed, nil
}
