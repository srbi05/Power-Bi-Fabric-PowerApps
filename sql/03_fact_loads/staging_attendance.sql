DROP TABLE IF EXISTS gold.stg_attendance;

CREATE TABLE gold.stg_attendance (
    AttendanceID       VARCHAR(30),
    EmployeeID          VARCHAR(20),
    [Date]              DATE,
    DayOfWeek           VARCHAR(20),
    [Month]             VARCHAR(20),
    AttendanceCode      VARCHAR(10),
    AttendanceDesc      VARCHAR(50),
    HoursWorked         DECIMAL(5,2),
    Department           VARCHAR(50),
    Region                VARCHAR(50),
    SourceSystem          VARCHAR(50),
    LoadDate               DATE
);
