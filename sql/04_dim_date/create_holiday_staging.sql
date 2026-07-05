DROP TABLE IF EXISTS gold.stg_holidays;

CREATE TABLE gold.stg_holidays (
    holiday_date     DATE,
    is_holiday_us    BIT,
    is_holiday_uk    BIT,
    holiday_name     VARCHAR(100)
);
