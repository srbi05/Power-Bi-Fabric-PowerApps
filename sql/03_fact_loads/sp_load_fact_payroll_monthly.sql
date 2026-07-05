CREATE OR ALTER PROCEDURE gold.sp_Load_Fact_Payroll_Monthly
AS
BEGIN

    INSERT INTO gold.fact_payroll_monthly (
        employee_sk, department_sk, date_sk, job_grade_sk,
        base_pay, bonus, overtime_pay, deductions, gross_pay, net_pay
    )
    SELECT
        e.employee_sk,
        d.department_sk,
        CAST(CONVERT(VARCHAR(8), s.PayDate, 112) AS INT) AS date_sk,
        j.job_grade_sk,
        s.MonthlySalary_USD AS base_pay,
        NULL AS bonus,
        s.OvertimePay_USD AS overtime_pay,
        s.Deductions_USD AS deductions,
        (s.MonthlySalary_USD + s.OvertimePay_USD) AS gross_pay,
        s.NetPay_USD AS net_pay
    FROM gold.stg_payroll s
    -- As-of join: match the employee version that was current on PayDate
    JOIN gold.dim_employee e
        ON e.employee_id = s.EmployeeID
        AND s.PayDate BETWEEN e.effective_start_date AND e.effective_end_date
    JOIN gold.dim_department d
        ON d.department_id = s.Department
    JOIN gold.dim_job_grade j
        ON j.job_grade_id = s.JobGrade;

    TRUNCATE TABLE gold.stg_payroll;

END;
