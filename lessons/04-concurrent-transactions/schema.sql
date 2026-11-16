BEGIN;

DROP TABLE IF EXISTS shift_staff CASCADE;
DROP TABLE IF EXISTS shifts CASCADE;

CREATE TABLE shifts (
    shift_id integer PRIMARY KEY,
    shift_name text NOT NULL
);

CREATE TABLE shift_staff (
    shift_id integer NOT NULL REFERENCES shifts (shift_id),
    staff_id integer NOT NULL,
    staff_name text NOT NULL,
    on_call boolean NOT NULL,
    PRIMARY KEY (shift_id, staff_id)
);

INSERT INTO shifts VALUES (1, 'Night shift');
INSERT INTO shift_staff VALUES
    (1, 101, 'Anna', true),
    (1, 102, 'Boris', true);

-- Остальные смены проверяют, что операция ограничена выбранной сменой.
INSERT INTO shifts
SELECT id, 'Shift ' || id FROM generate_series(2, 50) AS id;

INSERT INTO shift_staff
SELECT shift_id, staff_id,
       CASE staff_id WHEN 101 THEN 'Anna' ELSE 'Boris' END,
       staff_id = 101 OR shift_id % 2 = 0
FROM shifts
CROSS JOIN (VALUES (101), (102)) AS staff(staff_id)
WHERE shift_id > 1;

COMMIT;

ANALYZE shifts;
ANALYZE shift_staff;
