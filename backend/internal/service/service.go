package service

import (
	"crypto/rand"
	"encoding/base64"
	"errors"
	"fmt"
	"strings"
	"time"

	"golang.org/x/crypto/bcrypt"

	"medbook/backend/internal/model"
	"medbook/backend/internal/store"
)

var (
	ErrInvalidCredentials = errors.New("invalid credentials")
	ErrUserAlreadyExists  = errors.New("user already exists")
	ErrNotFound           = errors.New("not found")
	ErrUnauthorized       = errors.New("unauthorized")
	ErrSlotUnavailable    = errors.New("slot unavailable")
	ErrValidation         = errors.New("validation failed")
)

type Service struct {
	store      *store.Store
	sessionTTL time.Duration
}

func New(repo *store.Store, sessionTTL time.Duration) *Service {
	return &Service{
		store:      repo,
		sessionTTL: sessionTTL,
	}
}

func (s *Service) Login(request model.LoginRequest) (model.AuthSession, error) {
	if strings.TrimSpace(request.Identifier) == "" || request.Password == "" {
		return model.AuthSession{}, fmt.Errorf("%w: identifier and password are required", ErrValidation)
	}

	user, err := s.store.FindUserByIdentifier(request.Identifier)
	if err != nil {
		if store.IsNotFound(err) {
			return model.AuthSession{}, ErrInvalidCredentials
		}
		return model.AuthSession{}, err
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(request.Password)); err != nil {
		return model.AuthSession{}, ErrInvalidCredentials
	}

	token, err := generateToken()
	if err != nil {
		return model.AuthSession{}, fmt.Errorf("generate token: %w", err)
	}

	if err := s.store.CreateSession(token, user.ID, time.Now().UTC().Add(s.sessionTTL)); err != nil {
		return model.AuthSession{}, err
	}

	return model.AuthSession{
		Token: token,
		User:  sanitizeUser(user),
	}, nil
}

func (s *Service) Register(request model.RegisterRequest) (model.AuthSession, error) {
	if strings.TrimSpace(request.FullName) == "" ||
		strings.TrimSpace(request.Email) == "" ||
		strings.TrimSpace(request.Phone) == "" ||
		request.Password == "" {
		return model.AuthSession{}, fmt.Errorf("%w: all fields are required", ErrValidation)
	}

	exists, err := s.store.EmailOrPhoneExists(request.Email, request.Phone, "")
	if err != nil {
		return model.AuthSession{}, err
	}
	if exists {
		return model.AuthSession{}, ErrUserAlreadyExists
	}

	passwordHash, err := bcrypt.GenerateFromPassword([]byte(request.Password), bcrypt.DefaultCost)
	if err != nil {
		return model.AuthSession{}, fmt.Errorf("hash password: %w", err)
	}

	city := "Москва"
	user := model.User{
		ID:           generateID("user"),
		FullName:     strings.TrimSpace(request.FullName),
		Email:        strings.TrimSpace(request.Email),
		Phone:        strings.TrimSpace(request.Phone),
		PasswordHash: string(passwordHash),
		City:         &city,
	}

	if err := s.store.CreateUser(user); err != nil {
		return model.AuthSession{}, err
	}

	token, err := generateToken()
	if err != nil {
		return model.AuthSession{}, fmt.Errorf("generate token: %w", err)
	}
	if err := s.store.CreateSession(token, user.ID, time.Now().UTC().Add(s.sessionTTL)); err != nil {
		return model.AuthSession{}, err
	}

	return model.AuthSession{
		Token: token,
		User:  sanitizeUser(user),
	}, nil
}

func (s *Service) Authenticate(token string) (model.User, error) {
	if strings.TrimSpace(token) == "" {
		return model.User{}, ErrUnauthorized
	}

	user, err := s.store.GetUserByToken(token)
	if err != nil {
		if store.IsNotFound(err) {
			return model.User{}, ErrUnauthorized
		}
		return model.User{}, err
	}
	return sanitizeUser(user), nil
}

func (s *Service) Logout(token string) error {
	if strings.TrimSpace(token) == "" {
		return ErrUnauthorized
	}
	return s.store.DeleteSession(token)
}

func (s *Service) ListSpecializations() ([]model.Specialization, error) {
	return s.store.ListSpecializations()
}

func (s *Service) ListDoctors(specializationID, query string) ([]model.Doctor, error) {
	return s.store.ListDoctors(strings.TrimSpace(specializationID), strings.TrimSpace(query))
}

func (s *Service) GetDoctor(id string) (model.Doctor, error) {
	doctor, err := s.store.GetDoctorByID(id)
	if err != nil {
		if store.IsNotFound(err) {
			return model.Doctor{}, ErrNotFound
		}
		return model.Doctor{}, err
	}
	return doctor, nil
}

func (s *Service) GetAvailableSlots(doctorID string, date time.Time, ignoreAppointmentID string) ([]model.TimeSlot, error) {
	doctor, err := s.GetDoctor(doctorID)
	if err != nil {
		return nil, err
	}

	normalizedDate := time.Date(date.Year(), date.Month(), date.Day(), 0, 0, 0, 0, date.Location())
	if !containsWeekday(doctor.Schedule.WorkDays, normalizedDate) {
		return []model.TimeSlot{}, nil
	}

	bookedSlots, err := s.store.ListBookedSlots(doctor.ID, normalizedDate, ignoreAppointmentID)
	if err != nil {
		return nil, err
	}

	booked := make(map[string]struct{}, len(bookedSlots))
	for _, slot := range bookedSlots {
		booked[slot.Format(time.RFC3339Nano)] = struct{}{}
	}

	now := time.Now()
	current := time.Date(
		normalizedDate.Year(),
		normalizedDate.Month(),
		normalizedDate.Day(),
		doctor.Schedule.StartHour,
		0,
		0,
		0,
		normalizedDate.Location(),
	)
	finish := time.Date(
		normalizedDate.Year(),
		normalizedDate.Month(),
		normalizedDate.Day(),
		doctor.Schedule.EndHour,
		0,
		0,
		0,
		normalizedDate.Location(),
	)

	var slots []model.TimeSlot
	for current.Before(finish) {
		_, isBooked := booked[current.Format(time.RFC3339Nano)]
		slots = append(slots, model.TimeSlot{
			StartsAt:    current,
			IsAvailable: !isBooked && current.After(now),
		})
		current = current.Add(time.Duration(doctor.Schedule.SlotMinutes) * time.Minute)
	}

	return slots, nil
}

func (s *Service) ListAppointments(userID string) ([]model.Appointment, error) {
	return s.store.ListAppointmentsByUser(userID)
}

func (s *Service) BookAppointment(userID string, request model.BookAppointmentRequest) (model.Appointment, error) {
	if strings.TrimSpace(request.DoctorID) == "" || request.ScheduledAt.IsZero() {
		return model.Appointment{}, fmt.Errorf("%w: doctorId and scheduledAt are required", ErrValidation)
	}

	slots, err := s.GetAvailableSlots(request.DoctorID, request.ScheduledAt, "")
	if err != nil {
		return model.Appointment{}, err
	}
	if !slotAvailable(slots, request.ScheduledAt) {
		return model.Appointment{}, ErrSlotUnavailable
	}

	doctor, err := s.GetDoctor(request.DoctorID)
	if err != nil {
		return model.Appointment{}, err
	}

	appointmentID := generateID("appointment")
	if err := s.store.CreateAppointment(
		appointmentID,
		doctor.ID,
		userID,
		request.ScheduledAt,
		"scheduled",
		doctor.Location,
		doctor.Price,
	); err != nil {
		return model.Appointment{}, err
	}

	return s.store.GetAppointmentByIDForUser(appointmentID, userID)
}

func (s *Service) CancelAppointment(userID, appointmentID string) error {
	if err := s.store.UpdateAppointmentStatus(appointmentID, userID, "cancelled"); err != nil {
		if store.IsNotFound(err) {
			return ErrNotFound
		}
		return err
	}
	return nil
}

func (s *Service) RescheduleAppointment(
	userID string,
	appointmentID string,
	request model.RescheduleAppointmentRequest,
) (model.Appointment, error) {
	if request.ScheduledAt.IsZero() {
		return model.Appointment{}, fmt.Errorf("%w: scheduledAt is required", ErrValidation)
	}

	existing, err := s.store.GetAppointmentByIDForUser(appointmentID, userID)
	if err != nil {
		if store.IsNotFound(err) {
			return model.Appointment{}, ErrNotFound
		}
		return model.Appointment{}, err
	}

	slots, err := s.GetAvailableSlots(existing.DoctorID, request.ScheduledAt, appointmentID)
	if err != nil {
		return model.Appointment{}, err
	}
	if !slotAvailable(slots, request.ScheduledAt) {
		return model.Appointment{}, ErrSlotUnavailable
	}

	if err := s.store.UpdateAppointmentSchedule(appointmentID, userID, request.ScheduledAt); err != nil {
		if store.IsNotFound(err) {
			return model.Appointment{}, ErrNotFound
		}
		return model.Appointment{}, err
	}

	return s.store.GetAppointmentByIDForUser(appointmentID, userID)
}

func (s *Service) GetProfile(userID string) (model.User, error) {
	user, err := s.store.GetUserByID(userID)
	if err != nil {
		if store.IsNotFound(err) {
			return model.User{}, ErrNotFound
		}
		return model.User{}, err
	}
	return sanitizeUser(user), nil
}

func (s *Service) UpdateProfile(userID string, request model.UpdateProfileRequest) (model.User, error) {
	if strings.TrimSpace(request.FullName) == "" ||
		strings.TrimSpace(request.Email) == "" ||
		strings.TrimSpace(request.Phone) == "" {
		return model.User{}, fmt.Errorf("%w: fullName, email and phone are required", ErrValidation)
	}

	existing, err := s.store.GetUserByID(userID)
	if err != nil {
		if store.IsNotFound(err) {
			return model.User{}, ErrNotFound
		}
		return model.User{}, err
	}

	duplicate, err := s.store.EmailOrPhoneExists(request.Email, request.Phone, userID)
	if err != nil {
		return model.User{}, err
	}
	if duplicate {
		return model.User{}, ErrUserAlreadyExists
	}

	existing.FullName = strings.TrimSpace(request.FullName)
	existing.Email = strings.TrimSpace(request.Email)
	existing.Phone = strings.TrimSpace(request.Phone)
	existing.BirthDate = request.BirthDate
	existing.City = normalizeOptionalString(request.City)

	if err := s.store.UpdateUser(existing); err != nil {
		if store.IsNotFound(err) {
			return model.User{}, ErrNotFound
		}
		return model.User{}, err
	}

	return s.GetProfile(userID)
}

func sanitizeUser(user model.User) model.User {
	user.PasswordHash = ""
	return user
}

func normalizeOptionalString(value *string) *string {
	if value == nil {
		return nil
	}
	trimmed := strings.TrimSpace(*value)
	if trimmed == "" {
		return nil
	}
	return &trimmed
}

func containsWeekday(workDays []int, date time.Time) bool {
	current := int(date.Weekday())
	if current == 0 {
		current = 7
	}
	for _, day := range workDays {
		if day == current {
			return true
		}
	}
	return false
}

func slotAvailable(slots []model.TimeSlot, target time.Time) bool {
	for _, slot := range slots {
		if slot.StartsAt.Equal(target) {
			return slot.IsAvailable
		}
	}
	return false
}

func generateID(prefix string) string {
	return fmt.Sprintf("%s-%d", prefix, time.Now().UnixNano())
}

func generateToken() (string, error) {
	buffer := make([]byte, 32)
	if _, err := rand.Read(buffer); err != nil {
		return "", err
	}
	return base64.RawURLEncoding.EncodeToString(buffer), nil
}
