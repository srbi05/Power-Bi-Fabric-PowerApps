-- Run this ALONE, in a fresh query tab. CREATE/ALTER PROCEDURE must be
-- the only statement in its batch in Fabric Warehouse.

CREATE OR ALTER PROCEDURE gold.sp_Load_Fact_Headcount_Snapshot
AS
BEGIN

    WITH month_offsets AS (
        SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3
        UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7
        UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11
    ),
    snapshot_dates AS (
        SELECT EOMONTH(DATEFROMPARTS(2024, 1, 1), n) AS snapshot_date
        FROM month_offsets
    ),
    eligible_employees AS (
        SELECT
            s.EmployeeID,
            s.Department,
            s.JobGrade,
            s.HireDate,
            s.TerminationDate,
            sd.snapshot_date
        FROM gold.stg_employee_master s
        CROSS JOIN snapshot_dates sd
        WHERE s.HireDate <= sd.snapshot_date
    )
    INSERT INTO gold.fact_headcount_snapshot (
        employee_sk, department_sk, date_sk, job_grade_sk,
        is_active, is_new_hire, is_termination, tenure_days
    )
    SELECT
        e.employee_sk,
        d.department_sk,
        CAST(CONVERT(VARCHAR(8), ee.snapshot_date, 112) AS INT) AS date_sk,
        j.job_grade_sk,
        CASE WHEN ee.TerminationDate IS NULL OR ee.TerminationDate > ee.snapshot_date
             THEN 1 ELSE 0 END AS is_active,
        CASE WHEN YEAR(ee.HireDate) = YEAR(ee.snapshot_date)
              AND MONTH(ee.HireDate) = MONTH(ee.snapshot_date)
             THEN 1 ELSE 0 END AS is_new_hire,
        CASE WHEN ee.TerminationDate IS NOT NULL
              AND YEAR(ee.TerminationDate) = YEAR(ee.snapshot_date)
              AND MONTH(ee.TerminationDate) = MONTH(ee.snapshot_date)
             THEN 1 ELSE 0 END AS is_termination,
        DATEDIFF(DAY, ee.HireDate, ee.snapshot_date) AS tenure_days
    FROM eligible_employees ee
    JOIN gold.dim_employee e
        ON e.employee_id = ee.EmployeeID
        AND ee.snapshot_date BETWEEN e.effective_start_date AND e.effective_end_date
    JOIN gold.dim_department d
        ON d.department_id = ee.Department
    JOIN gold.dim_job_grade j
        ON j.job_grade_id = ee.JobGrade;

    TRUNCATE TABLE gold.stg_employee_master;

END;
