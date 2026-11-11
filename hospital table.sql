CREATE DATABASE IF NOT EXISTS hospital_db;
USE hospital_db;
CREATE TABLE roles (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(32) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE users (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  role_id BIGINT UNSIGNED NOT NULL,
  username VARCHAR(80) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  FOREIGN KEY (role_id) REFERENCES roles(id)
) ENGINE=InnoDB;

CREATE TABLE departments (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, 
  name VARCHAR(100) NOT NULL UNIQUE
) ENGINE=InnoDB;


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

CREATE TABLE wards (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(80) NOT NULL UNIQUE
) ENGINE=InnoDB;



CREATE TABLE rooms (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  ward_id BIGINT UNSIGNED NOT NULL,
  room_no VARCHAR(20) NOT NULL,
  UNIQUE KEY uq_ward_room (ward_id, room_no),
  FOREIGN KEY (ward_id) REFERENCES wards(id)
) ENGINE=InnoDB;


CREATE TABLE beds (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  room_id BIGINT UNSIGNED NOT NULL,
  bed_no VARCHAR(20) NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  daily_rate DECIMAL(12,2) NOT NULL CHECK (daily_rate >= 0),
  UNIQUE KEY uq_room_bed (room_id, bed_no),
  FOREIGN KEY (room_id) REFERENCES rooms(id)
) ENGINE=InnoDB;


CREATE TABLE admissions (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  patient_id BIGINT UNSIGNED NOT NULL,
  admitted_by BIGINT UNSIGNED NOT NULL,
  admitted_at DATETIME NOT NULL,
  discharged_at DATETIME,
  status ENUM('admitted','discharged') NOT NULL DEFAULT 'admitted',
  active_patient_id BIGINT UNSIGNED GENERATED ALWAYS AS (
    CASE WHEN discharged_at IS NULL THEN patient_id END
  ) STORED,
  UNIQUE KEY uq_active_admission (active_patient_id),
  UNIQUE KEY uq_admission_patient (id, patient_id),
  FOREIGN KEY (patient_id) REFERENCES patients(id),
  FOREIGN KEY (admitted_by) REFERENCES users(id),
  CHECK ((status = 'admitted' AND discharged_at IS NULL)
    OR (status = 'discharged' AND discharged_at IS NOT NULL AND discharged_at >= admitted_at))
) ENGINE=InnoDB;



CREATE TABLE bed_assignments (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  admission_id BIGINT UNSIGNED NOT NULL,
  bed_id BIGINT UNSIGNED NOT NULL,
  started_at DATETIME NOT NULL,
  ended_at DATETIME,
  daily_rate DECIMAL(12,2) NOT NULL CHECK (daily_rate >= 0),
  active_bed_id BIGINT UNSIGNED GENERATED ALWAYS AS (
    CASE WHEN ended_at IS NULL THEN bed_id END
  ) STORED,
  active_admission_id BIGINT UNSIGNED GENERATED ALWAYS AS (
    CASE WHEN ended_at IS NULL THEN admission_id END
  ) STORED,
  UNIQUE KEY uq_active_bed (active_bed_id),
  UNIQUE KEY uq_active_assignment (active_admission_id),
  FOREIGN KEY (admission_id) REFERENCES admissions(id),
  FOREIGN KEY (bed_id) REFERENCES beds(id),
  CHECK (ended_at IS NULL OR ended_at >= started_at)
) ENGINE=InnoDB;



CREATE TABLE visits (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  patient_id BIGINT UNSIGNED NOT NULL,
  doctor_id BIGINT UNSIGNED NOT NULL,
  appointment_id BIGINT UNSIGNED UNIQUE,
  admission_id BIGINT UNSIGNED,
  checked_in_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  status ENUM('waiting','in_consultation','completed') NOT NULL DEFAULT 'waiting',
  consultation_fee DECIMAL(12,2) NOT NULL CHECK (consultation_fee >= 0),
  symptoms TEXT,
  diagnosis TEXT,
  notes TEXT,
  follow_up_on DATE,
  FOREIGN KEY (patient_id) REFERENCES patients(id),
  FOREIGN KEY (doctor_id) REFERENCES doctors(id),
  FOREIGN KEY (appointment_id) REFERENCES appointments(id),
  FOREIGN KEY (admission_id, patient_id) REFERENCES admissions(id, patient_id),
  INDEX ix_visit_history (patient_id, checked_in_at),
  INDEX ix_doctor_queue (doctor_id, status, checked_in_at),
  CHECK (appointment_id IS NULL OR admission_id IS NULL)
) ENGINE=InnoDB;


CREATE TABLE vital_records (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  visit_id BIGINT UNSIGNED NOT NULL,
  recorded_by BIGINT UNSIGNED NOT NULL,
  recorded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  systolic_bp SMALLINT UNSIGNED,
  diastolic_bp SMALLINT UNSIGNED,
  pulse SMALLINT UNSIGNED,
  temperature_c DECIMAL(4,1),
  weight_kg DECIMAL(6,2),
  spo2 DECIMAL(5,2) CHECK (spo2 BETWEEN 0 AND 100),
  FOREIGN KEY (visit_id) REFERENCES visits(id),
  FOREIGN KEY (recorded_by) REFERENCES users(id),
  INDEX ix_visit_vitals (visit_id, recorded_at)
) ENGINE=InnoDB;


CREATE TABLE medicines (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  strength VARCHAR(50) NOT NULL,
  form VARCHAR(40) NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  UNIQUE KEY uq_medicine (name, strength, form)
) ENGINE=InnoDB;


CREATE TABLE prescriptions (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  visit_id BIGINT UNSIGNED NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (visit_id) REFERENCES visits(id)
) ENGINE=InnoDB;



CREATE TABLE prescription_items (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  prescription_id BIGINT UNSIGNED NOT NULL,
  medicine_id BIGINT UNSIGNED NOT NULL,
  dose VARCHAR(60) NOT NULL,
  frequency VARCHAR(60) NOT NULL,
  duration_days SMALLINT UNSIGNED NOT NULL CHECK (duration_days > 0),
  instructions VARCHAR(250),
  FOREIGN KEY (prescription_id) REFERENCES prescriptions(id),
  FOREIGN KEY (medicine_id) REFERENCES medicines(id)
) ENGINE=InnoDB;



CREATE TABLE lab_tests (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(30) NOT NULL UNIQUE,
  name VARCHAR(120) NOT NULL,
  price DECIMAL(12,2) NOT NULL CHECK (price >= 0),
  is_active BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;


CREATE TABLE lab_orders (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  visit_id BIGINT UNSIGNED NOT NULL,
  ordered_by BIGINT UNSIGNED NOT NULL,
  ordered_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (visit_id) REFERENCES visits(id),
  FOREIGN KEY (ordered_by) REFERENCES users(id)
) ENGINE=InnoDB;


CREATE TABLE lab_order_items (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  lab_order_id BIGINT UNSIGNED NOT NULL,
  lab_test_id BIGINT UNSIGNED NOT NULL,
  unit_price DECIMAL(12,2) NOT NULL CHECK (unit_price >= 0),
  status ENUM('ordered','collected','resulted','verified') NOT NULL DEFAULT 'ordered',
  collected_at DATETIME,
  UNIQUE KEY uq_test_in_order (lab_order_id, lab_test_id),
  FOREIGN KEY (lab_order_id) REFERENCES lab_orders(id),
  FOREIGN KEY (lab_test_id) REFERENCES lab_tests(id),
  CHECK ((status = 'ordered') = (collected_at IS NULL))
) ENGINE=InnoDB;


CREATE TABLE lab_results (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  lab_order_item_id BIGINT UNSIGNED NOT NULL UNIQUE,
  result_text TEXT NOT NULL,
  entered_by BIGINT UNSIGNED NOT NULL,
  entered_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  verified_by BIGINT UNSIGNED,
  verified_at DATETIME,
  FOREIGN KEY (lab_order_item_id) REFERENCES lab_order_items(id),
  FOREIGN KEY (entered_by) REFERENCES users(id),
  FOREIGN KEY (verified_by) REFERENCES users(id),
  CHECK ((verified_by IS NULL) = (verified_at IS NULL))
) ENGINE=InnoDB;



CREATE TABLE suppliers (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(120) NOT NULL,
  phone VARCHAR(30)
) ENGINE=InnoDB;


CREATE TABLE medicine_batches (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  medicine_id BIGINT UNSIGNED NOT NULL,
  supplier_id BIGINT UNSIGNED NOT NULL,
  batch_no VARCHAR(50) NOT NULL,
  expires_on DATE NOT NULL,
  qty_on_hand INT UNSIGNED NOT NULL DEFAULT 0,
  sale_price DECIMAL(12,2) NOT NULL CHECK (sale_price >= 0),
  UNIQUE KEY uq_medicine_batch (medicine_id, batch_no),
  INDEX ix_batch_expiry (medicine_id, expires_on, id),
  FOREIGN KEY (medicine_id) REFERENCES medicines(id),
  FOREIGN KEY (supplier_id) REFERENCES suppliers(id)
) ENGINE=InnoDB;

CREATE TABLE pharmacy_sales (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  visit_id BIGINT UNSIGNED NOT NULL,
  sold_by BIGINT UNSIGNED NOT NULL,
  sold_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (visit_id) REFERENCES visits(id),
  FOREIGN KEY (sold_by) REFERENCES users(id)
) ENGINE=InnoDB;


CREATE TABLE pharmacy_sale_items (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  sale_id BIGINT UNSIGNED NOT NULL,
  batch_id BIGINT UNSIGNED NOT NULL,
  prescription_item_id BIGINT UNSIGNED,
  qty INT UNSIGNED NOT NULL CHECK (qty > 0),
  unit_price DECIMAL(12,2) NOT NULL CHECK (unit_price >= 0),
  FOREIGN KEY (sale_id) REFERENCES pharmacy_sales(id),
  FOREIGN KEY (batch_id) REFERENCES medicine_batches(id),
  FOREIGN KEY (prescription_item_id) REFERENCES prescription_items(id)
) ENGINE=InnoDB;


CREATE TABLE stock_movements (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  batch_id BIGINT UNSIGNED NOT NULL,
  qty_delta INT NOT NULL,
  movement_type ENUM('receipt','dispense') NOT NULL,
  sale_item_id BIGINT UNSIGNED UNIQUE,
  created_by BIGINT UNSIGNED NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (batch_id) REFERENCES medicine_batches(id),
  FOREIGN KEY (sale_item_id) REFERENCES pharmacy_sale_items(id),
  FOREIGN KEY (created_by) REFERENCES users(id),
  CHECK ((movement_type = 'receipt' AND qty_delta > 0 AND sale_item_id IS NULL)
    OR (movement_type = 'dispense' AND qty_delta < 0 AND sale_item_id IS NOT NULL))
) ENGINE=InnoDB;


CREATE TABLE inpatient_notes (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  admission_id BIGINT UNSIGNED NOT NULL,
  author_id BIGINT UNSIGNED NOT NULL,
  note_type ENUM('doctor','nurse') NOT NULL,
  note_text TEXT NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (admission_id) REFERENCES admissions(id),
  FOREIGN KEY (author_id) REFERENCES users(id)
) ENGINE=InnoDB;


CREATE TABLE discharge_summaries (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  admission_id BIGINT UNSIGNED NOT NULL UNIQUE,
  summary_text TEXT NOT NULL,
  follow_up_on DATE,
  prepared_by BIGINT UNSIGNED NOT NULL,
  FOREIGN KEY (admission_id) REFERENCES admissions(id),
  FOREIGN KEY (prepared_by) REFERENCES users(id)
) ENGINE=InnoDB;


CREATE TABLE bills (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  visit_id BIGINT UNSIGNED UNIQUE,
  admission_id BIGINT UNSIGNED UNIQUE,
  status ENUM('draft','issued','void') NOT NULL DEFAULT 'draft',
  issued_at DATETIME,
  discount_amount DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (discount_amount >= 0),
  discount_approved_by BIGINT UNSIGNED,
  FOREIGN KEY (visit_id) REFERENCES visits(id),
  FOREIGN KEY (admission_id) REFERENCES admissions(id),
  FOREIGN KEY (discount_approved_by) REFERENCES users(id),
  CHECK ((visit_id IS NULL) <> (admission_id IS NULL)),
  CHECK (discount_amount = 0 OR discount_approved_by IS NOT NULL)
) ENGINE=InnoDB;


CREATE TABLE bill_items (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  bill_id BIGINT UNSIGNED NOT NULL,
  description VARCHAR(180) NOT NULL,
  quantity INT UNSIGNED NOT NULL CHECK (quantity > 0),
  unit_price DECIMAL(12,2) NOT NULL CHECK (unit_price >= 0),
  consultation_visit_id BIGINT UNSIGNED UNIQUE,
  lab_order_item_id BIGINT UNSIGNED UNIQUE,
  pharmacy_sale_item_id BIGINT UNSIGNED UNIQUE,
  bed_assignment_id BIGINT UNSIGNED UNIQUE,
  FOREIGN KEY (bill_id) REFERENCES bills(id),
  FOREIGN KEY (consultation_visit_id) REFERENCES visits(id),
  FOREIGN KEY (lab_order_item_id) REFERENCES lab_order_items(id),
  FOREIGN KEY (pharmacy_sale_item_id) REFERENCES pharmacy_sale_items(id),
  FOREIGN KEY (bed_assignment_id) REFERENCES bed_assignments(id),
  CHECK ((consultation_visit_id IS NOT NULL) + (lab_order_item_id IS NOT NULL)
    + (pharmacy_sale_item_id IS NOT NULL) + (bed_assignment_id IS NOT NULL) = 1)
) ENGINE=InnoDB;


CREATE TABLE payments (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  bill_id BIGINT UNSIGNED NOT NULL,
  amount DECIMAL(12,2) NOT NULL CHECK (amount > 0),
  method ENUM('cash','card','mobile','bank') NOT NULL,
  paid_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  receipt_no VARCHAR(50) NOT NULL UNIQUE,
  received_by BIGINT UNSIGNED NOT NULL,
  INDEX ix_payment_date (paid_at),
  FOREIGN KEY (bill_id) REFERENCES bills(id),
  FOREIGN KEY (received_by) REFERENCES users(id)
) ENGINE=InnoDB;


CREATE TABLE refunds (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  payment_id BIGINT UNSIGNED NOT NULL,
  amount DECIMAL(12,2) NOT NULL CHECK (amount > 0),
  reason VARCHAR(250) NOT NULL,
  approved_by BIGINT UNSIGNED NOT NULL,
  refunded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  refund_no VARCHAR(50) NOT NULL UNIQUE,
  FOREIGN KEY (payment_id) REFERENCES payments(id),
  FOREIGN KEY (approved_by) REFERENCES users(id)
) ENGINE=InnoDB;



CREATE TABLE audit_logs (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  actor_id BIGINT UNSIGNED NOT NULL,
  action VARCHAR(45) NOT NULL,
  entity_type VARCHAR(45) NOT NULL,
  entity_id BIGINT UNSIGNED NOT NULL,
  occurred_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (actor_id) REFERENCES users(id),
  INDEX ix_audit_entity (entity_type, entity_id, occurred_at)
) ENGINE=InnoDB;
