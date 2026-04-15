package store

import (
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"

	_ "modernc.org/sqlite"

	"medbook/backend/internal/model"
)

type Store struct {
	db *sql.DB
}

func Open(databasePath string) (*Store, error) {
	if !strings.HasPrefix(databasePath, "file:") && databasePath != ":memory:" {
		directory := filepath.Dir(databasePath)
		if directory != "." && directory != "" {
			if err := os.MkdirAll(directory, 0o755); err != nil {
				return nil, fmt.Errorf("create database directory: %w", err)
			}
		}
	}

	db, err := sql.Open("sqlite", databasePath)
	if err != nil {
		return nil, fmt.Errorf("open sqlite: %w", err)
	}

	db.SetMaxOpenConns(1)
	db.SetMaxIdleConns(1)
	db.SetConnMaxLifetime(0)

	if err := db.Ping(); err != nil {
		_ = db.Close()
		return nil, fmt.Errorf("ping sqlite: %w", err)
	}

	return &Store{db: db}, nil
}

func (s *Store) Close() error {
	return s.db.Close()
}

func (s *Store) CreateUser(user model.User) error {
	_, err := s.db.Exec(`
		INSERT INTO users (id, full_name, email, phone, password_hash, birth_date, city, updated_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?)
	`,
		user.ID,
		user.FullName,
		strings.ToLower(strings.TrimSpace(user.Email)),
		strings.TrimSpace(user.Phone),
		user.PasswordHash,
		nullableTimeString(user.BirthDate),
		nullableString(user.City),
		nowString(),
	)
	if err != nil {
		return fmt.Errorf("create user: %w", err)
	}
	return nil
}

func (s *Store) FindUserByIdentifier(identifier string) (model.User, error) {
	lookup := strings.ToLower(strings.TrimSpace(identifier))
	row := s.db.QueryRow(`
		SELECT id, full_name, email, phone, password_hash, birth_date, city
		FROM users
		WHERE lower(email) = ? OR phone = ?
		LIMIT 1
	`, lookup, strings.TrimSpace(identifier))
	user, err := scanUser(row)
	if err != nil {
		return model.User{}, err
	}
	return user, nil
}

func (s *Store) GetUserByID(id string) (model.User, error) {
	row := s.db.QueryRow(`
		SELECT id, full_name, email, phone, password_hash, birth_date, city
		FROM users
		WHERE id = ?
		LIMIT 1
	`, id)
	user, err := scanUser(row)
	if err != nil {
		return model.User{}, err
	}
	return user, nil
}

func (s *Store) GetUserByToken(token string) (model.User, error) {
	row := s.db.QueryRow(`
		SELECT u.id, u.full_name, u.email, u.phone, u.password_hash, u.birth_date, u.city
		FROM sessions s
		JOIN users u ON u.id = s.user_id
		WHERE s.token = ? AND s.expires_at > ?
		LIMIT 1
	`, token, nowString())
	user, err := scanUser(row)
	if err != nil {
		return model.User{}, err
	}
	return user, nil
}

func (s *Store) EmailOrPhoneExists(email, phone, excludeUserID string) (bool, error) {
	query := `
		SELECT COUNT(1)
		FROM users
		WHERE (lower(email) = ? OR phone = ?)
	`
	args := []any{
		strings.ToLower(strings.TrimSpace(email)),
		strings.TrimSpace(phone),
	}
	if excludeUserID != "" {
		query += ` AND id <> ?`
		args = append(args, excludeUserID)
	}

	var count int
	if err := s.db.QueryRow(query, args...).Scan(&count); err != nil {
		return false, fmt.Errorf("check duplicate user: %w", err)
	}
	return count > 0, nil
}

func (s *Store) UpdateUser(user model.User) error {
	result, err := s.db.Exec(`
		UPDATE users
		SET full_name = ?, email = ?, phone = ?, birth_date = ?, city = ?, updated_at = ?
		WHERE id = ?
	`,
		user.FullName,
		strings.ToLower(strings.TrimSpace(user.Email)),
		strings.TrimSpace(user.Phone),
		nullableTimeString(user.BirthDate),
		nullableString(user.City),
		nowString(),
		user.ID,
	)
	if err != nil {
		return fmt.Errorf("update user: %w", err)
	}

	affected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("check updated user rows: %w", err)
	}
	if affected == 0 {
		return sql.ErrNoRows
	}
	return nil
}

func (s *Store) CreateSession(token, userID string, expiresAt time.Time) error {
	_, err := s.db.Exec(`
		INSERT INTO sessions (token, user_id, expires_at)
		VALUES (?, ?, ?)
	`, token, userID, formatTime(expiresAt))
	if err != nil {
		return fmt.Errorf("create session: %w", err)
	}
	return nil
}

func (s *Store) DeleteSession(token string) error {
	_, err := s.db.Exec(`DELETE FROM sessions WHERE token = ?`, token)
	if err != nil {
		return fmt.Errorf("delete session: %w", err)
	}
	return nil
}

func (s *Store) CleanupExpiredSessions() error {
	_, err := s.db.Exec(`DELETE FROM sessions WHERE expires_at <= ?`, nowString())
	if err != nil {
		return fmt.Errorf("cleanup sessions: %w", err)
	}
	return nil
}

func (s *Store) CreateSpecialization(item model.Specialization) error {
	_, err := s.db.Exec(`
		INSERT INTO specializations (id, title)
		VALUES (?, ?)
	`, item.ID, item.Title)
	if err != nil {
		return fmt.Errorf("create specialization: %w", err)
	}
	return nil
}

func (s *Store) ListSpecializations() ([]model.Specialization, error) {
	rows, err := s.db.Query(`
		SELECT id, title
		FROM specializations
		ORDER BY title ASC
	`)
	if err != nil {
		return nil, fmt.Errorf("list specializations: %w", err)
	}
	defer rows.Close()

	var result []model.Specialization
	for rows.Next() {
		var item model.Specialization
		if err := rows.Scan(&item.ID, &item.Title); err != nil {
			return nil, fmt.Errorf("scan specialization: %w", err)
		}
		result = append(result, item)
	}
	return result, rows.Err()
}

func (s *Store) CreateDoctor(doctor model.Doctor) error {
	encodedDays, err := json.Marshal(doctor.Schedule.WorkDays)
	if err != nil {
		return fmt.Errorf("marshal work days: %w", err)
	}

	tx, err := s.db.Begin()
	if err != nil {
		return fmt.Errorf("begin create doctor: %w", err)
	}

	if _, err := tx.Exec(`
		INSERT INTO doctors (
			id, name, specialization_id, description, experience_years, rating, price, location, featured, updated_at
		)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
	`,
		doctor.ID,
		doctor.Name,
		doctor.SpecializationID,
		doctor.Description,
		doctor.ExperienceYears,
		doctor.Rating,
		doctor.Price,
		doctor.Location,
		boolToInt(doctor.Featured),
		nowString(),
	); err != nil {
		_ = tx.Rollback()
		return fmt.Errorf("insert doctor: %w", err)
	}

	if _, err := tx.Exec(`
		INSERT INTO doctor_schedules (doctor_id, work_days, start_hour, end_hour, slot_minutes)
		VALUES (?, ?, ?, ?, ?)
	`,
		doctor.ID,
		string(encodedDays),
		doctor.Schedule.StartHour,
		doctor.Schedule.EndHour,
		doctor.Schedule.SlotMinutes,
	); err != nil {
		_ = tx.Rollback()
		return fmt.Errorf("insert doctor schedule: %w", err)
	}

	if err := tx.Commit(); err != nil {
		return fmt.Errorf("commit create doctor: %w", err)
	}
	return nil
}

func (s *Store) ListDoctors(specializationID, query string) ([]model.Doctor, error) {
	baseQuery := `
		SELECT
			d.id, d.name, d.specialization_id, d.description, d.experience_years,
			d.rating, d.price, d.location, d.featured,
			ds.work_days, ds.start_hour, ds.end_hour, ds.slot_minutes
		FROM doctors d
		JOIN doctor_schedules ds ON ds.doctor_id = d.id
		WHERE 1 = 1
	`
	var args []any

	if specializationID != "" {
		baseQuery += ` AND d.specialization_id = ?`
		args = append(args, specializationID)
	}
	if trimmed := strings.TrimSpace(query); trimmed != "" {
		baseQuery += ` AND lower(d.name) LIKE ?`
		args = append(args, "%"+strings.ToLower(trimmed)+"%")
	}

	baseQuery += ` ORDER BY d.featured DESC, d.rating DESC, d.name ASC`

	rows, err := s.db.Query(baseQuery, args...)
	if err != nil {
		return nil, fmt.Errorf("list doctors: %w", err)
	}
	defer rows.Close()

	var result []model.Doctor
	for rows.Next() {
		doctor, err := scanDoctor(rows)
		if err != nil {
			return nil, err
		}
		result = append(result, doctor)
	}
	return result, rows.Err()
}

func (s *Store) GetDoctorByID(id string) (model.Doctor, error) {
	row := s.db.QueryRow(`
		SELECT
			d.id, d.name, d.specialization_id, d.description, d.experience_years,
			d.rating, d.price, d.location, d.featured,
			ds.work_days, ds.start_hour, ds.end_hour, ds.slot_minutes
		FROM doctors d
		JOIN doctor_schedules ds ON ds.doctor_id = d.id
		WHERE d.id = ?
		LIMIT 1
	`, id)
	return scanDoctor(row)
}

func (s *Store) CreateAppointment(
	id string,
	doctorID string,
	userID string,
	scheduledAt time.Time,
	status string,
	location string,
	price int,
) error {
	_, err := s.db.Exec(`
		INSERT INTO appointments (id, doctor_id, user_id, scheduled_at, status, location, price, updated_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?)
	`,
		id,
		doctorID,
		userID,
		formatTime(scheduledAt),
		status,
		location,
		price,
		nowString(),
	)
	if err != nil {
		return fmt.Errorf("create appointment: %w", err)
	}
	return nil
}

func (s *Store) ListAppointmentsByUser(userID string) ([]model.Appointment, error) {
	rows, err := s.db.Query(`
		SELECT
			a.id, a.doctor_id, a.user_id, d.name, sp.title, a.scheduled_at, a.status, a.location, a.price
		FROM appointments a
		JOIN doctors d ON d.id = a.doctor_id
		JOIN specializations sp ON sp.id = d.specialization_id
		WHERE a.user_id = ?
		ORDER BY a.scheduled_at ASC
	`, userID)
	if err != nil {
		return nil, fmt.Errorf("list appointments: %w", err)
	}
	defer rows.Close()

	var result []model.Appointment
	for rows.Next() {
		appointment, err := scanAppointment(rows)
		if err != nil {
			return nil, err
		}
		result = append(result, appointment)
	}
	return result, rows.Err()
}

func (s *Store) GetAppointmentByIDForUser(appointmentID, userID string) (model.Appointment, error) {
	row := s.db.QueryRow(`
		SELECT
			a.id, a.doctor_id, a.user_id, d.name, sp.title, a.scheduled_at, a.status, a.location, a.price
		FROM appointments a
		JOIN doctors d ON d.id = a.doctor_id
		JOIN specializations sp ON sp.id = d.specialization_id
		WHERE a.id = ? AND a.user_id = ?
		LIMIT 1
	`, appointmentID, userID)
	return scanAppointment(row)
}

func (s *Store) UpdateAppointmentStatus(appointmentID, userID, status string) error {
	result, err := s.db.Exec(`
		UPDATE appointments
		SET status = ?, updated_at = ?
		WHERE id = ? AND user_id = ?
	`, status, nowString(), appointmentID, userID)
	if err != nil {
		return fmt.Errorf("update appointment status: %w", err)
	}
	return ensureRowsAffected(result)
}

func (s *Store) UpdateAppointmentSchedule(appointmentID, userID string, scheduledAt time.Time) error {
	result, err := s.db.Exec(`
		UPDATE appointments
		SET scheduled_at = ?, status = 'scheduled', updated_at = ?
		WHERE id = ? AND user_id = ?
	`, formatTime(scheduledAt), nowString(), appointmentID, userID)
	if err != nil {
		return fmt.Errorf("update appointment schedule: %w", err)
	}
	return ensureRowsAffected(result)
}

func (s *Store) ListBookedSlots(doctorID string, date time.Time, ignoreAppointmentID string) ([]time.Time, error) {
	dayStart := time.Date(date.Year(), date.Month(), date.Day(), 0, 0, 0, 0, date.Location())
	dayEnd := dayStart.Add(24 * time.Hour)

	query := `
		SELECT scheduled_at
		FROM appointments
		WHERE doctor_id = ?
		  AND status <> 'cancelled'
		  AND scheduled_at >= ?
		  AND scheduled_at < ?
	`
	args := []any{doctorID, formatTime(dayStart), formatTime(dayEnd)}
	if ignoreAppointmentID != "" {
		query += ` AND id <> ?`
		args = append(args, ignoreAppointmentID)
	}

	rows, err := s.db.Query(query, args...)
	if err != nil {
		return nil, fmt.Errorf("list booked slots: %w", err)
	}
	defer rows.Close()

	var result []time.Time
	for rows.Next() {
		var raw string
		if err := rows.Scan(&raw); err != nil {
			return nil, fmt.Errorf("scan booked slot: %w", err)
		}
		parsed, err := time.Parse(time.RFC3339Nano, raw)
		if err != nil {
			return nil, fmt.Errorf("parse booked slot: %w", err)
		}
		result = append(result, parsed)
	}
	return result, rows.Err()
}

func (s *Store) countRows(table string) (int, error) {
	var count int
	query := fmt.Sprintf(`SELECT COUNT(1) FROM %s`, table)
	if err := s.db.QueryRow(query).Scan(&count); err != nil {
		return 0, fmt.Errorf("count rows in %s: %w", table, err)
	}
	return count, nil
}

func scanUser(scanner interface{ Scan(...any) error }) (model.User, error) {
	var (
		user         model.User
		birthDateRaw sql.NullString
		cityRaw      sql.NullString
	)
	if err := scanner.Scan(
		&user.ID,
		&user.FullName,
		&user.Email,
		&user.Phone,
		&user.PasswordHash,
		&birthDateRaw,
		&cityRaw,
	); err != nil {
		return model.User{}, err
	}

	if birthDateRaw.Valid {
		parsed, err := time.Parse(time.RFC3339Nano, birthDateRaw.String)
		if err != nil {
			return model.User{}, fmt.Errorf("parse birth_date: %w", err)
		}
		user.BirthDate = &parsed
	}
	if cityRaw.Valid {
		city := cityRaw.String
		user.City = &city
	}
	return user, nil
}

func scanDoctor(scanner interface{ Scan(...any) error }) (model.Doctor, error) {
	var (
		doctor      model.Doctor
		featuredRaw int
		workDaysRaw string
	)
	if err := scanner.Scan(
		&doctor.ID,
		&doctor.Name,
		&doctor.SpecializationID,
		&doctor.Description,
		&doctor.ExperienceYears,
		&doctor.Rating,
		&doctor.Price,
		&doctor.Location,
		&featuredRaw,
		&workDaysRaw,
		&doctor.Schedule.StartHour,
		&doctor.Schedule.EndHour,
		&doctor.Schedule.SlotMinutes,
	); err != nil {
		return model.Doctor{}, fmt.Errorf("scan doctor: %w", err)
	}
	if err := json.Unmarshal([]byte(workDaysRaw), &doctor.Schedule.WorkDays); err != nil {
		return model.Doctor{}, fmt.Errorf("decode work days: %w", err)
	}
	doctor.Featured = featuredRaw == 1
	return doctor, nil
}

func scanAppointment(scanner interface{ Scan(...any) error }) (model.Appointment, error) {
	var (
		appointment    model.Appointment
		scheduledAtRaw string
	)
	if err := scanner.Scan(
		&appointment.ID,
		&appointment.DoctorID,
		&appointment.UserID,
		&appointment.DoctorName,
		&appointment.SpecializationName,
		&scheduledAtRaw,
		&appointment.Status,
		&appointment.Location,
		&appointment.Price,
	); err != nil {
		return model.Appointment{}, fmt.Errorf("scan appointment: %w", err)
	}

	parsed, err := time.Parse(time.RFC3339Nano, scheduledAtRaw)
	if err != nil {
		return model.Appointment{}, fmt.Errorf("parse scheduled_at: %w", err)
	}
	appointment.ScheduledAt = parsed
	return appointment, nil
}

func ensureRowsAffected(result sql.Result) error {
	affected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("check rows affected: %w", err)
	}
	if affected == 0 {
		return sql.ErrNoRows
	}
	return nil
}

func boolToInt(value bool) int {
	if value {
		return 1
	}
	return 0
}

func nullableTimeString(value *time.Time) any {
	if value == nil {
		return nil
	}
	return formatTime(*value)
}

func nullableString(value *string) any {
	if value == nil {
		return nil
	}
	trimmed := strings.TrimSpace(*value)
	if trimmed == "" {
		return nil
	}
	return trimmed
}

func formatTime(value time.Time) string {
	return value.Format(time.RFC3339Nano)
}

func nowString() string {
	return formatTime(time.Now().UTC())
}

func IsNotFound(err error) bool {
	return errors.Is(err, sql.ErrNoRows)
}
