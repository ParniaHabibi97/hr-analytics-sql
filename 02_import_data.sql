/* ================================================================
   HR ANALYTICS — 02. DATA IMPORT & CLEANING
   Prerequisite: raw_hr_data table already imported from HRDataset_v14.csv
   (File -> Import -> Table from CSV file... in DB Browser for SQLite,
   table name "raw_hr_data", "Column names in first line" checked).
   Run 01_schema.sql before this file.
   ================================================================ */

-- ---------- Lookup tables ----------

INSERT INTO departments (department_name)
SELECT DISTINCT TRIM(Department)
FROM raw_hr_data;

INSERT INTO positions (position_name)
SELECT DISTINCT TRIM(Position)
FROM raw_hr_data;

-- DISTINCT on the (ManagerID, ManagerName) pair. Rows with a blank
-- ManagerID are excluded here; those 8 rows are all for "Webster Butler",
-- whose manager_id (39) is populated in his other 13 appearances and is
-- filled in below via a CASE expression, not by joining on his name
-- (his name was found to NOT be a reliable join key — see README).
INSERT INTO managers (manager_id, manager_name)
SELECT DISTINCT CAST(TRIM(ManagerID) AS INTEGER), TRIM(ManagerName)
FROM raw_hr_data
WHERE TRIM(ManagerID) != '';

-- ---------- employees ----------

-- DOB is a fixed-width MM/DD/YY string (always exactly 8 characters),
-- so fixed-position SUBSTR is reliable here.
INSERT INTO employees (emp_id, employee_name, dob, sex, marital_desc, citizen_desc, hispanic_latino, race_desc, state, zip)
SELECT
    CAST(TRIM(EmpID) AS INTEGER),
    TRIM(Employee_Name),
    '19' || SUBSTR(TRIM(DOB), 7, 2) || '-' || SUBSTR(TRIM(DOB), 1, 2) || '-' || SUBSTR(TRIM(DOB), 4, 2),
    TRIM(Sex),
    TRIM(MaritalDesc),
    TRIM(CitizenDesc),
    TRIM(HispanicLatino),
    TRIM(RaceDesc),
    TRIM(State),
    TRIM(Zip)
FROM raw_hr_data;

-- Fix: the CSV import strips leading zeros from Zip because it looks
-- numeric. US zip codes are always 5 digits, so re-pad them.
UPDATE employees
SET zip = printf('%05d', CAST(zip AS INTEGER));

-- ---------- employment_records ----------

-- DateofHire / DateofTermination are variable-width (e.g. "7/5/2011" or
-- "11/7/2011"), so INSTR is used to locate each "/" dynamically instead
-- of relying on a fixed character position. SUBSTR('0'||x,-2,2) pads a
-- 1- or 2-digit value to 2 digits.
INSERT INTO employment_records
    (emp_id, date_of_hire, date_of_termination, term_reason, employment_status,
     department_name, position_name, salary, manager_id, recruitment_source)
SELECT
    CAST(TRIM(r.EmpID) AS INTEGER),

    SUBSTR(TRIM(r.DateofHire), INSTR(TRIM(r.DateofHire),'/') + INSTR(SUBSTR(TRIM(r.DateofHire), INSTR(TRIM(r.DateofHire),'/')+1),'/') + 1)
      || '-' ||
      SUBSTR('0' || SUBSTR(TRIM(r.DateofHire), 1, INSTR(TRIM(r.DateofHire),'/')-1), -2, 2)
      || '-' ||
      SUBSTR('0' || SUBSTR(SUBSTR(TRIM(r.DateofHire), INSTR(TRIM(r.DateofHire),'/')+1), 1, INSTR(SUBSTR(TRIM(r.DateofHire), INSTR(TRIM(r.DateofHire),'/')+1),'/')-1), -2, 2),

    CASE WHEN TRIM(r.DateofTermination) = '' THEN NULL ELSE
        SUBSTR(TRIM(r.DateofTermination), INSTR(TRIM(r.DateofTermination),'/') + INSTR(SUBSTR(TRIM(r.DateofTermination), INSTR(TRIM(r.DateofTermination),'/')+1),'/') + 1)
          || '-' ||
          SUBSTR('0' || SUBSTR(TRIM(r.DateofTermination), 1, INSTR(TRIM(r.DateofTermination),'/')-1), -2, 2)
          || '-' ||
          SUBSTR('0' || SUBSTR(SUBSTR(TRIM(r.DateofTermination), INSTR(TRIM(r.DateofTermination),'/')+1), 1, INSTR(SUBSTR(TRIM(r.DateofTermination), INSTR(TRIM(r.DateofTermination),'/')+1),'/')-1), -2, 2)
    END,

    TRIM(r.TermReason),
    TRIM(r.EmploymentStatus),
    TRIM(r.Department),
    TRIM(r.Position),
    CAST(TRIM(r.Salary) AS REAL),

    -- manager_id: use the row's own ManagerID directly whenever present.
    -- Only the 8 rows with a blank ManagerID (all "Webster Butler") need
    -- a manual fallback, cross-referenced from his other 13 appearances.
    CASE
        WHEN TRIM(r.ManagerID) != '' THEN CAST(TRIM(r.ManagerID) AS INTEGER)
        WHEN TRIM(r.ManagerName) = 'Webster Butler' THEN 39
        ELSE NULL
    END,

    TRIM(r.RecruitmentSource)
FROM raw_hr_data r;

-- ---------- performance_records ----------

-- LastPerformanceReview_Date uses the same variable-width format as
-- DateofHire, so the same parsing pattern is reused.
INSERT INTO performance_records
    (emp_id, performance_score, engagement_survey, emp_satisfaction,
     special_projects_count, last_performance_review_date, days_late_last_30, absences)
SELECT
    CAST(TRIM(r.EmpID) AS INTEGER),
    TRIM(r.PerformanceScore),
    CAST(TRIM(r.EngagementSurvey) AS REAL),
    CAST(TRIM(r.EmpSatisfaction) AS INTEGER),
    CAST(TRIM(r.SpecialProjectsCount) AS INTEGER),

    CASE WHEN TRIM(r.LastPerformanceReview_Date) = '' THEN NULL ELSE
        SUBSTR(TRIM(r.LastPerformanceReview_Date), INSTR(TRIM(r.LastPerformanceReview_Date),'/') + INSTR(SUBSTR(TRIM(r.LastPerformanceReview_Date), INSTR(TRIM(r.LastPerformanceReview_Date),'/')+1),'/') + 1)
          || '-' ||
          SUBSTR('0' || SUBSTR(TRIM(r.LastPerformanceReview_Date), 1, INSTR(TRIM(r.LastPerformanceReview_Date),'/')-1), -2, 2)
          || '-' ||
          SUBSTR('0' || SUBSTR(SUBSTR(TRIM(r.LastPerformanceReview_Date), INSTR(TRIM(r.LastPerformanceReview_Date),'/')+1), 1, INSTR(SUBSTR(TRIM(r.LastPerformanceReview_Date), INSTR(TRIM(r.LastPerformanceReview_Date),'/')+1),'/')-1), -2, 2)
    END,

    CAST(TRIM(r.DaysLateLast30) AS INTEGER),
    CAST(TRIM(r.Absences) AS INTEGER)
FROM raw_hr_data r;

-- ---------- validation ----------
-- Run after the above to confirm everything imported correctly:
--   PRAGMA foreign_key_check;               -- should return 0 rows
--   SELECT COUNT(*) FROM employees;         -- should be 311
--   SELECT COUNT(*) FROM employment_records;-- should be 311
--   SELECT COUNT(*) FROM performance_records;-- should be 311
