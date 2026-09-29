/* ================================================================
   HR ANALYTICS — 01. DATABASE SCHEMA
   Source: HRDataset_v14.csv (Kaggle, Dr. Carla Patalano & Dr. Rich Huebner)
   Normalizes 1 flat CSV file into 6 relational tables.
   Run this first, then 02_import_data.sql, then 03_analysis.sql.
   ================================================================ */

PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS performance_records;
DROP TABLE IF EXISTS employment_records;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS managers;
DROP TABLE IF EXISTS positions;
DROP TABLE IF EXISTS departments;

-- Lookup table: departments. Built from the clean TEXT column, not the
-- raw DeptID column, which was found to be unreliable (see README).
CREATE TABLE departments (
    department_name TEXT PRIMARY KEY
);

-- Lookup table: positions. Same reasoning as departments — PositionID
-- was found to be partially unreliable.
CREATE TABLE positions (
    position_name TEXT PRIMARY KEY
);

-- Lookup table: managers. Managers do NOT have their own employee record
-- in this dataset — verified that no manager_id matches an emp_id, and no
-- manager_name matches an employee_name.
CREATE TABLE managers (
    manager_id   INTEGER PRIMARY KEY,
    manager_name TEXT NOT NULL
);

-- Core table: one row per employee, demographic attributes only.
CREATE TABLE employees (
    emp_id          INTEGER PRIMARY KEY,
    employee_name   TEXT NOT NULL,
    dob             DATE,
    sex             TEXT,
    marital_desc    TEXT,
    citizen_desc    TEXT,
    hispanic_latino TEXT,
    race_desc       TEXT,
    state           TEXT,
    zip             TEXT   -- TEXT on purpose: many zip codes have a leading zero
);

-- Employment details: one row per employee (this dataset is a snapshot,
-- not a history — no employee has more than one employment record).
CREATE TABLE employment_records (
    emp_id               INTEGER PRIMARY KEY,
    date_of_hire         DATE,
    date_of_termination  DATE,
    term_reason          TEXT,
    employment_status    TEXT,
    department_name      TEXT,
    position_name        TEXT,
    salary               REAL,
    manager_id           INTEGER,
    recruitment_source   TEXT,
    FOREIGN KEY (emp_id)          REFERENCES employees(emp_id),
    FOREIGN KEY (department_name) REFERENCES departments(department_name),
    FOREIGN KEY (position_name)   REFERENCES positions(position_name),
    FOREIGN KEY (manager_id)      REFERENCES managers(manager_id)
);

-- Performance & engagement details: one row per employee.
CREATE TABLE performance_records (
    emp_id                       INTEGER PRIMARY KEY,
    performance_score            TEXT,
    engagement_survey            REAL,
    emp_satisfaction             INTEGER,
    special_projects_count       INTEGER,
    last_performance_review_date DATE,
    days_late_last_30            INTEGER,
    absences                     INTEGER,
    FOREIGN KEY (emp_id) REFERENCES employees(emp_id)
);
