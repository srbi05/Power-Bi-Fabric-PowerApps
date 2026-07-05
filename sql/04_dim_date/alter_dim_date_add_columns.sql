ALTER TABLE gold.dim_date ADD fiscal_quarter INT;
ALTER TABLE gold.dim_date ADD week_number INT;
ALTER TABLE gold.dim_date ADD is_holiday BIT;
ALTER TABLE gold.dim_date ADD is_holiday_us BIT;
ALTER TABLE gold.dim_date ADD is_holiday_uk BIT;
ALTER TABLE gold.dim_date ADD holiday_name VARCHAR(100);
