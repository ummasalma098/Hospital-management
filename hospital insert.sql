USE hospital_db;
CREATE TABLE roles (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(32) NOT NULL UNIQUE
) ENGINE=InnoDB;

INSERT INTO roles (code) VALUES
('admin'),
('manager'),
('editor'),
('author'),
('moderator'),
('user'),
('customer'),
('vendor'),
('staff'),
('super_admin');

SELECT*from roles;

CREATE TABLE users (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  role_id BIGINT UNSIGNED NOT NULL,
  username VARCHAR(80) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  FOREIGN KEY (role_id) REFERENCES roles(id)
) ENGINE=InnoDB;

INSERT INTO users (role_id, username, password_hash, is_active) VALUES
(1, 'admin', 'admin_hash_placeholder', TRUE),
(2, 'manager', 'manager_hash_placeholder', TRUE),
(3, 'editor', 'editor_hash_placeholder', TRUE),
(4, 'author', 'author_hash_placeholder', TRUE),
(5, 'moderator', 'moderator_hash_placeholder', TRUE),
(6, 'user', 'user_hash_placeholder', TRUE),
(7, 'customer', 'customer_hash_placeholder', TRUE),
(8, 'vendor', 'vendor_hash_placeholder', TRUE),
(9, 'staff', 'staff_hash_placeholder', TRUE),
(10, 'super_admin', 'super_admin_hash_placeholder', TRUE);


CREATE TABLE departments (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, 
  name VARCHAR(100) NOT NULL UNIQUE
) ENGINE=InnoDB;

INSERT INTO departments (name) VALUES
('Human Resources'),
('Information Technology'),
('Finance'),
('Marketing'),
('Sales'),
('Customer Support'),
('Operations'),
('Administration'),
('Research and Development'),
('Quality Assurance');


CREATE TABLE doctors (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL UNIQUE,
  department_id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(120) NOT NULL,
  specialization VARCHAR(100) NOT NULL,
  fee DECIMAL(12,2) NOT NULL CHECK (fee >= 0),
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (department_id) REFERENCES departments(id)
) ENGINE=InnoDB;


INSERT INTO doctors
(user_id, department_id, name, specialization, fee, is_active)
VALUES
(1, 1, 'Dr. Abdullah Khan', 'Medicine Specialist', 800.00, TRUE),
(2, 2, 'Dr. Rahim Ahmed', 'Cardiologist', 1000.00, TRUE),
(3, 3, 'Dr. Karim Hasan', 'Neurologist', 1200.00, TRUE),
(4, 4, 'Dr. Tanvir Islam', 'Dermatologist', 700.00, TRUE),
(5, 5, 'Dr. Mahmud Hossain', 'Orthopedic Surgeon', 900.00, TRUE),
(6, 6, 'Dr. Nusrat Jahan', 'Gynecologist', 1000.00, TRUE),
(7, 7, 'Dr. Sadia Akter', 'Pediatrician', 800.00, TRUE),
(8, 8, 'Dr. Faisal Ahmed', 'ENT Specialist', 750.00, TRUE),
(9, 9, 'Dr. Mehedi Hasan', 'Psychiatrist', 1100.00, TRUE),
(10, 10, 'Dr. Sumaiya Rahman', 'Ophthalmologist', 850.00, TRUE);


CREATE TABLE patients (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  patient_no VARCHAR(30) NOT NULL UNIQUE,
  full_name VARCHAR(120) NOT NULL,
  dob DATE NOT NULL,
  phone VARCHAR(30),
  address VARCHAR(250),
  emergency_phone VARCHAR(30),
  INDEX ix_patient_phone (phone),
  INDEX ix_patient_name (full_name)
) ENGINE=InnoDB;



INSERT INTO patients
(patient_no, full_name, dob, phone, address, emergency_phone)
VALUES
('PAT-1001', 'Abdur Rahman', '1990-05-15', '01712345678', 'Rajshahi, Bangladesh', '01812345678'),
('PAT-1002', 'Nusrat Jahan', '1995-08-22', '01723456789', 'Dhaka, Bangladesh', '01823456789'),
('PAT-1003', 'Mohammad Karim', '1985-03-10', '01912345678', 'Chittagong, Bangladesh', '01612345678'),
('PAT-1004', 'Fatema Akter', '2000-11-05', '01834567890', 'Sylhet, Bangladesh', '01734567890'),
('PAT-1005', 'Rakib Hasan', '1992-07-18', '01612345678', 'Khulna, Bangladesh', '01923456789'),
('PAT-1006', 'Sumaiya Rahman', '1988-01-25', '01745678901', 'Rajshahi, Bangladesh', '01845678901'),
('PAT-1007', 'Tanvir Ahmed', '1998-09-12', '01934567890', 'Barishal, Bangladesh', '01634567890'),
('PAT-1008', 'Sadia Islam', '1993-04-30', '01856789012', 'Rangpur, Bangladesh', '01756789012'),
('PAT-1009', 'Mehedi Hasan', '1980-12-20', '01645678901', 'Cumilla, Bangladesh', '01945678901'),
('PAT-1010', 'Ayesha Siddika', '2002-06-08', '01767890123', 'Bogura, Bangladesh', '01867890123');

 

CREATE TABLE doctor_slots (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  doctor_id BIGINT UNSIGNED NOT NULL,
  starts_at DATETIME NOT NULL,
  ends_at DATETIME NOT NULL,
  is_open BOOLEAN NOT NULL DEFAULT TRUE,
  UNIQUE KEY uq_doctor_start (doctor_id, starts_at),
  FOREIGN KEY (doctor_id) REFERENCES doctors(id),
  CHECK (MINUTE(starts_at) IN (0, 30) AND SECOND(starts_at) = 0
    AND ends_at = DATE_ADD(starts_at, INTERVAL 30 MINUTE))
) ENGINE=InnoDB;

INSERT INTO doctor_slots
(doctor_id, starts_at, ends_at, is_open)
VALUES
(1, '2026-11-11 09:00:00', '2026-11-11 09:30:00', TRUE),
(2, '2026-11-11 09:30:00', '2026-11-11 10:00:00', TRUE),
(3, '2026-11-11 10:00:00', '2026-11-11 10:30:00', TRUE),
(4, '2026-11-11 10:30:00', '2026-11-11 11:00:00', TRUE),
(5, '2026-11-11 11:00:00', '2026-11-11 11:30:00', TRUE),
(6, '2026-11-11 11:30:00', '2026-11-11 12:00:00', TRUE),
(7, '2026-11-11 12:00:00', '2026-11-11 12:30:00', TRUE),
(8, '2026-11-11 12:30:00', '2026-11-11 13:00:00', TRUE),
(9, '2026-11-11 14:00:00', '2026-11-11 14:30:00', TRUE),
(10, '2026-11-11 14:30:00', '2026-11-11 15:00:00', TRUE);


CREATE TABLE appointments (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  slot_id BIGINT UNSIGNED NOT NULL,
  patient_id BIGINT UNSIGNED NOT NULL,
  status ENUM('booked','checked_in','cancelled','no_show') NOT NULL DEFAULT 'booked',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  active_slot_id BIGINT UNSIGNED GENERATED ALWAYS AS (
    CASE WHEN status IN ('booked','checked_in') THEN slot_id END
  ) STORED,
  UNIQUE KEY uq_active_slot (active_slot_id),
  FOREIGN KEY (slot_id) REFERENCES doctor_slots(id),
  FOREIGN KEY (patient_id) REFERENCES patients(id)
) ENGINE=InnoDB;


INSERT INTO appointments
(slot_id, patient_id, status)
VALUES
(1, 1, 'booked'),
(2, 2, 'booked'),
(3, 3, 'checked_in'),
(4, 4, 'booked'),
(5, 5, 'cancelled'),
(6, 6, 'booked'),
(7, 7, 'no_show'),
(8, 8, 'checked_in'),
(9, 9, 'booked'),
(10, 10, 'cancelled');