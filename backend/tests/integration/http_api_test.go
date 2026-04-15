package integration_test

import (
	"net/http"
	"testing"
	"time"

	"medbook/backend/internal/model"
)

func TestHTTPAPIAppointmentAndProfileFlow(t *testing.T) {
	app := newTestApp(t)

	healthResponse := app.requestJSON(t, http.MethodGet, "/health", "", nil)
	assertStatus(t, healthResponse, http.StatusOK)

	loginResponse := app.requestJSON(t, http.MethodPost, "/api/v1/auth/login", "", map[string]string{
		"identifier": "anna@example.com",
		"password":   "password123",
	})
	assertStatus(t, loginResponse, http.StatusOK)

	session := decodeResponse[model.AuthSession](t, loginResponse)
	if session.Token == "" {
		t.Fatal("expected auth token after login")
	}
	if session.User.ID != "user-1" {
		t.Fatalf("unexpected logged in user: %s", session.User.ID)
	}

	profileResponse := app.requestJSON(t, http.MethodGet, "/api/v1/profile", session.Token, nil)
	assertStatus(t, profileResponse, http.StatusOK)
	profile := decodeResponse[model.User](t, profileResponse)
	if profile.Email != "anna@example.com" {
		t.Fatalf("unexpected profile email: %s", profile.Email)
	}

	listBeforeResponse := app.requestJSON(t, http.MethodGet, "/api/v1/appointments", session.Token, nil)
	assertStatus(t, listBeforeResponse, http.StatusOK)
	appointmentsBefore := decodeResponse[[]model.Appointment](t, listBeforeResponse)
	if len(appointmentsBefore) != 3 {
		t.Fatalf("unexpected seeded appointments count: %d", len(appointmentsBefore))
	}

	firstSlot := app.mustFindAvailableSlot(t, "doctor-1", "")
	bookResponse := app.requestJSON(t, http.MethodPost, "/api/v1/appointments", session.Token, map[string]string{
		"doctorId":    "doctor-1",
		"scheduledAt": firstSlot.Format(time.RFC3339),
	})
	assertStatus(t, bookResponse, http.StatusCreated)
	bookedAppointment := decodeResponse[model.Appointment](t, bookResponse)

	listAfterBookResponse := app.requestJSON(t, http.MethodGet, "/api/v1/appointments", session.Token, nil)
	assertStatus(t, listAfterBookResponse, http.StatusOK)
	appointmentsAfterBook := decodeResponse[[]model.Appointment](t, listAfterBookResponse)
	if len(appointmentsAfterBook) != 4 {
		t.Fatalf("unexpected appointments count after booking: %d", len(appointmentsAfterBook))
	}

	bookedFromList := assertAppointmentPresent(t, appointmentsAfterBook, bookedAppointment.ID)
	if !bookedFromList.ScheduledAt.Equal(bookedAppointment.ScheduledAt) {
		t.Fatalf("stored appointment time mismatch: got %s want %s",
			bookedFromList.ScheduledAt.Format(time.RFC3339),
			bookedAppointment.ScheduledAt.Format(time.RFC3339),
		)
	}

	secondSlot := app.mustFindAvailableSlot(t, "doctor-1", bookedAppointment.ID, bookedAppointment.ScheduledAt)
	rescheduleResponse := app.requestJSON(
		t,
		http.MethodPatch,
		"/api/v1/appointments/"+bookedAppointment.ID+"/reschedule",
		session.Token,
		map[string]string{"scheduledAt": secondSlot.Format(time.RFC3339)},
	)
	assertStatus(t, rescheduleResponse, http.StatusOK)
	rescheduled := decodeResponse[model.Appointment](t, rescheduleResponse)
	if !rescheduled.ScheduledAt.Equal(secondSlot) {
		t.Fatalf("unexpected rescheduled time: %s", rescheduled.ScheduledAt.Format(time.RFC3339))
	}

	cancelResponse := app.requestJSON(
		t,
		http.MethodPatch,
		"/api/v1/appointments/"+bookedAppointment.ID+"/cancel",
		session.Token,
		nil,
	)
	assertStatus(t, cancelResponse, http.StatusNoContent)

	listAfterCancelResponse := app.requestJSON(t, http.MethodGet, "/api/v1/appointments", session.Token, nil)
	assertStatus(t, listAfterCancelResponse, http.StatusOK)
	appointmentsAfterCancel := decodeResponse[[]model.Appointment](t, listAfterCancelResponse)
	cancelledAppointment := assertAppointmentPresent(t, appointmentsAfterCancel, bookedAppointment.ID)
	if cancelledAppointment.Status != "cancelled" {
		t.Fatalf("unexpected appointment status after cancel: %s", cancelledAppointment.Status)
	}

	city := "Казань"
	birthDate := "1995-07-20"
	updateProfileResponse := app.requestJSON(t, http.MethodPut, "/api/v1/profile", session.Token, map[string]any{
		"fullName":  "Анна Смирнова Updated",
		"email":     "anna.updated@example.com",
		"phone":     "+79991230000",
		"birthDate": birthDate,
		"city":      city,
	})
	assertStatus(t, updateProfileResponse, http.StatusOK)

	updatedProfile := decodeResponse[model.User](t, updateProfileResponse)
	if updatedProfile.Email != "anna.updated@example.com" {
		t.Fatalf("unexpected updated email: %s", updatedProfile.Email)
	}
	if updatedProfile.City == nil || *updatedProfile.City != city {
		t.Fatalf("unexpected updated city: %v", updatedProfile.City)
	}

	userFromDB, err := app.store.GetUserByID("user-1")
	if err != nil {
		t.Fatalf("load updated user from db: %v", err)
	}
	if userFromDB.Email != "anna.updated@example.com" {
		t.Fatalf("db email was not updated: %s", userFromDB.Email)
	}
	if userFromDB.BirthDate == nil || userFromDB.BirthDate.Format("2006-01-02") != birthDate {
		t.Fatalf("db birthDate was not updated: %v", userFromDB.BirthDate)
	}
}
