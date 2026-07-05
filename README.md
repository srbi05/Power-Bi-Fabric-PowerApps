# GlobalBank Corp HR Analytics

An end-to-end HR analytics platform built on Microsoft Fabric, covering the full
medallion architecture (Bronze → Silver → Gold), a certified Power BI semantic
model in Direct Lake mode, and a 5-page executive dashboard.

## Architecture

```
Bronze (Lakehouse)  →  Silver (Lakehouse)  →  Gold (Warehouse, star schema)
                                                      ↓
                                        Power BI Semantic Model (Direct Lake)
                                                      ↓
                                        Executive HR Dashboard (5 pages)
```

**Gold layer star schema:** 4 dimensions (`dim_employee` [SCD Type 2],
`dim_department`, `dim_date`, `dim_job_grade`), 3 facts
(`fact_payroll_monthly`, `fact_attendance_daily`, `fact_headcount_snapshot`).

## Repo structure

- `/sql/01_gold_schema` — Warehouse and star schema DDL
- `/sql/02_scd2_dim_employee` — SCD Type 2 load logic for the employee dimension
- `/sql/03_fact_loads` — Stored procedures loading all 3 fact tables via as-of
  SCD2 joins
- `/sql/04_dim_date` — Calendar generation (2015–2030) with US/UK bank holidays
- `/sql/05_powerbi_views` — Consumption-layer views for Power BI
- `/sql/06_dashboard_extensions` — Schema extensions added to support the
  executive dashboard (demographics, exit reasons, attrition categorization)
- `/dax` — Full DAX measures library reference
- `/docs` — Architecture Decision Record, data dictionary, known limitations,
  and a troubleshooting log documenting real platform issues hit during the build
- `/power_bi_theme` — Brand theme JSON (GlobalBank navy/gold)

## Key data-source verification

Every fact table load was verified against source row counts, not just
"ran without error":

| Fact table | Loaded rows | Source verification |
|---|---|---|
| fact_payroll_monthly | 109,680 | Exact match to source CSV row count |
| fact_attendance_daily | 180,000 | Exact match to source CSV row count |
| fact_headcount_snapshot | 116,243 | Exact match to independently recomputed expected count |

## Known limitations

See `/docs/KNOWN_LIMITATIONS.md` for a full list of honest data/platform
gaps (no requisition/budget source data, Q&A deprecation, map visual
licensing, etc.) and how each was resolved or substituted.
