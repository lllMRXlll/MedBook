package model

import "time"

type User struct {
	ID           string     `json:"id"`
	FullName     string     `json:"fullName"`
	Email        string     `json:"email"`
	Phone        string     `json:"phone"`
	PasswordHash string     `json:"-"`
	BirthDate    *time.Time `json:"birthDate,omitempty"`
	City         *string    `json:"city,omitempty"`
}

type Session struct {
	Token     string
	UserID    string
	ExpiresAt time.Time
}

type AuthSession struct {
	Token string `json:"token"`
	User  User   `json:"user"`
}

type Specialization struct {
	ID    string `json:"id"`
	Title string `json:"title"`
}

type DoctorSchedule struct {
	WorkDays    []int `json:"workDays"`
	StartHour   int   `json:"startHour"`
	EndHour     int   `json:"endHour"`
	SlotMinutes int   `json:"slotMinutes"`
}

type Doctor struct {
	ID               string         `json:"id"`
	Name             string         `json:"name"`
	SpecializationID string         `json:"specializationId"`
	Description      string         `json:"description"`
	ExperienceYears  int            `json:"experienceYears"`
	Rating           float64        `json:"rating"`
	Price            int            `json:"price"`
	Location         string         `json:"location"`
	Featured         bool           `json:"featured"`
	Schedule         DoctorSchedule `json:"schedule"`
}

type TimeSlot struct {
	StartsAt    time.Time `json:"startsAt"`
	IsAvailable bool      `json:"isAvailable"`
}

type Appointment struct {
	ID                 string    `json:"id"`
	DoctorID           string    `json:"doctorId"`
	UserID             string    `json:"userId"`
	DoctorName         string    `json:"doctorName"`
	SpecializationName string    `json:"specializationName"`
	ScheduledAt        time.Time `json:"scheduledAt"`
	Status             string    `json:"status"`
	Location           string    `json:"location"`
	Price              int       `json:"price"`
}

type LoginRequest struct {
	Identifier string `json:"identifier"`
	Password   string `json:"password"`
}

type RegisterRequest struct {
	FullName string `json:"fullName"`
	Email    string `json:"email"`
	Phone    string `json:"phone"`
	Password string `json:"password"`
}

type BookAppointmentRequest struct {
	DoctorID    string    `json:"doctorId"`
	ScheduledAt time.Time `json:"scheduledAt"`
}

type RescheduleAppointmentRequest struct {
	ScheduledAt time.Time `json:"scheduledAt"`
}

type UpdateProfileRequest struct {
	FullName  string     `json:"fullName"`
	Email     string     `json:"email"`
	Phone     string     `json:"phone"`
	BirthDate *time.Time `json:"birthDate"`
	City      *string    `json:"city"`
}

type ErrorResponse struct {
	Message string `json:"message"`
}
