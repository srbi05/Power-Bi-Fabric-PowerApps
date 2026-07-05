# Troubleshooting Log

Real issues hit during this build, in the order they occurred, with root
cause and fix. Kept here rather than only in chat history since this is
genuinely useful reference material -- both for anyone repeating this
build and as evidence of actual debugging depth.

## Fabric Warehouse SQL quirks

**`CREATE SCHEMA` / `CREATE PROCEDURE` / `CREATE VIEW` must be the only
statement in their batch.** Unlike SSMS, the Fabric Warehouse SQL editor
does not split batches on `GO`. Submitting `CREATE SCHEMA gold; GO;
CREATE TABLE ...` in one execution fails with a syntax error on the
CREATE SCHEMA line itself. Fix: run these statements alone, in their own
query execution, every time.

**`IDENTITY` columns must be `BIGINT`, not `INT`.** Fabric Warehouse
rejects `INT IDENTITY(1,1)` outright with "Identity column must be of
data type BIGINT."

**`IDENTITY` cannot specify seed/increment.** Even `BIGINT
IDENTITY(1,1)` fails -- Fabric Warehouse only supports bare `IDENTITY`
with implicit seed 1, increment 1.

**Surrogate key type mismatches break FK constraints silently until you
add them.** Dimension tables built with `BIGINT IDENTITY` but fact tables
built with plain `INT` for the same logical key produced a `FOREIGN KEY
NOT ENFORCED` creation failure: "Column is not the same data type as
referencing column." Fix: match types explicitly across every FK pair
from the start.

**`INFORMATION_SCHEMA.COLUMNS` failed with "Invalid object name" under
case-sensitive collation.** Fell back to `sys.tables`/`sys.columns`/
`sys.types` joins, which work regardless of collation settings.

## SCD2 / fact load bugs

**Backdating bug: first-load `effective_start_date = GETDATE()` broke
every historical fact join.** Setting the initial SCD2 load's start date
to "today" meant historical payroll/attendance records (dated in the
past) fell outside the `BETWEEN effective_start_date AND
effective_end_date` as-of join range entirely -- 0 rows loaded, no error.
Fix: backdate the first-ever version of each employee to a sentinel date
(1900-01-01) using `ROW_NUMBER() OVER (PARTITION BY employee_id ORDER BY
effective_end_date ASC)`.

**Boolean vs. Integer comparison in Direct Lake DAX.** SQL `BIT` columns
surface as native DAX Booleans in Direct Lake. Measures written as
`fact_table[is_active] = 1` failed with "DAX comparison operations do not
support comparing values of type True/False with values of type
Integer." Fix: compare to `TRUE()` instead of `1`.

**Nesting a termination filter inside an already-active-filtered measure
returns near-permanent blank.** `Terminations MTD` was initially written
as `CALCULATE([Active Headcount], is_termination = TRUE())` -- but a
terminated employee's snapshot row has `is_active = 0` in their
termination month, so requiring both flags is almost always a
contradiction. Fix: count directly with `DISTINCTCOUNT`, don't nest
inside a measure that already filters on the opposite condition.

## Direct Lake / semantic model

**Calculated columns are not supported in Direct Lake.** Any per-row
derived value (age_band, attrition_category, sort helpers) had to be
computed in SQL at the Warehouse layer and picked up via a model
refresh/reframe, not built as a DAX calculated column.

**Schema changes require a manual refresh/reframe.** Adding columns to a
Warehouse table does not automatically appear in a Direct Lake semantic
model's field list -- requires an explicit refresh action on the
semantic model item.

**`PREVIOUSMONTH`/`SAMEPERIODLASTYEAR` silently return blank with no
error if `dim_date` isn't explicitly marked as the model's Date Table.**
No warning, no error -- every time-intelligence calculation item just
evaluated to blank. Fix: Model view → dim_date → Mark as date table →
select `full_date`.

**Smart-quotes copy-paste bug in calculation item DAX.** Pasting
`'Time Comparison'[Time Calculation] = "Prior Month"` from a rich-text
source (chat, browser) sometimes converts straight quotes to curly
"smart quotes," which look identical but don't match as string literals
in DAX. Symptom: the calculation evaluates without error but always
returns the *current* value instead of the shifted one (net effect: MoM
Change always computes to exactly 0, since it's silently comparing the
current period against itself). Fix: delete and manually retype the
quoted string rather than pasting.

**Creating a calculation group disables implicit measures model-wide.**
After adding the first calculation group, dragging a raw column onto a
visual and picking an aggregation (e.g., "Average of tenure_days") is no
longer possible -- Power BI shows the message and requires an explicit
measure to be created first for every value used anywhere in the report,
even on visuals unrelated to the calculation group.

## Power BI report-building

**"Show value as → Percent of Grand Total" silently recalculates a
column into something completely different than the underlying
measure.** Applied accidentally to a table's Attrition Rate % column, it
turned an already-correct percentage measure into a "percent of the
sum of all months' rates" calculation, producing wildly wrong-looking
numbers (a single month showing 16% attrition) despite the DAX itself
being correct.

**Conditional-formatting "Rules" editor's two conditions are AND, not
OR.** Attempting a symmetric two-sided threshold (`>= 5% OR <= -5%`) as
a single rule with `>= 0.05 AND < -0.05` is impossible by construction
(mutually exclusive) and never fires. Fix: two separate single-sided
rules instead of one combined rule.

**Conditional-formatting Rules applied to a ratio/percentage column
produces a nonsensical value on the table's Total row.** A percentage
gap doesn't have a mathematically valid "total" in the first place;
Power BI's Total row for that column computed something structurally
different from the individual rows, which the rules engine misread and
displayed as `-1`. Fix: disable the Total row entirely for
ratio/percentage columns -- the correct analytical choice regardless of
the display bug.

**Stray "(Blank)" category rows appear in any visual grouped by a column
with some NULL values** (attrition funnel, exit reason chart, pay equity
table) -- representing currently-active employees who have no exit
reason / gender / etc. yet. Fix: add an "is not blank" filter on that
column, per visual, as needed.

**Stale cached visual results persist after a fix has actually taken
effect elsewhere in the model.** A KPI card kept showing `--` even after
the underlying measure was confirmed correct via a separate table visual
-- removing and re-adding the field to the card's Value well forced a
fresh query and resolved it. Same class of issue caused a map visual to
initially not respond to slicer selections at all until an Edit
Interactions check was performed (in that case the actual cause was an
accidental "None" interaction override, not caching).

**Page navigation buttons always exclude the current page from their own
destination dropdown**, by design (not a bug) -- a page can never contain
a working button pointing to itself. Building a full N-page nav bar
requires assembling it across at least 2 different pages, then
copy-pasting the completed set everywhere.

**Drillthrough field well moved between Power BI UI versions.** Older
guidance describes a "Drillthrough filters well" always visible in the
Visualizations pane; the current interface requires first setting a
page's **Page type** to "Drillthrough" before a "Drill through from"
field well appears at all.

**Map/Filled Map visuals require two independent opt-ins
simultaneously**: a tenant-level Admin Portal setting AND a local Power
BI Desktop security setting (File → Options → Security → Map and Filled
Map Visuals, requiring an app restart). Enabling only one produces the
same `FilledMapVisualNotEnabled` error as enabling neither.

**Histogram is not a native visual** -- requires installing the official
Microsoft "Histogram Chart" custom visual from AppSource.

**Q&A visual creation is unavailable** as of mid-2026, ahead of its
scheduled December 2026 full retirement (Microsoft deprecation
announcement, December 2025). Its replacement, Copilot, requires an
F64+ Fabric capacity tier.
