USE hospital_db;

-- Add a new department named Physiotherapy.(Q1)
INSERT INTO departments (name)
VALUES ('Physiotherapy');
SELECT*from departments;

-- Register a patient named Nusrat Jahan with patient number PT-ASMT-001, date of birth 18 April
-- 2001, and phone number 01700000001.(Q2)
 INSERT INTO patients
(patient_no, full_name, dob, phone)
VALUES
('PT-ASMT-001', 'Nusrat Jahan', '2001-04-18', '01700000001');

SELECT*from patients;
-- Show the patient number, name, and phone number of patients whose names start with Nus. Sort the
-- results by name.(Q-3)
SELECT
    patient_no,
    full_name,
    phone
FROM patients
WHERE full_name LIKE 'Nus%'
ORDER BY full_name ASC;


-- (Change the phone number of patient PT-ASMT-001 to 01800000001)(Q-4)

UPDATE patients
SET phone = '01800000001'
where patient_no='PT-ASMT-001';

SELECT*from patients;

-- Show the ID, name, and fee of active doctors who charge BDT 1,000 or less. Sort by fee, then by name,
-- in ascending order.(Q5)


SELECT
    id,
    name,
    fee
FROM doctors
WHERE is_active = TRUE
  AND fee <= 1000
ORDER BY fee ASC, name ASC;


-- Create a 30-minute slot for doctor ID 1 starting tomorrow at 11:00 UTC.(Q6)

SET @slot_start = TIMESTAMP(
    UTC_DATE() + INTERVAL 1 DAY,
    '11:30:00'
);

INSERT INTO doctor_slots (doctor_id, starts_at, ends_at)
VALUES (
    2,
    @slot_start,
    DATE_ADD(@slot_start, INTERVAL 30 MINUTE)
);
 SELECT *
FROM doctor_slots
WHERE doctor_id = 1
ORDER BY starts_at DESC;

SELECT*from doctor_slots;

-- Book the slot created in Question 6 for patient ID 2.(Q7)

-- 7
SET @slot_id = (
    SELECT id
    FROM doctor_slots
    WHERE doctor_id = 2
      AND starts_at = @slot_start
);

INSERT INTO appointments (slot_id, patient_id, status)
VALUES (@slot_id, 2, 'booked');

SET @appointment_id = LAST_INSERT_ID();

SELECT
    a.id AS appointment_id,
    a.slot_id,
    a.patient_id,
    p.full_name AS patient_name,
    s.doctor_id,
    s.starts_at,
    s.ends_at,
    a.status,
    a.created_at
FROM appointments a
JOIN patients p ON a.patient_id = p.id
JOIN doctor_slots s ON a.slot_id = s.id
WHERE a.patient_id = 2
  AND a.slot_id = 12
ORDER BY a.created_at DESC;


-- Cancel the booking made in Question 7. Then verify its status in the appointment history.(Q8)


UPDATE appointments
SET status = 'cancelled'
WHERE id = @appointment_id
  AND status = 'booked';

SELECT id, slot_id, patient_id, status
FROM appointments
WHERE id = @appointment_id;

SELECT * from appointments;



-- Show each username together with its assigned role.(Q9)
SELECT
    u.username,
    r.code AS role
FROM users u
INNER JOIN roles r
    ON u.role_id = r.id
ORDER BY u.username ASC;


-- Show each active doctor’s name, department, and consultation fee.(Q10)

SELECT
    d.name AS doctor_name,
    dep.name AS department_name,
    d.fee AS consultation_fee
FROM doctors d
INNER JOIN departments dep
    ON d.department_id = dep.id
WHERE d.is_active = TRUE
ORDER BY d.name ASC;

 11. সব appointment-এর ID, রোগীর নাম, ডাক্তারের নাম,
--     slot-এর শুরুর সময় ও status দেখাও।
SELECT a.id AS appointment_id,
       p.full_name AS patient_name,
       d.name AS doctor_name,
       s.starts_at AS slot_start_utc,
       a.status
FROM appointments AS a
JOIN patients AS p ON p.id = a.patient_id
JOIN doctor_slots AS s ON s.id = a.slot_id
JOIN doctors AS d ON d.id = s.doctor_id
ORDER BY s.starts_at, a.id;


-- 12. Doctor ID 1-এর ভবিষ্যতের খোলা ও খালি slot-এর
--     ID, শুরুর সময় ও শেষের সময় দেখাও।
SELECT s.id AS slot_id,
       s.starts_at AS slot_start_utc,
       s.ends_at AS slot_end_utc
FROM doctor_slots AS s
LEFT JOIN appointments AS a ON a.active_slot_id = s.id
WHERE s.doctor_id = 1
  AND s.is_open = TRUE
  AND s.starts_at > UTC_TIMESTAMP()
  AND a.id IS NULL
ORDER BY s.starts_at, s.id;


-- 13. প্রত্যেক ডাক্তারের booked appointment গুনে দেখাও।
--     কোনো booked appointment না থাকলে 0 দেখাও।
SELECT d.id AS doctor_id,
       d.name AS doctor_name,
       COUNT(a.id) AS total_booked
FROM doctors AS d
LEFT JOIN doctor_slots AS s ON s.doctor_id = d.id
LEFT JOIN appointments AS a
    ON a.slot_id = s.id AND a.status = 'booked'
GROUP BY d.id, d.name
ORDER BY total_booked DESC, d.name, d.id;


-- 14. কমপক্ষে দুটি booked appointment আছে এমন ডাক্তারদের
--     নাম ও booking সংখ্যা দেখাও।
SELECT d.name AS doctor_name,
       COUNT(a.id) AS total_booked
FROM doctors AS d
JOIN doctor_slots AS s ON s.doctor_id = d.id
JOIN appointments AS a ON a.slot_id = s.id
WHERE a.status = 'booked'
GROUP BY d.id, d.name
HAVING COUNT(a.id) >= 2
ORDER BY total_booked DESC, d.name, d.id;


-- 15. কখনো appointment করেননি এমন রোগীদের নম্বর ও নাম দেখাও।
SELECT p.patient_no, p.full_name AS patient_name
FROM patients AS p
WHERE NOT EXISTS (
    SELECT 1
    FROM appointments AS a
    WHERE a.patient_id = p.id
)
ORDER BY p.patient_no;


-- 16. নির্দিষ্ট UTC তারিখের সব appointment-এর
--     ID, status ও slot-এর শুরুর সময় দেখাও।
--     উদাহরণের তারিখের জায়গায় প্রয়োজনীয় UTC তারিখ বসাও।
SET @report_date = CAST('2026-11-11' AS DATE);

SELECT a.id AS appointment_id,
       a.status,
       s.starts_at AS slot_start_utc
FROM appointments AS a
JOIN doctor_slots AS s ON s.id = a.slot_id
WHERE s.starts_at >= @report_date
  AND s.starts_at < @report_date + INTERVAL 1 DAY
ORDER BY s.starts_at, a.id;