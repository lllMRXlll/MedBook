package store

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"

	"golang.org/x/crypto/bcrypt"

	"medbook/backend/internal/model"
)

type seedUser struct {
	ID        string  `json:"id"`
	FullName  string  `json:"fullName"`
	Email     string  `json:"email"`
	Phone     string  `json:"phone"`
	Password  string  `json:"password"`
	BirthDate *string `json:"birthDate"`
	City      *string `json:"city"`
}

type seedDoctor struct {
	ID               string               `json:"id"`
	Name             string               `json:"name"`
	SpecializationID string               `json:"specializationId"`
	Description      string               `json:"description"`
	ExperienceYears  int                  `json:"experienceYears"`
	Rating           float64              `json:"rating"`
	Price            int                  `json:"price"`
	Location         string               `json:"location"`
	Featured         bool                 `json:"featured"`
	Schedule         model.DoctorSchedule `json:"schedule"`
}

type seedAppointment struct {
	ID          string `json:"id"`
	DoctorID    string `json:"doctorId"`
	UserID      string `json:"userId"`
	ScheduledAt string `json:"scheduledAt"`
	Status      string `json:"status"`
	Location    string `json:"location"`
	Price       int    `json:"price"`
}

func (s *Store) Seed(seedDir string) error {
	if err := s.seedUsers(seedDir); err != nil {
		return err
	}
	if err := s.seedSpecializations(seedDir); err != nil {
		return err
	}
	if err := s.seedDoctors(seedDir); err != nil {
		return err
	}
	if err := s.seedAppointments(seedDir); err != nil {
		return err
	}
	return nil
}

func (s *Store) seedUsers(seedDir string) error {
	count, err := s.countRows("users")
	if err != nil {
		return err
	}
	if count > 0 {
		return nil
	}

	var users []seedUser
	if err := readJSON(filepath.Join(seedDir, "users.json"), &users); err != nil {
		return fmt.Errorf("read users seed: %w", err)
	}

	for _, user := range users {
		birthDate, err := parseOptionalSeedTime(user.BirthDate)
		if err != nil {
			return fmt.Errorf("parse birth date for %s: %w", user.ID, err)
		}

		passwordHash, err := bcrypt.GenerateFromPassword([]byte(user.Password), bcrypt.DefaultCost)
		if err != nil {
			return fmt.Errorf("hash seed password for %s: %w", user.ID, err)
		}

		if err := s.CreateUser(model.User{
			ID:           user.ID,
			FullName:     user.FullName,
			Email:        user.Email,
			Phone:        user.Phone,
			PasswordHash: string(passwordHash),
			BirthDate:    birthDate,
			City:         user.City,
		}); err != nil {
			return fmt.Errorf("insert seed user %s: %w", user.ID, err)
		}
	}

	return nil
}

func (s *Store) seedSpecializations(seedDir string) error {
	count, err := s.countRows("specializations")
	if err != nil {
		return err
	}
	if count > 0 {
		return nil
	}

	var specializations []model.Specialization
	if err := readJSON(filepath.Join(seedDir, "specializations.json"), &specializations); err != nil {
		return fmt.Errorf("read specializations seed: %w", err)
	}

	for _, item := range specializations {
		if err := s.CreateSpecialization(item); err != nil {
			return fmt.Errorf("insert specialization %s: %w", item.ID, err)
		}
	}

	return nil
}

func (s *Store) seedDoctors(seedDir string) error {
	count, err := s.countRows("doctors")
	if err != nil {
		return err
	}
	if count > 0 {
		return nil
	}

	var doctors []seedDoctor
	if err := readJSON(filepath.Join(seedDir, "doctors.json"), &doctors); err != nil {
		return fmt.Errorf("read doctors seed: %w", err)
	}

	for _, doctor := range doctors {
		if err := s.CreateDoctor(model.Doctor{
			ID:               doctor.ID,
			Name:             doctor.Name,
			SpecializationID: doctor.SpecializationID,
			Description:      doctor.Description,
			ExperienceYears:  doctor.ExperienceYears,
			Rating:           doctor.Rating,
			Price:            doctor.Price,
			Location:         doctor.Location,
			Featured:         doctor.Featured,
			Schedule:         doctor.Schedule,
		}); err != nil {
			return fmt.Errorf("insert doctor %s: %w", doctor.ID, err)
		}
	}

	return nil
}

func (s *Store) seedAppointments(seedDir string) error {
	count, err := s.countRows("appointments")
	if err != nil {
		return err
	}
	if count > 0 {
		return nil
	}

	var appointments []seedAppointment
	if err := readJSON(filepath.Join(seedDir, "appointments.json"), &appointments); err != nil {
		return fmt.Errorf("read appointments seed: %w", err)
	}

	for _, appointment := range appointments {
		scheduledAt, err := parseSeedTime(appointment.ScheduledAt)
		if err != nil {
			return fmt.Errorf("parse scheduledAt for %s: %w", appointment.ID, err)
		}

		if err := s.CreateAppointment(
			appointment.ID,
			appointment.DoctorID,
			appointment.UserID,
			scheduledAt,
			appointment.Status,
			appointment.Location,
			appointment.Price,
		); err != nil {
			return fmt.Errorf("insert appointment %s: %w", appointment.ID, err)
		}
	}

	return nil
}

func readJSON(path string, destination any) error {
	content, err := os.ReadFile(path)
	if err != nil {
		return err
	}
	return json.Unmarshal(content, destination)
}

func parseOptionalSeedTime(value *string) (*time.Time, error) {
	if value == nil || *value == "" {
		return nil, nil
	}
	parsed, err := parseSeedTime(*value)
	if err != nil {
		return nil, err
	}
	return &parsed, nil
}

func parseSeedTime(value string) (time.Time, error) {
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

	return time.Time{}, fmt.Errorf("unsupported time format: %s", value)
}
