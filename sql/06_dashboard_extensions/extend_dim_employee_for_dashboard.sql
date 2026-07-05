-- =====================================================================
-- Schema extensions added to support Scenario 5 (Executive Dashboard)
--
-- These fields exist in the original Employee_Master.csv source but were
-- not brought into dim_employee during the initial Gold layer build in
-- Scenario 3. Adding them here rather than re-architecting the dimension,
-- since they are non-SCD2-tracked demographic/reference attributes.
-- =====================================================================

-- Demographics and exit reason (needed for D&I and Attrition pages)
ALTER TABLE gold.dim_employee ADD gender VARCHAR(20);
ALTER TABLE gold.dim_employee ADD ethnicity VARCHAR(50);
ALTER TABLE gold.dim_employee ADD date_of_birth DATE;
ALTER TABLE gold.dim_employee ADD exit_reason VARCHAR(100);

-- Age band (computed in SQL, not as a Direct Lake calculated column --
-- Direct Lake models do not support calculated columns; see
-- docs/TROUBLESHOOTING_LOG.md)
ALTER TABLE gold.dim_employee ADD age_band VARCHAR(20);

-- Attrition risk score and salary, for the scatter plot analysis
ALTER TABLE gold.dim_employee ADD attrition_category VARCHAR(20);
ALTER TABLE gold.dim_employee ADD attrition_category_sort INT;
ALTER TABLE gold.dim_employee ADD attrition_risk_score INT;
ALTER TABLE gold.dim_employee ADD base_salary DECIMAL(12,2);

-- ---------------------------------------------------------------------
-- Backfill (assumes gold.stg_employee_master is freshly loaded)
-- ---------------------------------------------------------------------
UPDATE d
SET
    d.gender = s.Gender,
    d.ethnicity = s.Ethnicity,
    d.date_of_birth = s.DateOfBirth,
    d.exit_reason = s.ExitReason,
    d.attrition_risk_score = s.AttritionRiskScore,
    d.base_salary = s.BaseSalary_USD,
    d.attrition_category =
        CASE s.ExitReason
            WHEN 'Resignation' THEN 'Voluntary'
            WHEN 'Better Opportunity' THEN 'Voluntary'
            WHEN 'Relocation' THEN 'Voluntary'
            WHEN 'Personal Reasons' THEN 'Voluntary'
            WHEN 'Performance' THEN 'Involuntary'
            WHEN 'Redundancy' THEN 'Involuntary'
            WHEN 'Mutual Agreement' THEN 'Involuntary'
            WHEN 'Retirement' THEN 'Retirement'
            WHEN 'Contract End' THEN 'Contract End'
            ELSE NULL
        END
FROM gold.dim_employee d
JOIN gold.stg_employee_master s
    ON d.employee_id = s.EmployeeID;

UPDATE gold.dim_employee
SET attrition_category_sort =
    CASE attrition_category
        WHEN 'Voluntary' THEN 1
        WHEN 'Involuntary' THEN 2
        WHEN 'Retirement' THEN 3
        WHEN 'Contract End' THEN 4
        ELSE NULL
    END;

-- Age band: buckets <25, 25-34, 35-44, 45-54, 55-64, 65+
-- Computed as of load date, accounting for whether the birthday has
-- occurred yet this calendar year (DATEDIFF(YEAR,...) alone overcounts).
UPDATE gold.dim_employee
SET age_band =
    CASE
        WHEN DATEDIFF(YEAR, date_of_birth, GETDATE()) -
             CASE WHEN DATEADD(YEAR, DATEDIFF(YEAR, date_of_birth, GETDATE()), date_of_birth) > GETDATE()
                  THEN 1 ELSE 0 END < 25 THEN '<25'
        WHEN DATEDIFF(YEAR, date_of_birth, GETDATE()) -
             CASE WHEN DATEADD(YEAR, DATEDIFF(YEAR, date_of_birth, GETDATE()), date_of_birth) > GETDATE()
                  THEN 1 ELSE 0 END BETWEEN 25 AND 34 THEN '25-34'
        WHEN DATEDIFF(YEAR, date_of_birth, GETDATE()) -
             CASE WHEN DATEADD(YEAR, DATEDIFF(YEAR, date_of_birth, GETDATE()), date_of_birth) > GETDATE()
                  THEN 1 ELSE 0 END BETWEEN 35 AND 44 THEN '35-44'
        WHEN DATEDIFF(YEAR, date_of_birth, GETDATE()) -
             CASE WHEN DATEADD(YEAR, DATEDIFF(YEAR, date_of_birth, GETDATE()), date_of_birth) > GETDATE()
                  THEN 1 ELSE 0 END BETWEEN 45 AND 54 THEN '45-54'
        WHEN DATEDIFF(YEAR, date_of_birth, GETDATE()) -
             CASE WHEN DATEADD(YEAR, DATEDIFF(YEAR, date_of_birth, GETDATE()), date_of_birth) > GETDATE()
                  THEN 1 ELSE 0 END BETWEEN 55 AND 64 THEN '55-64'
        ELSE '65+'
    END
WHERE date_of_birth IS NOT NULL;

TRUNCATE TABLE gold.stg_employee_master;
