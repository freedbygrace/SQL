# Business Analytics Database - Data Models

## Overview
This database supports **Data Analyst** activities including:
- Routine and semi-routine analysis
- Dashboard creation and maintenance
- Business trend identification
- Statistical analysis and pattern recognition
- Stakeholder reporting

---

## Model 1: Customer Analytics (Routine Analysis)

### Purpose
Support customer segmentation, lifetime value analysis, churn prediction, and engagement tracking.

### Tables

#### `customer_segments`
Customer classification for targeted analysis
```sql
- segment_id (PK)
- segment_name (e.g., 'High Value', 'At Risk', 'New Customer')
- segment_description
- criteria_definition (JSON)
- created_date
- updated_date
```

#### `customer_lifetime_value`
CLV calculations for business insights
```sql
- clv_id (PK)
- customer_id (FK → customers)
- calculation_date
- total_revenue
- total_transactions
- average_order_value
- predicted_future_value
- clv_score
- segment_id (FK → customer_segments)
```

#### `churn_predictions`
Customer retention analysis
```sql
- prediction_id (PK)
- customer_id (FK → customers)
- prediction_date
- churn_probability (0-100)
- risk_level (LOW, MEDIUM, HIGH, CRITICAL)
- last_transaction_date
- days_since_last_transaction
- engagement_score
- recommended_action
```

#### `customer_satisfaction`
Satisfaction scores and feedback
```sql
- satisfaction_id (PK)
- customer_id (FK → customers)
- survey_date
- nps_score (-100 to 100)
- csat_score (1-5)
- feedback_text
- category (PRODUCT, SERVICE, SUPPORT, etc.)
- sentiment (POSITIVE, NEUTRAL, NEGATIVE)
```

#### `engagement_metrics`
Customer interaction tracking
```sql
- metric_id (PK)
- customer_id (FK → customers)
- metric_date
- login_count
- page_views
- time_spent_minutes
- features_used
- support_tickets_opened
- engagement_score
```

---

## Model 2: Sales & Revenue Analytics (Semi-Routine Reporting)

### Purpose
Support sales performance tracking, revenue forecasting, and product analysis.

### Tables

#### `product_catalog`
Product master data
```sql
- product_id (PK)
- product_name
- product_category
- product_subcategory
- unit_price
- cost_price
- margin_percentage
- is_active
- launch_date
- discontinued_date
```

#### `sales_transactions`
Detailed sales records (extends existing transactions)
```sql
- sale_id (PK)
- transaction_id (FK → transactions)
- product_id (FK → product_catalog)
- quantity
- unit_price
- discount_amount
- tax_amount
- total_amount
- sale_date
- sales_channel (ONLINE, STORE, PHONE, MOBILE_APP)
- sales_rep_id
- region
```

#### `sales_targets`
Performance goals for tracking
```sql
- target_id (PK)
- target_period (DAILY, WEEKLY, MONTHLY, QUARTERLY, YEARLY)
- start_date
- end_date
- product_category
- region
- target_revenue
- target_units
- target_customers
- created_by
```

#### `sales_performance`
Aggregated performance metrics
```sql
- performance_id (PK)
- period_date
- period_type (DAILY, WEEKLY, MONTHLY, QUARTERLY)
- product_id (FK → product_catalog)
- region
- total_revenue
- total_units_sold
- total_transactions
- unique_customers
- average_order_value
- vs_target_percentage
```

#### `revenue_forecasts`
Predictive revenue analysis
```sql
- forecast_id (PK)
- forecast_date
- forecast_period_start
- forecast_period_end
- product_category
- region
- forecasted_revenue
- confidence_level (LOW, MEDIUM, HIGH)
- forecast_method (HISTORICAL, TREND, SEASONAL, ML)
- actual_revenue (filled after period ends)
- variance_percentage
```

---

## Model 3: Operational Metrics & KPIs (Dashboard Creation)

### Purpose
Support dashboard creation with pre-calculated KPIs and trend analysis.

### Tables

#### `kpi_definitions`
Master list of tracked KPIs
```sql
- kpi_id (PK)
- kpi_name
- kpi_description
- kpi_category (SALES, CUSTOMER, OPERATIONAL, FINANCIAL)
- calculation_formula
- target_value
- threshold_warning
- threshold_critical
- unit_of_measure
- refresh_frequency (REALTIME, HOURLY, DAILY, WEEKLY)
- is_active
```

#### `daily_metrics`
Daily operational snapshots
```sql
- metric_id (PK)
- metric_date
- kpi_id (FK → kpi_definitions)
- metric_value
- vs_previous_day_percentage
- vs_previous_week_percentage
- vs_previous_month_percentage
- status (ON_TARGET, WARNING, CRITICAL)
- notes
```

#### `monthly_summaries`
Monthly aggregated data for reporting
```sql
- summary_id (PK)
- summary_month
- summary_year
- total_revenue
- total_transactions
- total_customers
- new_customers
- churned_customers
- average_transaction_value
- customer_acquisition_cost
- customer_lifetime_value
- net_promoter_score
- gross_margin_percentage
```

#### `trend_analysis`
Statistical trend tracking
```sql
- trend_id (PK)
- kpi_id (FK → kpi_definitions)
- analysis_date
- period_start
- period_end
- trend_direction (UP, DOWN, FLAT)
- trend_strength (WEAK, MODERATE, STRONG)
- moving_average_7day
- moving_average_30day
- seasonality_detected
- anomalies_detected
- statistical_significance
```

#### `dashboard_snapshots`
Pre-calculated dashboard data
```sql
- snapshot_id (PK)
- dashboard_name
- snapshot_timestamp
- data_payload (JSON)
- refresh_duration_seconds
- row_count
- last_updated_by
```

---

## Model 4: Business Intelligence & Reporting

### Purpose
Support ad-hoc analysis and standard report generation.

### Tables

#### `report_definitions`
Catalog of standard reports
```sql
- report_id (PK)
- report_name
- report_description
- report_category
- sql_query_template
- parameters (JSON)
- output_format (PDF, EXCEL, CSV, HTML)
- schedule_frequency
- recipients
- is_active
```

#### `report_executions`
Report run history
```sql
- execution_id (PK)
- report_id (FK → report_definitions)
- execution_timestamp
- parameters_used (JSON)
- row_count
- execution_duration_seconds
- status (SUCCESS, FAILED, TIMEOUT)
- error_message
- output_file_path
- executed_by
```

#### `data_quality_checks`
Data validation tracking
```sql
- check_id (PK)
- check_name
- table_name
- column_name
- check_type (NULL_CHECK, RANGE_CHECK, UNIQUENESS, REFERENTIAL_INTEGRITY)
- check_date
- records_checked
- records_failed
- failure_percentage
- status (PASS, FAIL, WARNING)
- remediation_notes
```

---

## Relationships to Existing Models

### Integration Points

1. **Customer Analytics** ← links to existing `customers` table
2. **Sales Transactions** ← extends existing `transactions` table
3. **Engagement Metrics** ← links to `login_sessions` and `transactions`
4. **Churn Predictions** ← analyzes `transactions` and `accounts`
5. **KPIs** ← aggregates from multiple existing tables

---

## Use Cases for Data Analyst Role

### Routine Analysis
- Daily sales reports
- Customer segment updates
- KPI dashboard refreshes
- Data quality checks

### Semi-Routine Analysis
- Monthly trend analysis
- Churn prediction updates
- Revenue forecasting
- Performance vs. targets

### Ad-Hoc Analysis
- Customer cohort analysis
- Product performance deep-dives
- Seasonal pattern identification
- Anomaly investigation

---

## Next Steps

1. ✅ Design complete
2. ⏳ Implement schema in `schema/01-create-tables.sql`
3. ⏳ Update data generation scripts
4. ⏳ Create SQL exercises for each model
5. ⏳ Update documentation

