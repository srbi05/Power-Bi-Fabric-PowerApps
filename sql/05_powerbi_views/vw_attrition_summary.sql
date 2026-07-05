CREATE OR ALTER VIEW gold.vw_Attrition_Summary
AS
SELECT
    dd.full_date          AS snapshot_date,
    dd.year,
    dd.month,
    dd.month_name,
    dp.department_name,
    SUM(CAST(fh.is_active AS INT))       AS active_headcount,
    SUM(CAST(fh.is_termination AS INT))  AS terminations,
    CASE WHEN SUM(CAST(fh.is_active AS INT)) = 0 THEN NULL
         ELSE CAST(SUM(CAST(fh.is_termination AS INT)) AS FLOAT)
              / NULLIF(SUM(CAST(fh.is_active AS INT)), 0) * 100
    END AS attrition_rate_pct
FROM gold.fact_headcount_snapshot fh
JOIN gold.dim_date dd ON fh.date_sk = dd.date_sk
JOIN gold.dim_department dp ON fh.department_sk = dp.department_sk
GROUP BY dd.full_date, dd.year, dd.month, dd.month_name, dp.department_name;
