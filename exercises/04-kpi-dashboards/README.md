# Level 4: KPI Dashboards & Metrics

## Introduction
Learn to build and maintain KPI dashboards - a critical skill for Data Analysts supporting business decision-making.

## Learning Objectives
- Track key performance indicators
- Calculate trend metrics
- Build dashboard queries
- Monitor data quality
- Create executive reports

---

## Exercise 4.1: Current KPI Status
**Objective:** Get current status of all active KPIs

```sql
SELECT 
    kd.kpi_name,
    kd.kpi_category,
    kd.target_value,
    dm.metric_value as current_value,
    dm.status,
    kd.unit_of_measure,
    ROUND(100.0 * dm.metric_value / kd.target_value, 2) as achievement_pct
FROM kpi_definitions kd
LEFT JOIN daily_metrics dm ON kd.kpi_id = dm.kpi_id
WHERE kd.is_active = TRUE
  AND dm.metric_date = CURRENT_DATE
ORDER BY kd.kpi_category, kd.kpi_name;
```

**Expected Result:** Dashboard view of all KPIs with current status

---

## Exercise 4.2: KPIs Below Target
**Objective:** Identify KPIs that are underperforming

```sql
-- Your query here

```

**Solution:**
```sql
SELECT 
    kd.kpi_name,
    kd.kpi_category,
    kd.target_value,
    dm.metric_value as current_value,
    kd.threshold_warning,
    kd.threshold_critical,
    dm.status,
    (dm.metric_value - kd.target_value) as variance,
    ROUND(100.0 * (dm.metric_value - kd.target_value) / kd.target_value, 2) as variance_pct
FROM kpi_definitions kd
JOIN daily_metrics dm ON kd.kpi_id = dm.kpi_id
WHERE kd.is_active = TRUE
  AND dm.metric_date = CURRENT_DATE
  AND dm.metric_value < kd.target_value
ORDER BY variance_pct ASC;
```

---

## Exercise 4.3: KPI Trend Analysis (7 Days)
**Objective:** Show 7-day trend for critical KPIs

```sql
-- Your query here

```

**Solution:**
```sql
SELECT 
    kd.kpi_name,
    dm.metric_date,
    dm.metric_value,
    kd.target_value,
    dm.vs_previous_day_percentage,
    dm.status
FROM kpi_definitions kd
JOIN daily_metrics dm ON kd.kpi_id = dm.kpi_id
WHERE kd.is_active = TRUE
  AND dm.metric_date >= CURRENT_DATE - INTERVAL '7 days'
  AND kd.kpi_category IN ('SALES', 'CUSTOMER')
ORDER BY kd.kpi_name, dm.metric_date DESC;
```

---

## Exercise 4.4: Monthly Performance Summary
**Objective:** Aggregate monthly business metrics

```sql
-- Your query here

```

**Solution:**
```sql
SELECT 
    summary_year,
    summary_month,
    TO_CHAR(TO_DATE(summary_month::TEXT, 'MM'), 'Month') as month_name,
    total_revenue,
    total_transactions,
    total_customers,
    new_customers,
    average_transaction_value,
    ROUND(100.0 * new_customers / total_customers, 2) as new_customer_pct
FROM monthly_summaries
WHERE summary_year >= EXTRACT(YEAR FROM CURRENT_DATE) - 1
ORDER BY summary_year DESC, summary_month DESC;
```

---

## Exercise 4.5: Year-over-Year Comparison
**Objective:** Compare this year's performance to last year

```sql
-- Your query here

```

**Solution:**
```sql
WITH current_year AS (
    SELECT 
        summary_month,
        total_revenue,
        total_transactions,
        new_customers
    FROM monthly_summaries
    WHERE summary_year = EXTRACT(YEAR FROM CURRENT_DATE)
),
previous_year AS (
    SELECT 
        summary_month,
        total_revenue,
        total_transactions,
        new_customers
    FROM monthly_summaries
    WHERE summary_year = EXTRACT(YEAR FROM CURRENT_DATE) - 1
)
SELECT 
    cy.summary_month,
    TO_CHAR(TO_DATE(cy.summary_month::TEXT, 'MM'), 'Month') as month_name,
    cy.total_revenue as current_year_revenue,
    py.total_revenue as previous_year_revenue,
    (cy.total_revenue - py.total_revenue) as revenue_change,
    ROUND(100.0 * (cy.total_revenue - py.total_revenue) / py.total_revenue, 2) as revenue_growth_pct,
    cy.total_transactions as current_year_transactions,
    py.total_transactions as previous_year_transactions
FROM current_year cy
LEFT JOIN previous_year py ON cy.summary_month = py.summary_month
ORDER BY cy.summary_month;
```

---

## Exercise 4.6: Dashboard Snapshot
**Objective:** Create a pre-calculated dashboard snapshot

```sql
-- Your query here

```

**Solution:**
```sql
INSERT INTO dashboard_snapshots (
    snapshot_date, dashboard_name, metric_name, metric_value, metric_category
)
SELECT 
    CURRENT_DATE as snapshot_date,
    'Executive Dashboard' as dashboard_name,
    kd.kpi_name as metric_name,
    dm.metric_value,
    kd.kpi_category as metric_category
FROM kpi_definitions kd
JOIN daily_metrics dm ON kd.kpi_id = dm.kpi_id
WHERE kd.is_active = TRUE
  AND dm.metric_date = CURRENT_DATE;

-- View the snapshot
SELECT * FROM dashboard_snapshots 
WHERE snapshot_date = CURRENT_DATE 
ORDER BY metric_category, metric_name;
```

---

## Exercise 4.7: Trend Detection
**Objective:** Identify metrics with consistent upward or downward trends

```sql
-- Your query here

```

**Solution:**
```sql
WITH trend_data AS (
    SELECT 
        kd.kpi_name,
        kd.kpi_category,
        dm.metric_date,
        dm.metric_value,
        dm.vs_previous_day_percentage,
        ROW_NUMBER() OVER (PARTITION BY kd.kpi_id ORDER BY dm.metric_date DESC) as day_rank
    FROM kpi_definitions kd
    JOIN daily_metrics dm ON kd.kpi_id = dm.kpi_id
    WHERE dm.metric_date >= CURRENT_DATE - INTERVAL '7 days'
)
SELECT 
    kpi_name,
    kpi_category,
    COUNT(*) as days_tracked,
    AVG(vs_previous_day_percentage) as avg_daily_change,
    MIN(metric_value) as min_value,
    MAX(metric_value) as max_value,
    CASE 
        WHEN AVG(vs_previous_day_percentage) > 5 THEN 'STRONG UPWARD'
        WHEN AVG(vs_previous_day_percentage) > 0 THEN 'UPWARD'
        WHEN AVG(vs_previous_day_percentage) > -5 THEN 'DOWNWARD'
        ELSE 'STRONG DOWNWARD'
    END as trend_direction
FROM trend_data
GROUP BY kpi_name, kpi_category
ORDER BY avg_daily_change DESC;
```

---

## Exercise 4.8: Data Quality Monitoring
**Objective:** Track data quality metrics

```sql
-- Your query here

```

**Solution:**
```sql
SELECT 
    check_date,
    table_name,
    check_type,
    records_checked,
    records_failed,
    ROUND(100.0 * records_failed / records_checked, 2) as failure_rate,
    status,
    error_details
FROM data_quality_checks
WHERE check_date >= CURRENT_DATE - INTERVAL '7 days'
  AND status IN ('WARNING', 'FAILED')
ORDER BY check_date DESC, failure_rate DESC;
```

---

## Exercise 4.9: Report Execution History
**Objective:** Monitor report generation and performance

```sql
-- Your query here

```

**Solution:**
```sql
SELECT 
    rd.report_name,
    rd.report_category,
    re.execution_date,
    re.execution_status,
    re.execution_time_seconds,
    re.records_generated,
    re.file_size_kb
FROM report_definitions rd
JOIN report_executions re ON rd.report_id = re.report_id
WHERE re.execution_date >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY re.execution_date DESC;
```

---

## Exercise 4.10: Executive Summary Dashboard
**Objective:** Create a comprehensive executive summary

```sql
-- Your query here

```

**Solution:**
```sql
WITH today_metrics AS (
    SELECT 
        SUM(CASE WHEN kd.kpi_category = 'SALES' THEN dm.metric_value ELSE 0 END) as total_sales,
        AVG(CASE WHEN kd.kpi_name = 'Customer Engagement Score' THEN dm.metric_value END) as avg_engagement,
        AVG(CASE WHEN kd.kpi_name = 'Net Promoter Score' THEN dm.metric_value END) as avg_nps,
        COUNT(CASE WHEN dm.status = 'CRITICAL' THEN 1 END) as critical_kpis,
        COUNT(CASE WHEN dm.status = 'WARNING' THEN 1 END) as warning_kpis,
        COUNT(CASE WHEN dm.status = 'ON_TARGET' THEN 1 END) as on_target_kpis
    FROM kpi_definitions kd
    JOIN daily_metrics dm ON kd.kpi_id = dm.kpi_id
    WHERE dm.metric_date = CURRENT_DATE
),
monthly_summary AS (
    SELECT 
        total_revenue,
        total_transactions,
        new_customers,
        average_transaction_value
    FROM monthly_summaries
    WHERE summary_year = EXTRACT(YEAR FROM CURRENT_DATE)
      AND summary_month = EXTRACT(MONTH FROM CURRENT_DATE)
)
SELECT 
    'Executive Summary' as report_title,
    CURRENT_DATE as report_date,
    tm.total_sales,
    tm.avg_engagement,
    tm.avg_nps,
    tm.critical_kpis,
    tm.warning_kpis,
    tm.on_target_kpis,
    ms.total_revenue as mtd_revenue,
    ms.total_transactions as mtd_transactions,
    ms.new_customers as mtd_new_customers
FROM today_metrics tm
CROSS JOIN monthly_summary ms;
```

---

## Exercise 4.11: Moving Average Calculation
**Objective:** Calculate 7-day moving average for key metrics

```sql
-- Your query here

```

**Solution:**
```sql
SELECT 
    kd.kpi_name,
    dm.metric_date,
    dm.metric_value,
    AVG(dm.metric_value) OVER (
        PARTITION BY kd.kpi_id 
        ORDER BY dm.metric_date 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) as moving_avg_7day,
    kd.target_value
FROM kpi_definitions kd
JOIN daily_metrics dm ON kd.kpi_id = dm.kpi_id
WHERE kd.kpi_name IN ('Daily Revenue', 'Transactions Per Day', 'Customer Engagement Score')
  AND dm.metric_date >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY kd.kpi_name, dm.metric_date DESC;
```

---

## Exercise 4.12: Anomaly Detection
**Objective:** Identify unusual metric values

```sql
-- Your query here

```

**Solution:**
```sql
WITH metric_stats AS (
    SELECT 
        kpi_id,
        AVG(metric_value) as avg_value,
        STDDEV(metric_value) as stddev_value
    FROM daily_metrics
    WHERE metric_date >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY kpi_id
)
SELECT 
    kd.kpi_name,
    dm.metric_date,
    dm.metric_value,
    ms.avg_value,
    ms.stddev_value,
    (dm.metric_value - ms.avg_value) / NULLIF(ms.stddev_value, 0) as z_score,
    CASE 
        WHEN ABS((dm.metric_value - ms.avg_value) / NULLIF(ms.stddev_value, 0)) > 3 THEN 'EXTREME ANOMALY'
        WHEN ABS((dm.metric_value - ms.avg_value) / NULLIF(ms.stddev_value, 0)) > 2 THEN 'ANOMALY'
        ELSE 'NORMAL'
    END as anomaly_status
FROM kpi_definitions kd
JOIN daily_metrics dm ON kd.kpi_id = dm.kpi_id
JOIN metric_stats ms ON kd.kpi_id = ms.kpi_id
WHERE dm.metric_date >= CURRENT_DATE - INTERVAL '7 days'
  AND ABS((dm.metric_value - ms.avg_value) / NULLIF(ms.stddev_value, 0)) > 2
ORDER BY ABS((dm.metric_value - ms.avg_value) / NULLIF(ms.stddev_value, 0)) DESC;
```

---

## Challenge Exercises

### Challenge 4.1: Custom Dashboard Builder
Create a flexible query that can generate different dashboard views based on parameters (date range, KPI category, etc.)

### Challenge 4.2: Predictive Alerting
Build a query that predicts which KPIs are likely to miss targets based on current trends

### Challenge 4.3: Correlation Analysis
Identify correlations between different KPIs (e.g., does customer engagement correlate with revenue?)

---

## Next Steps
You've now mastered the core Data Analyst skills! Continue with:
- **Level 5:** Advanced Analytics (Window Functions, CTEs)
- **Level 6:** Fraud Detection (Advanced Pattern Recognition)
- Build your own custom dashboards and reports!

