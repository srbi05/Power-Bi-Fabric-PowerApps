-- =====================================================================
-- Step 1: Reload staging (it was truncated after the SCD2 test)
-- =====================================================================
COPY INTO gold.stg_employee_master
FROM 'https://onelake.dfs.fabric.microsoft.com/10414fdb-c3ce-488a-a530-ba74cbb5cbc0/7324d38f-5ffa-420d-b5c6-bc72f9d0775c/Files/raw/Employees/GlobalBank_Employee_Master.csv'
WITH (
    FILE_TYPE = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ','
);

-- =====================================================================
-- Step 2: Load dim_department -- distinct departments only
-- =====================================================================
INSERT INTO gold.dim_department (department_id, department_name, division, cost_center)
SELECT DISTINCT
    Department,
    Department,
    NULL,
    NULL
FROM gold.stg_employee_master s
WHERE NOT EXISTS (
    SELECT 1 FROM gold.dim_department d WHERE d.department_id = s.Department
);

-- =====================================================================
-- Step 3: Load dim_job_grade -- distinct grades, salary bands derived
-- from actual min/max BaseSalary_USD observed per grade
-- =====================================================================
INSERT INTO gold.dim_job_grade (job_grade_id, grade_name, grade_level, salary_band_min, salary_band_max)
SELECT
    JobGrade,
    JobGrade,
    TRY_CAST(REPLACE(JobGrade, 'G', '') AS INT),
    MIN(BaseSalary_USD),
    MAX(BaseSalary_USD)
FROM gold.stg_employee_master s
WHERE NOT EXISTS (
    SELECT 1 FROM gold.dim_job_grade j WHERE j.job_grade_id = s.JobGrade
)
GROUP BY JobGrade;

-- =====================================================================
-- Step 4: Clear staging again
-- =====================================================================
TRUNCATE TABLE gold.stg_employee_master;

-- =====================================================================
-- Verify
-- =====================================================================
SELECT * FROM gold.dim_department;
SELECT * FROM gold.dim_job_grade;
