# DAX Measures Library

All measures live in a dedicated `_Measures` table in the semantic model
(`SM_GlobalHR_Gold`), organized into display folders.

## [Headcount]

```dax
Active Headcount =
CALCULATE(
    DISTINCTCOUNT(fact_headcount_snapshot[employee_sk]),
    fact_headcount_snapshot[is_active] = TRUE()
)
```
*Note: compares to `TRUE()` not `1` -- Direct Lake surfaces SQL `BIT` columns
as native DAX Booleans, which do not implicitly compare to integers.*

```dax
New Hires MTD =
CALCULATE([Active Headcount], fact_headcount_snapshot[is_new_hire] = TRUE())
```

```dax
Terminations MTD =
CALCULATE(
    DISTINCTCOUNT(fact_headcount_snapshot[employee_sk]),
    fact_headcount_snapshot[is_termination] = TRUE()
)
```
*Note: does NOT nest inside [Active Headcount] -- a terminated employee's
snapshot row has is_active=0 in their termination month, so requiring both
flags simultaneously returns a near-permanent blank.*

```dax
Avg Tenure (Years) =
DIVIDE(
    CALCULATE(AVERAGE(fact_headcount_snapshot[tenure_days]), fact_headcount_snapshot[is_active] = TRUE()),
    365
)
```

```dax
Net Headcount Change = [New Hires MTD] - [Terminations MTD]
```

## [Attrition]

```dax
Attrition Rate % = DIVIDE([Terminations MTD], [Active Headcount])
```
*Format as Percentage in the model, not just in a visual override.*

```dax
Avg Active Headcount (Rolling 12M) =
VAR MaxDate = MAX(dim_date[full_date])
VAR StartDate = EDATE(MaxDate, -11)
VAR SnapshotDates =
    CALCULATETABLE(VALUES(dim_date[full_date]), DATESBETWEEN(dim_date[full_date], StartDate, MaxDate))
RETURN
AVERAGEX(SnapshotDates, CALCULATE([Active Headcount]))
```

```dax
Rolling 12M Terminations =
VAR MaxDate = MAX(dim_date[full_date])
VAR StartDate = EDATE(MaxDate, -11)
RETURN
CALCULATE([Terminations MTD], DATESBETWEEN(dim_date[full_date], StartDate, MaxDate))
```

```dax
Rolling 12M Attrition Rate % =
DIVIDE([Rolling 12M Terminations], [Avg Active Headcount (Rolling 12M)])
```

```dax
YTD Terminations = CALCULATE([Terminations MTD], DATESYTD(dim_date[full_date]))
```

```dax
Attrition Count = DISTINCTCOUNT(dim_employee[employee_sk])
```
*Used with attrition_category or exit_reason as the visual's category field
-- deliberately has no explicit filter argument, so the visual's own
grouping determines what's counted (an explicit filter on the same column
would override/replace the visual's grouping context entirely).*

## [Payroll]

```dax
Total Payroll Cost = SUM(fact_payroll_monthly[gross_pay])
Total Net Pay = SUM(fact_payroll_monthly[net_pay])
Total Overtime Pay = SUM(fact_payroll_monthly[overtime_pay])
Total Deductions = SUM(fact_payroll_monthly[deductions])
```

```dax
Avg Payroll per Employee =
DIVIDE([Total Payroll Cost], DISTINCTCOUNT(fact_payroll_monthly[employee_sk]))
```

```dax
Avg Salary by Grade =
AVERAGEX(
    VALUES(dim_job_grade[grade_name]),
    DIVIDE([Total Payroll Cost], DISTINCTCOUNT(fact_payroll_monthly[employee_sk]))
)
```

```dax
Overtime % of Payroll = DIVIDE([Total Overtime Pay], [Total Payroll Cost])
```

```dax
Salary Variance % vs Grade Band Midpoint =
VAR BandMidpoint =
    AVERAGEX(
        dim_job_grade,
        (dim_job_grade[salary_band_min] + dim_job_grade[salary_band_max]) / 2
    )
VAR ActualAvg = [Avg Salary by Grade]
RETURN
DIVIDE(ActualAvg - BandMidpoint, BandMidpoint)
```
*KNOWN LIMITATION: no true budget data source exists. This substitutes
variance-from-observed-grade-band-midpoint for a real budget comparison.
Since the band itself was derived from the same salary data, this measure
will trend toward small values by construction -- it answers "how far from
typical for this grade" not "how far from a target."*

```dax
Pay Equity Gap % =
VAR OverallAvg = CALCULATE(AVERAGE(dim_employee[base_salary]), ALL(dim_employee[gender]))
VAR GroupAvg = AVERAGEX(VALUES(dim_employee[gender]), CALCULATE(AVERAGE(dim_employee[base_salary])))
RETURN
DIVIDE(GroupAvg - OverallAvg, OverallAvg)
```

## [Time Intelligence] -- Calculation Group: "Time Comparison"

Column name: `Time Calculation`. Items:

```dax
Current Period = SELECTEDMEASURE()

Prior Period = CALCULATE(SELECTEDMEASURE(), SAMEPERIODLASTYEAR(dim_date[full_date]))

YoY Change =
SELECTEDMEASURE() - CALCULATE(SELECTEDMEASURE(), 'Time Comparison'[Time Calculation] = "Prior Period")

YoY Change % =
VAR PriorValue = CALCULATE(SELECTEDMEASURE(), 'Time Comparison'[Time Calculation] = "Prior Period")
RETURN DIVIDE(SELECTEDMEASURE() - PriorValue, PriorValue)

Prior Month = CALCULATE(SELECTEDMEASURE(), PREVIOUSMONTH(dim_date[full_date]))

MoM Change =
SELECTEDMEASURE() - CALCULATE(SELECTEDMEASURE(), 'Time Comparison'[Time Calculation] = "Prior Month")

MoM Change % =
VAR PriorValue = CALCULATE(SELECTEDMEASURE(), 'Time Comparison'[Time Calculation] = "Prior Month")
RETURN DIVIDE(SELECTEDMEASURE() - PriorValue, PriorValue)
```

**KNOWN LIMITATION:** source data only covers 2024, so `Prior Period`/
`YoY Change`/`YoY Change %` correctly return blank for every period (no
2023 data to compare against). This is correct DAX behavior, not a bug --
included to demonstrate the pattern even though it has no visible output
on the current dataset. MoM variants use `PREVIOUSMONTH` instead and
produce real results across the 12-month range.

**Prerequisite:** `dim_date` must be explicitly marked as the model's Date
Table (Model view → dim_date → Mark as date table → full_date), or all
time-intelligence functions silently return blank with no error. See
`docs/TROUBLESHOOTING_LOG.md`.

**Scatter plot / pyramid helper measures:**

```dax
Avg Tenure Days = AVERAGE(fact_headcount_snapshot[tenure_days])
```
*Required because once a calculation group exists in the model, implicit
measures (dragging a raw column onto a visual and picking an aggregation)
are disabled -- every value on every visual must be an explicit measure.*

```dax
Headcount Signed (Pyramid) =
VAR BaseCount = [Active Headcount]
RETURN IF(SELECTEDVALUE(dim_employee[gender]) = "Male", -BaseCount, BaseCount)
```
*Note: this is a 2-way split (Male vs. everything else). Non-binary and
"Prefer not to say" both land on the positive side alongside Female. A
cleaner 4-way signed split would need a different visual approach.*
