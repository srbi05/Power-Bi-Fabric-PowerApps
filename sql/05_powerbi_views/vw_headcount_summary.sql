CREATE OR ALTER VIEW gold.vw_Headcount_Summary
AS
SELECT
    dd.full_date            AS snapshot_date,
    dd.year,
    dd.month,
    dd.month_name,
    dd.fiscal_year,
    dd.fiscal_quarter,
    dp.department_name,
    jg.grade_name,
    COUNT(*)                                  AS employees_on_roster,
    SUM(CAST(fh.is_active AS INT))            AS active_headcount,
    SUM(CAST(fh.is_new_hire AS INT))          AS new_hires,
    SUM(CAST(fh.is_termination AS INT))       AS terminations,
    AVG(CAST(fh.tenure_days AS FLOAT)) / 365.0 AS avg_tenure_years
FROM gold.fact_headcount_snapshot fh
JOIN gold.dim_date dd ON fh.date_sk = dd.date_sk
JOIN gold.dim_department dp ON fh.department_sk = dp.department_sk
JOIN gold.dim_job_grade jg ON fh.job_grade_sk = jg.job_grade_sk
GROUP BY
    dd.full_date, dd.year, dd.month, dd.month_name, dd.fiscal_year, dd.fiscal_quarter,
    dp.department_name, jg.grade_name;
