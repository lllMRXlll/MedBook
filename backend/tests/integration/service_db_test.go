package integration_test

import (
	"testing"
	"time"

	"medbook/backend/internal/model"
)

func TestServiceAppointmentLifecyclePersistsToSQLite(t *testing.T) {
	app := newTestApp(t)

	initialSpecializations, err := app.service.ListSpecializations()
	if err != nil {
		t.Fatalf("list specializations: %v", err)
	}
	if len(initialSpecializations) == 0 {
		t.Fatal("expected seeded specializations")
	}

	session, err := app.service.Register(model.RegisterRequest{
		FullName: "Integration User",
		Email:    "integration@example.com",
		Phone:    "+79990001122",
		Password: "strong-password",
	})
	if err != nil {
		t.Fatalf("register user: %v", err)
	}

	userFromDB, err := app.store.GetUserByID(session.User.ID)
	if err != nil {
		t.Fatalf("load registered user from db: %v", err)
	}
	if userFromDB.Email != "integration@example.com" {
		t.Fatalf("unexpected stored email: %s", userFromDB.Email)
	}

	firstSlot := app.mustFindAvailableSlot(t, "doctor-1", "")
	booked, err := app.service.BookAppointment(session.User.ID, model.BookAppointmentRequest{
		DoctorID:    "doctor-1",
		ScheduledAt: firstSlot,
	})
	if err != nil {
		t.Fatalf("book appointment: %v", err)
	}

	storedAppointments, err := app.store.ListAppointmentsByUser(session.User.ID)
	if err != nil {
		t.Fatalf("list appointments from db: %v", err)
	}
	if len(storedAppointments) != 1 {
		t.Fatalf("unexpected appointments count after booking: %d", len(storedAppointments))
	}
	if storedAppointments[0].ID != booked.ID {
		t.Fatalf("unexpected appointment id in db: %s", storedAppointments[0].ID)
	}

	secondSlot := app.mustFindAvailableSlot(t, "doctor-1", booked.ID, booked.ScheduledAt)
	rescheduled, err := app.service.RescheduleAppointment(
		session.User.ID,
		booked.ID,
		model.RescheduleAppointmentRequest{ScheduledAt: secondSlot},
	)
	if err != nil {
		t.Fatalf("reschedule appointment: %v", err)
	}
	if !rescheduled.ScheduledAt.Equal(secondSlot) {
		t.Fatalf("unexpected rescheduled time: %s", rescheduled.ScheduledAt.Format(time.RFC3339))
	}

	storedAfterReschedule, err := app.store.GetAppointmentByIDForUser(booked.ID, session.User.ID)
	if err != nil {
		t.Fatalf("load appointment after reschedule: %v", err)
	}
	if !storedAfterReschedule.ScheduledAt.Equal(secondSlot) {
		t.Fatalf("db did not persist new scheduledAt: %s", storedAfterReschedule.ScheduledAt.Format(time.RFC3339))
	}

	if err := app.service.CancelAppointment(session.User.ID, booked.ID); err != nil {
		t.Fatalf("cancel appointment: %v", err)
	}

	storedAfterCancel, err := app.store.GetAppointmentByIDForUser(booked.ID, session.User.ID)
	if err != nil {
		t.Fatalf("load appointment after cancel: %v", err)
	}
	if storedAfterCancel.Status != "cancelled" {
		t.Fatalf("unexpected appointment status in db: %s", storedAfterCancel.Status)
	}
}
