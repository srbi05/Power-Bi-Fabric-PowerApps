UPDATE dd
SET
    dd.is_holiday = 1,
    dd.is_holiday_us = h.is_holiday_us,
    dd.is_holiday_uk = h.is_holiday_uk,
    dd.holiday_name = h.holiday_name
FROM gold.dim_date dd
JOIN gold.stg_holidays h
    ON dd.full_date = h.holiday_date;

-- Default non-holiday rows to 0 rather than NULL
UPDATE gold.dim_date
SET is_holiday = 0, is_holiday_us = 0, is_holiday_uk = 0
WHERE is_holiday IS NULL;

TRUNCATE TABLE gold.stg_holidays;

-- Verify
SELECT COUNT(*) AS total_dates,
       SUM(CAST(is_holiday AS INT)) AS total_holiday_flags,
       SUM(CAST(is_holiday_us AS INT)) AS us_holidays,
       SUM(CAST(is_holiday_uk AS INT)) AS uk_holidays
FROM gold.dim_date;

SELECT TOP 15 full_date, day_of_week, is_weekend, is_holiday_us, is_holiday_uk, holiday_name
FROM gold.dim_date
WHERE is_holiday = 1
ORDER BY full_date;
