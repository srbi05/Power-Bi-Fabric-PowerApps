# Known Limitations

Documented honestly rather than glossed over -- each of these reflects a
real constraint in the source data or the platform, not an implementation
shortcut.

## Data gaps
- **No requisition/recruiting data.** No source file represents open job
  postings. The "Open Requisitions" KPI from the original spec could not
  be built and was replaced with Avg Tenure (Years).
- **No budget data.** No source represents a payroll budget or salary
  targets. "Salary Variance % vs Budget" was replaced with variance
  against the observed salary band midpoint for each job grade.
- **No monthly bonus data.** Payroll fact's `bonus` column is always NULL
  -- Employee_Master has an annual bonus figure, but the monthly Payroll
  file has no equivalent line item.
- **No lateness indicator.** Attendance source data has Present/WFH/On
  Leave/Half Day/Absent codes but nothing distinguishing a late arrival.
  `is_late` is always 0.
- **Single year of data (2024 only).** Year-over-year DAX measures
  (built via the Time Comparison calculation group) are correctly
  implemented but return blank for every period, since there's no 2023
  data to compare against.

## Platform / licensing constraints
- **Q&A visual deprecated.** Microsoft deprecated Q&A visual creation
  ahead of full retirement in December 2026. Its replacement, Copilot,
  requires an F64+ Fabric capacity not available on this trial tenant.
- **Map/Filled Map visuals require two separate opt-ins** -- a tenant
  admin setting AND a local Power BI Desktop security setting -- both
  needed simultaneously, which is not obvious from either UI in isolation.
- **Direct Lake does not support calculated columns.** Any derived
  per-row column (age_band, attrition_category, etc.) had to be computed
  in SQL at the Warehouse layer instead of as a DAX calculated column.
- **Direct Lake does not support non-materialized SQL views as a data
  source in pure Direct Lake mode** -- relevant if a future iteration
  wants a single combined "Headcount + Attrition Category" table for a
  richer funnel visual; that would fall back to DirectQuery for that one
  table.

## Design simplifications
- **Headcount Signed (Pyramid) measure is a 2-way split** (Male vs.
  everyone else), not a full 4-way gender breakdown, due to how signed
  bar charts work in Power BI without a custom visual.
- **Fiscal year assumed = calendar year.** No fiscal year offset was
  specified or available to confirm GlobalBank's actual fiscal calendar.
- **"Mutual Agreement" exit reason classified as Involuntary** in the
  attrition funnel -- a defensible but debatable categorization, since
  mutual-agreement exits are sometimes treated as a third category
  entirely in real HR reporting.
