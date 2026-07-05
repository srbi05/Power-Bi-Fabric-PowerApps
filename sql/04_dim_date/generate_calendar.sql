-- Generates every date from 2015-01-01 to 2030-12-31 using a tally
-- (number series) CTE -- avoids relying on recursive CTEs, which can be
-- unreliable in Fabric Warehouse.

WITH digits AS (
    SELECT 0 AS d UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
    UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9
),
tally AS (
    SELECT (d4.d * 1000 + d3.d * 100 + d2.d * 10 + d1.d) AS n
    FROM digits d1
    CROSS JOIN digits d2
    CROSS JOIN digits d3
    CROSS JOIN digits d4
),
calendar AS (
    SELECT DATEADD(DAY, n, '2015-01-01') AS full_date
    FROM tally
    WHERE n <= DATEDIFF(DAY, '2015-01-01', '2030-12-31')
)
INSERT INTO gold.dim_date (
    date_sk, full_date, year, quarter, month, month_name, day_of_week,
    is_weekend, fiscal_year, fiscal_quarter, week_number
)
SELECT
    CAST(CONVERT(VARCHAR(8), full_date, 112) AS INT) AS date_sk,
    full_date,
    YEAR(full_date) AS year,
    DATEPART(QUARTER, full_date) AS quarter,
    MONTH(full_date) AS month,
    DATENAME(MONTH, full_date) AS month_name,
    DATENAME(WEEKDAY, full_date) AS day_of_week,
    CASE WHEN DATEPART(WEEKDAY, full_date) IN (1, 7) THEN 1 ELSE 0 END AS is_weekend,
    -- Fiscal year assumed = calendar year (adjust here if GlobalBank uses
    -- a non-calendar fiscal year, e.g. April-start)
    YEAR(full_date) AS fiscal_year,
    DATEPART(QUARTER, full_date) AS fiscal_quarter,
    DATEPART(ISO_WEEK, full_date) AS week_number
FROM calendar;

SELECT COUNT(*) AS row_count FROM gold.dim_date;
