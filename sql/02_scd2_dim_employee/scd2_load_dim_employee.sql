-- =====================================================================
-- SCD Type 2 load for dim_employee
-- Tracks: department, job grade, manager, location
-- =====================================================================

-- Staging table -- mirrors GlobalBank_Employee_Master.csv column-for-column
CREATE TABLE gold.stg_employee_master (
    EmployeeID              VARCHAR(20),
    FirstName               VARCHAR(50),
    LastName                VARCHAR(50),
    FullName                VARCHAR(100),
    Email                   VARCHAR(150),
    Phone                   VARCHAR(30),
    Gender                  VARCHAR(20),
    Ethnicity               VARCHAR(50),
    DateOfBirth             DATE,
    HireDate                DATE,
    TerminationDate         DATE,
    ExitReason              VARCHAR(100),
    Status                  VARCHAR(20),
    EmploymentType          VARCHAR(20),
    Department              VARCHAR(50),
    JobGrade                VARCHAR(10),
    JobTitle                VARCHAR(100),
    Region                  VARCHAR(50),
    Country                 VARCHAR(50),
    CostCenter              VARCHAR(20),
    ManagerID               VARCHAR(20),
    BaseSalary_USD          DECIMAL(12,2),
    BonusAmount_USD         DECIMAL(12,2),
    BonusPct                DECIMAL(6,4),
    TotalComp_USD           DECIMAL(12,2),
    YearsOfService          DECIMAL(5,1),
    AttritionRiskScore      INT,
    SourceSystem            VARCHAR(50),
    LoadDate                DATE
);

-- Load: COPY INTO gold.stg_employee_master FROM '<abfss path>' WITH (FILE_TYPE='CSV', FIRSTROW=2, FIELDTERMINATOR=',')

-- ---------------------------------------------------------------------
-- Close out rows where a tracked attribute changed
-- ---------------------------------------------------------------------
UPDATE d
SET
    d.effective_end_date = CAST(GETDATE() AS DATE),
    d.is_current = 0
FROM gold.dim_employee d
JOIN gold.stg_employee_master s
    ON d.employee_id = s.EmployeeID
WHERE d.is_current = 1
  AND (
        ISNULL(d.department_id, '') <> ISNULL(s.Department, '')
     OR ISNULL(d.job_grade_id, '')  <> ISNULL(s.JobGrade, '')
     OR ISNULL(d.manager_id, '')    <> ISNULL(s.ManagerID, '')
     OR ISNULL(d.location, '')      <> ISNULL(s.Region, '')
  );

-- ---------------------------------------------------------------------
-- Insert new-version rows: employees just closed out, plus brand new
-- employees not yet in dim_employee.
--
-- IMPORTANT: on the very first bulk load, effective_start_date must be
-- backdated to a sentinel far-past date (not GETDATE()) so that
-- historical fact data (payroll, attendance from prior periods) can
-- still join correctly via the as-of pattern used in fact loads.
-- See docs/TROUBLESHOOTING_LOG.md for the bug this fixes.
-- ---------------------------------------------------------------------
INSERT INTO gold.dim_employee (
    employee_id, first_name, last_name, department_id, job_grade_id,
    manager_id, location, effective_start_date, effective_end_date, is_current
)
SELECT
    s.EmployeeID, s.FirstName, s.LastName, s.Department, s.JobGrade,
    s.ManagerID, s.Region, CAST(GETDATE() AS DATE), '9999-12-31', 1
FROM gold.stg_employee_master s
WHERE NOT EXISTS (
    SELECT 1 FROM gold.dim_employee d
    WHERE d.employee_id = s.EmployeeID
      AND d.is_current = 1
);

TRUNCATE TABLE gold.stg_employee_master;

-- ---------------------------------------------------------------------
-- One-time fix for the FIRST load only: backdate the earliest version
-- of each employee to 1900-01-01 so historical facts join correctly.
-- ---------------------------------------------------------------------
WITH first_version AS (
    SELECT employee_sk,
           ROW_NUMBER() OVER (PARTITION BY employee_id ORDER BY effective_end_date ASC, employee_sk ASC) AS rn
    FROM gold.dim_employee
)
UPDATE d
SET d.effective_start_date = '1900-01-01'
FROM gold.dim_employee d
JOIN first_version f ON d.employee_sk = f.employee_sk
WHERE f.rn = 1;
