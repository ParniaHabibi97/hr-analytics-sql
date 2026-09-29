/* ================================================================
   HR ANALYTICS — 03. ANALYSIS QUERIES
   Answers the open questions posed by the dataset's original authors.
   Run after 01_schema.sql and 02_import_data.sql.
   ================================================================ */


/* ------------------------------------------------------------
   Q1 — Is there a relationship between manager and performance score?
   ------------------------------------------------------------ */
SELECT
    m.manager_name,
    COUNT(*) AS total_reports,
    SUM(CASE WHEN pr.performance_score = 'PIP' THEN 1 ELSE 0 END) AS pip_count,
    ROUND(100.0 * SUM(CASE WHEN pr.performance_score = 'PIP' THEN 1 ELSE 0 END) / COUNT(*), 1) AS pip_pct
FROM managers m
JOIN employment_records er ON m.manager_id = er.manager_id
JOIN performance_records pr ON er.emp_id = pr.emp_id
GROUP BY m.manager_name
HAVING total_reports >= 10
ORDER BY pip_pct DESC;


/* ------------------------------------------------------------
   Q2 — What is the overall diversity profile of the organization?
   ------------------------------------------------------------ */
SELECT race_desc, COUNT(*) AS n,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM employees), 1) AS pct
FROM employees
GROUP BY race_desc
ORDER BY n DESC;

SELECT sex, COUNT(*) AS n,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM employees), 1) AS pct
FROM employees
GROUP BY sex;


/* ------------------------------------------------------------
   Q3 — Which recruitment sources bring in the most diversity?
   ------------------------------------------------------------ */
SELECT er.recruitment_source,
       COUNT(*) AS total_hired,
       SUM(CASE WHEN e.race_desc != 'White' THEN 1 ELSE 0 END) AS non_white,
       ROUND(100.0 * SUM(CASE WHEN e.race_desc != 'White' THEN 1 ELSE 0 END) / COUNT(*), 1) AS non_white_pct
FROM employees e
JOIN employment_records er ON e.emp_id = er.emp_id
GROUP BY er.recruitment_source
HAVING total_hired >= 10
ORDER BY non_white_pct DESC;


/* ------------------------------------------------------------
   Q4 — What factors correlate with termination?
   (Descriptive groundwork for a future predictive model — SQL
   alone cannot build a classifier.)
   ------------------------------------------------------------ */
SELECT department_name,
       COUNT(*) AS total,
       SUM(CASE WHEN employment_status != 'Active' THEN 1 ELSE 0 END) AS terminated,
       ROUND(100.0 * SUM(CASE WHEN employment_status != 'Active' THEN 1 ELSE 0 END) / COUNT(*), 1) AS term_rate_pct
FROM employment_records
GROUP BY department_name
ORDER BY term_rate_pct DESC;

SELECT pr.performance_score,
       COUNT(*) AS total,
       SUM(CASE WHEN er.employment_status != 'Active' THEN 1 ELSE 0 END) AS terminated,
       ROUND(100.0 * SUM(CASE WHEN er.employment_status != 'Active' THEN 1 ELSE 0 END) / COUNT(*), 1) AS term_rate_pct
FROM performance_records pr
JOIN employment_records er ON pr.emp_id = er.emp_id
GROUP BY pr.performance_score
ORDER BY term_rate_pct DESC;


/* ------------------------------------------------------------
   Q5 — Are there areas of the company where pay is not equitable?
   (Descriptive only — no statistical significance testing performed;
   several positions have very small sample sizes.)
   ------------------------------------------------------------ */
WITH pos_gender AS (
    SELECT er.position_name, e.sex, COUNT(*) AS n, ROUND(AVG(er.salary), 0) AS avg_salary
    FROM employees e
    JOIN employment_records er ON e.emp_id = er.emp_id
    GROUP BY er.position_name, e.sex
)
SELECT
    position_name,
    MAX(CASE WHEN sex = 'M' THEN avg_salary END) AS avg_male_salary,
    MAX(CASE WHEN sex = 'F' THEN avg_salary END) AS avg_female_salary,
    MAX(CASE WHEN sex = 'M' THEN n END) AS n_male,
    MAX(CASE WHEN sex = 'F' THEN n END) AS n_female
FROM pos_gender
GROUP BY position_name
HAVING avg_male_salary IS NOT NULL AND avg_female_salary IS NOT NULL
ORDER BY ABS(avg_male_salary - avg_female_salary) DESC
LIMIT 8;

/* ============================================================
   END OF ANALYSIS
   ============================================================ */
