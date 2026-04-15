package integration_test

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"path/filepath"
	"runtime"
	"testing"
	"time"

	"medbook/backend/internal/config"
	"medbook/backend/internal/model"
	"medbook/backend/internal/service"
	"medbook/backend/internal/store"
	httptransport "medbook/backend/internal/transport/http"
)

type testApp struct {
	store   *store.Store
	service *service.Service
	router  http.Handler
}

func newTestApp(t *testing.T) *testApp {
	t.Helper()

	databasePath := filepath.Join(t.TempDir(), "medbook-test.db")
	repo, err := store.Open(databasePath)
	if err != nil {
		t.Fatalf("open test store: %v", err)
	}
	t.Cleanup(func() {
		if err := repo.Close(); err != nil {
			t.Fatalf("close test store: %v", err)
		}
	})

	if err := repo.Migrate(); err != nil {
		t.Fatalf("migrate test store: %v", err)
	}
	if err := repo.Seed(seedDataDir(t)); err != nil {
		t.Fatalf("seed test store: %v", err)
	}

	svc := service.New(repo, 2*time.Hour)
	cfg := config.Config{
		AllowedOrigin:  "*",
		RequestTimeout: 5 * time.Second,
	}

	return &testApp{
		store:   repo,
		service: svc,
		router:  httptransport.NewRouter(cfg, svc),
	}
}

func seedDataDir(t *testing.T) string {
	t.Helper()

	_, filename, _, ok := runtime.Caller(0)
	if !ok {
		t.Fatal("resolve test file path")
	}

	return filepath.Clean(filepath.Join(
		filepath.Dir(filename),
		"..",
		"..",
		"..",
		"assets",
		"mock",
	))
}

func (app *testApp) mustFindAvailableSlot(t *testing.T, doctorID string, ignoreAppointmentID string, exclude ...time.Time) time.Time {
	t.Helper()

	excluded := make(map[string]struct{}, len(exclude))
	for _, item := range exclude {
		excluded[item.Format(time.RFC3339Nano)] = struct{}{}
	}

	start := time.Now().Add(24 * time.Hour)
	for dayOffset := 0; dayOffset < 30; dayOffset++ {
		date := start.AddDate(0, 0, dayOffset)
		slots, err := app.service.GetAvailableSlots(doctorID, date, ignoreAppointmentID)
		if err != nil {
			t.Fatalf("load available slots: %v", err)
		}

		for _, slot := range slots {
			if !slot.IsAvailable {
				continue
			}
			if _, skipped := excluded[slot.StartsAt.Format(time.RFC3339Nano)]; skipped {
				continue
			}
			return slot.StartsAt
		}
	}

	t.Fatalf("no available slot found for doctor %s", doctorID)
	return time.Time{}
}

func (app *testApp) requestJSON(t *testing.T, method, path, token string, body any) *httptest.ResponseRecorder {
	t.Helper()

	var payload bytes.Buffer
	if body != nil {
		if err := json.NewEncoder(&payload).Encode(body); err != nil {
			t.Fatalf("encode request body: %v", err)
		}
	}

	request := httptest.NewRequest(method, path, &payload)
	if body != nil {
		request.Header.Set("Content-Type", "application/json")
	}
	if token != "" {
		request.Header.Set("Authorization", "Bearer "+token)
	}

	recorder := httptest.NewRecorder()
	app.router.ServeHTTP(recorder, request)
	return recorder
}

func decodeResponse[T any](t *testing.T, recorder *httptest.ResponseRecorder) T {
	t.Helper()

	var payload T
	if err := json.Unmarshal(recorder.Body.Bytes(), &payload); err != nil {
		t.Fatalf("decode response: %v, body=%s", err, recorder.Body.String())
	}
	return payload
}

func assertStatus(t *testing.T, recorder *httptest.ResponseRecorder, expected int) {
	t.Helper()
	if recorder.Code != expected {
		t.Fatalf("unexpected status: got %d want %d body=%s", recorder.Code, expected, recorder.Body.String())
	}
}

func assertAppointmentPresent(t *testing.T, appointments []model.Appointment, appointmentID string) model.Appointment {
	t.Helper()

	for _, item := range appointments {
		if item.ID == appointmentID {
			return item
		}
	}

	t.Fatalf("appointment %s not found in response", appointmentID)
	return model.Appointment{}
}
