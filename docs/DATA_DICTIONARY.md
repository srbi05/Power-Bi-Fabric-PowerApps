# Data Dictionary — Gold Layer (WH_Gold_HR)

## dim_employee (SCD Type 2)

| Column | Type | Description |
|---|---|---|
| employee_sk | BIGINT | Surrogate key (PK) |
| employee_id | VARCHAR(20) | Natural/business key |
| first_name, last_name | VARCHAR(50) | |
| department_id | VARCHAR(20) | Natural key text value (e.g. "Treasury") -- not a numeric code |
| job_grade_id | VARCHAR(10) | Natural key text value (e.g. "G4") |
| manager_id | VARCHAR(20) | |
| location | VARCHAR(100) | Region (e.g. "Asia Pacific") -- sourced from Employee_Master's Region field, not Country |
| effective_start_date, effective_end_date | DATE | SCD2 tracking. First-ever version per employee is backdated to 1900-01-01 |
| is_current | BIT | SCD2 tracking -- indicates current *attribute version*, NOT employment status (see fact_headcount_snapshot.is_active for that) |
| gender, ethnicity, date_of_birth | various | Added in Scenario 5 for D&I reporting |
| exit_reason | VARCHAR(100) | Raw exit reason from source, only populated for terminated employees |
| attrition_category | VARCHAR(20) | Derived: Voluntary / Involuntary / Retirement / Contract End |
| attrition_category_sort | INT | Sort-order helper (1-4) for visuals needing a specific stage sequence rather than alphabetical/size sort |
| age_band | VARCHAR(20) | Derived bucket from date_of_birth, computed in SQL (Direct Lake does not support calculated columns) |
| attrition_risk_score | INT | 0-100, sourced directly from Employee_Master |
| base_salary | DECIMAL(12,2) | Current base salary, sourced from Employee_Master |

## dim_department
department_sk (PK), department_id, department_name, division, cost_center.
`division`/`cost_center` are NULL -- source data has no clean
department-to-division or department-to-single-cost-center mapping.

## dim_job_grade
job_grade_sk (PK), job_grade_id, grade_name, grade_level, salary_band_min,
salary_band_max. Salary bands are derived (MIN/MAX of observed
BaseSalary_USD per grade), not externally set targets.

## dim_date
date_sk (INT, YYYYMMDD, PK), full_date, year, quarter, month, month_name,
day_of_week, is_weekend, fiscal_year (= calendar year, no fiscal offset
assumed), fiscal_quarter, week_number, is_holiday, is_holiday_us,
is_holiday_uk, holiday_name. Covers 2015-01-01 through 2030-12-31.

## fact_payroll_monthly
Grain: one row per employee per pay period. 109,680 rows.
employee_sk, department_sk, date_sk, job_grade_sk (all FK),
base_pay, bonus (always NULL -- source has no monthly bonus line item),
overtime_pay, deductions, gross_pay (= base_pay + overtime_pay), net_pay.

## fact_attendance_daily
Grain: one row per employee per calendar day. 180,000 rows.
employee_sk, department_sk, date_sk (FK), hours_worked, is_absent, is_late
(always 0 -- source has no lateness indicator), leave_type.

## fact_headcount_snapshot
Grain: one row per employee per month-end snapshot date (2024 only).
116,243 rows. employee_sk, department_sk, date_sk, job_grade_sk (FK),
is_active, is_new_hire, is_termination, tenure_days.

## Verification methodology
Every fact load was checked against an independently computed expected
row count (either the source CSV's actual row count, or a Python
recomputation of the eligible employee-month combinations for the
snapshot table) -- not just "did the load run without error."
