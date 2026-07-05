CREATE OR ALTER PROCEDURE gold.sp_Load_Fact_Attendance_Daily
AS
BEGIN

    INSERT INTO gold.fact_attendance_daily (
        employee_sk, department_sk, date_sk,
        hours_worked, is_absent, is_late, leave_type
    )
    SELECT
        e.employee_sk,
        d.department_sk,
        CAST(CONVERT(VARCHAR(8), s.[Date], 112) AS INT) AS date_sk,
        s.HoursWorked,
        CASE WHEN s.AttendanceCode = 'A' THEN 1 ELSE 0 END AS is_absent,
        0 AS is_late,  -- source data has no lateness indicator
        CASE WHEN s.AttendanceCode = 'L' THEN 'On Leave' ELSE NULL END AS leave_type
    FROM gold.stg_attendance s
    -- As-of join: match the employee version that was current on the attendance date
    JOIN gold.dim_employee e
        ON e.employee_id = s.EmployeeID
        AND s.[Date] BETWEEN e.effective_start_date AND e.effective_end_date
    JOIN gold.dim_department d
        ON d.department_id = s.Department;

    TRUNCATE TABLE gold.stg_attendance;

END;
