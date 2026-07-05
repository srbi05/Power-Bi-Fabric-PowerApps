DROP TABLE IF EXISTS gold.stg_payroll;

CREATE TABLE gold.stg_payroll (
    PayrollID           VARCHAR(30),
    EmployeeID           VARCHAR(20),
    PayPeriod            VARCHAR(10),
    PayDate               DATE,
    Department            VARCHAR(50),
    Region                VARCHAR(50),
    JobGrade              VARCHAR(10),
    MonthlySalary_USD    DECIMAL(12,2),
    OvertimeHours         DECIMAL(6,2),
    OvertimePay_USD      DECIMAL(12,2),
    Deductions_USD        DECIMAL(12,2),
    NetPay_USD            DECIMAL(12,2),
    PayrollStatus         VARCHAR(20),
    CostCenter             VARCHAR(20),
    SourceSystem           VARCHAR(50),
    LoadDate                DATE
);
