-- =====================================================================
-- Gold Layer Schema: WH_Gold_HR
-- Run in order: this file must be split into separate batch executions
-- per Fabric Warehouse's batch rules (see docs/TROUBLESHOOTING_LOG.md)
-- =====================================================================

-- BATCH 1 (run alone): CREATE SCHEMA must be the only statement in its batch
CREATE SCHEMA gold;

-- BATCH 2: dimension and fact tables
-- Note: IDENTITY columns must be BIGINT in Fabric Warehouse (not INT),
-- and cannot specify seed/increment -- just BIGINT IDENTITY.

CREATE TABLE gold.dim_date (
    date_sk         INT NOT NULL,
    full_date       DATE NOT NULL,
    year            INT,
    quarter         INT,
    month           INT,
    month_name      VARCHAR(20),
    day_of_week     VARCHAR(20),
    is_weekend      BIT,
    fiscal_year     INT
);

CREATE TABLE gold.dim_department (
    department_sk   BIGINT IDENTITY NOT NULL,
    department_id   VARCHAR(20) NOT NULL,
    department_name VARCHAR(100),
    division        VARCHAR(100),
    cost_center     VARCHAR(20)
);

CREATE TABLE gold.dim_job_grade (
    job_grade_sk     BIGINT IDENTITY NOT NULL,
    job_grade_id     VARCHAR(20) NOT NULL,
    grade_name       VARCHAR(50),
    grade_level      INT,
    salary_band_min  DECIMAL(12,2),
    salary_band_max  DECIMAL(12,2)
);

CREATE TABLE gold.dim_employee (
    employee_sk           BIGINT IDENTITY NOT NULL,
    employee_id           VARCHAR(20) NOT NULL,
    first_name             VARCHAR(50),
    last_name              VARCHAR(50),
    department_id          VARCHAR(20),
    job_grade_id           VARCHAR(20),
    manager_id             VARCHAR(20),
    location                VARCHAR(100),
    effective_start_date    DATE NOT NULL,
    effective_end_date      DATE NOT NULL,
    is_current               BIT NOT NULL
);

CREATE TABLE gold.fact_payroll_monthly (
    employee_sk     BIGINT NOT NULL,
    department_sk   BIGINT NOT NULL,
    date_sk         INT NOT NULL,
    job_grade_sk    BIGINT NOT NULL,
    base_pay        DECIMAL(12,2),
    bonus           DECIMAL(12,2),
    overtime_pay    DECIMAL(12,2),
    deductions      DECIMAL(12,2),
    gross_pay       DECIMAL(12,2),
    net_pay         DECIMAL(12,2)
);

CREATE TABLE gold.fact_attendance_daily (
    employee_sk     BIGINT NOT NULL,
    department_sk   BIGINT NOT NULL,
    date_sk         INT NOT NULL,
    hours_worked    DECIMAL(5,2),
    is_absent       BIT,
    is_late         BIT,
    leave_type      VARCHAR(30)
);

CREATE TABLE gold.fact_headcount_snapshot (
    employee_sk     BIGINT NOT NULL,
    department_sk   BIGINT NOT NULL,
    date_sk         INT NOT NULL,
    job_grade_sk    BIGINT NOT NULL,
    is_active       BIT,
    is_new_hire     BIT,
    is_termination  BIT,
    tenure_days     INT
);

-- BATCH 3: constraints (documentation + Power BI relationship auto-detection;
-- NOT ENFORCED by the Fabric Warehouse engine -- referential integrity is
-- the responsibility of the load logic)

ALTER TABLE gold.dim_date ADD CONSTRAINT PK_dim_date PRIMARY KEY NONCLUSTERED (date_sk) NOT ENFORCED;
ALTER TABLE gold.dim_department ADD CONSTRAINT PK_dim_department PRIMARY KEY NONCLUSTERED (department_sk) NOT ENFORCED;
ALTER TABLE gold.dim_job_grade ADD CONSTRAINT PK_dim_job_grade PRIMARY KEY NONCLUSTERED (job_grade_sk) NOT ENFORCED;
ALTER TABLE gold.dim_employee ADD CONSTRAINT PK_dim_employee PRIMARY KEY NONCLUSTERED (employee_sk) NOT ENFORCED;

ALTER TABLE gold.fact_payroll_monthly ADD CONSTRAINT FK_payroll_employee FOREIGN KEY (employee_sk) REFERENCES gold.dim_employee(employee_sk) NOT ENFORCED;
ALTER TABLE gold.fact_payroll_monthly ADD CONSTRAINT FK_payroll_department FOREIGN KEY (department_sk) REFERENCES gold.dim_department(department_sk) NOT ENFORCED;
ALTER TABLE gold.fact_payroll_monthly ADD CONSTRAINT FK_payroll_date FOREIGN KEY (date_sk) REFERENCES gold.dim_date(date_sk) NOT ENFORCED;
ALTER TABLE gold.fact_payroll_monthly ADD CONSTRAINT FK_payroll_jobgrade FOREIGN KEY (job_grade_sk) REFERENCES gold.dim_job_grade(job_grade_sk) NOT ENFORCED;

ALTER TABLE gold.fact_attendance_daily ADD CONSTRAINT FK_attendance_employee FOREIGN KEY (employee_sk) REFERENCES gold.dim_employee(employee_sk) NOT ENFORCED;
ALTER TABLE gold.fact_attendance_daily ADD CONSTRAINT FK_attendance_department FOREIGN KEY (department_sk) REFERENCES gold.dim_department(department_sk) NOT ENFORCED;
ALTER TABLE gold.fact_attendance_daily ADD CONSTRAINT FK_attendance_date FOREIGN KEY (date_sk) REFERENCES gold.dim_date(date_sk) NOT ENFORCED;

ALTER TABLE gold.fact_headcount_snapshot ADD CONSTRAINT FK_headcount_employee FOREIGN KEY (employee_sk) REFERENCES gold.dim_employee(employee_sk) NOT ENFORCED;
ALTER TABLE gold.fact_headcount_snapshot ADD CONSTRAINT FK_headcount_department FOREIGN KEY (department_sk) REFERENCES gold.dim_department(department_sk) NOT ENFORCED;
ALTER TABLE gold.fact_headcount_snapshot ADD CONSTRAINT FK_headcount_date FOREIGN KEY (date_sk) REFERENCES gold.dim_date(date_sk) NOT ENFORCED;
ALTER TABLE gold.fact_headcount_snapshot ADD CONSTRAINT FK_headcount_jobgrade FOREIGN KEY (job_grade_sk) REFERENCES gold.dim_job_grade(job_grade_sk) NOT ENFORCED;
