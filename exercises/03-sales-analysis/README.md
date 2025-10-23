# Level 3: Sales & Revenue Analysis

## Introduction
Master sales performance analysis, product analytics, and revenue forecasting - core responsibilities for Data Analysts in sales-driven organizations.

## Learning Objectives
- Analyze sales performance vs targets
- Identify top-performing products
- Compare sales across channels and regions
- Calculate revenue metrics
- Analyze sales trends

---

## Exercise 3.1: Daily Sales Summary
**Objective:** Get today's sales summary

```sql
SELECT 
    COUNT(*) as total_sales,
    SUM(total_amount) as total_revenue,
    AVG(total_amount) as avg_sale_value,
    SUM(quantity) as total_units_sold,
    COUNT(DISTINCT product_id) as products_sold
FROM sales_transactions
WHERE DATE(sale_date) = CURRENT_DATE;
```

**Expected Result:** Summary of today's sales activity

---

## Exercise 3.2: Top Products by Revenue
**Objective:** Find the top 10 products by total revenue

```sql
-- Your query here

```

**Solution:**
```sql
SELECT 
    p.product_id,
    p.product_name,
    p.product_category,
    p.product_subcategory,
    COUNT(st.transaction_id) as sales_count,
    SUM(st.quantity) as units_sold,
    SUM(st.total_amount) as total_revenue,
    AVG(st.total_amount) as avg_sale_value
FROM product_catalog p
JOIN sales_transactions st ON p.product_id = st.product_id
GROUP BY p.product_id, p.product_name, p.product_category, p.product_subcategory
ORDER BY total_revenue DESC
LIMIT 10;
```

---

## Exercise 3.3: Sales by Channel
**Objective:** Compare sales performance across different channels

```sql
-- Your query here

```

**Solution:**
```sql
SELECT 
    sales_channel,
    COUNT(*) as transaction_count,
    SUM(total_amount) as total_revenue,
    AVG(total_amount) as avg_transaction_value,
    SUM(quantity) as total_units,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) as pct_of_total_transactions
FROM sales_transactions
GROUP BY sales_channel
ORDER BY total_revenue DESC;
```

---

## Exercise 3.4: Regional Performance
**Objective:** Analyze sales by region

```sql
-- Your query here

```

**Solution:**
```sql
SELECT 
    region,
    COUNT(*) as sales_count,
    SUM(total_amount) as total_revenue,
    AVG(total_amount) as avg_sale,
    SUM(discount_amount) as total_discounts,
    ROUND(100.0 * SUM(discount_amount) / SUM(total_amount), 2) as discount_rate
FROM sales_transactions
GROUP BY region
ORDER BY total_revenue DESC;
```

---

## Exercise 3.5: Product Category Analysis
**Objective:** Compare performance across product categories

```sql
-- Your query here

```

**Solution:**
```sql
SELECT 
    p.product_category,
    COUNT(DISTINCT p.product_id) as product_count,
    COUNT(st.transaction_id) as sales_count,
    SUM(st.total_amount) as total_revenue,
    AVG(st.total_amount) as avg_sale_value,
    SUM(st.quantity) as units_sold,
    AVG(p.margin_percentage) as avg_margin
FROM product_catalog p
LEFT JOIN sales_transactions st ON p.product_id = st.product_id
GROUP BY p.product_category
ORDER BY total_revenue DESC;
```

---

## Exercise 3.6: Monthly Sales Trend
**Objective:** Show sales trends over the past 12 months

```sql
-- Your query here

```

**Solution:**
```sql
SELECT 
    DATE_TRUNC('month', sale_date) as month,
    COUNT(*) as transaction_count,
    SUM(total_amount) as total_revenue,
    AVG(total_amount) as avg_transaction_value,
    SUM(quantity) as units_sold
FROM sales_transactions
WHERE sale_date >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY DATE_TRUNC('month', sale_date)
ORDER BY month DESC;
```

---

## Exercise 3.7: Sales Performance vs Target
**Objective:** Compare actual sales to targets

```sql
-- Your query here

```

**Solution:**
```sql
SELECT 
    st.target_period,
    st.target_category,
    st.target_value,
    COALESCE(sp.actual_value, 0) as actual_value,
    COALESCE(sp.actual_value, 0) - st.target_value as variance,
    ROUND(100.0 * COALESCE(sp.actual_value, 0) / st.target_value, 2) as achievement_pct,
    CASE 
        WHEN COALESCE(sp.actual_value, 0) >= st.target_value THEN 'MET'
        WHEN COALESCE(sp.actual_value, 0) >= st.target_value * 0.9 THEN 'NEAR'
        ELSE 'MISSED'
    END as status
FROM sales_targets st
LEFT JOIN sales_performance sp ON st.target_id = sp.target_id
WHERE st.target_period >= CURRENT_DATE - INTERVAL '6 months'
ORDER BY st.target_period DESC, st.target_category;
```

---

## Exercise 3.8: Product Profitability
**Objective:** Calculate profit margins by product

```sql
-- Your query here

```

**Solution:**
```sql
SELECT 
    p.product_id,
    p.product_name,
    p.product_category,
    p.unit_price,
    p.cost_price,
    p.margin_percentage,
    COUNT(st.transaction_id) as sales_count,
    SUM(st.quantity) as units_sold,
    SUM(st.total_amount) as total_revenue,
    SUM(st.quantity * p.cost_price) as total_cost,
    SUM(st.total_amount) - SUM(st.quantity * p.cost_price) as gross_profit
FROM product_catalog p
JOIN sales_transactions st ON p.product_id = st.product_id
GROUP BY p.product_id, p.product_name, p.product_category, p.unit_price, p.cost_price, p.margin_percentage
HAVING SUM(st.total_amount) > 0
ORDER BY gross_profit DESC
LIMIT 20;
```

---

## Exercise 3.9: Revenue Forecast Accuracy
**Objective:** Compare forecasted revenue to actual revenue

```sql
-- Your query here

```

**Solution:**
```sql
SELECT 
    rf.forecast_period,
    rf.forecast_category,
    rf.forecasted_revenue,
    rf.confidence_level,
    ms.total_revenue as actual_revenue,
    (ms.total_revenue - rf.forecasted_revenue) as variance,
    ROUND(100.0 * ABS(ms.total_revenue - rf.forecasted_revenue) / rf.forecasted_revenue, 2) as error_pct
FROM revenue_forecasts rf
JOIN monthly_summaries ms ON 
    EXTRACT(MONTH FROM rf.forecast_period) = ms.summary_month AND
    EXTRACT(YEAR FROM rf.forecast_period) = ms.summary_year
WHERE rf.forecast_period >= CURRENT_DATE - INTERVAL '12 months'
ORDER BY rf.forecast_period DESC;
```

---

## Exercise 3.10: Sales Velocity Analysis
**Objective:** Identify fast-moving vs slow-moving products

```sql
-- Your query here

```

**Solution:**
```sql
WITH product_sales AS (
    SELECT 
        p.product_id,
        p.product_name,
        p.product_category,
        COUNT(st.transaction_id) as sales_count,
        SUM(st.quantity) as units_sold,
        MIN(st.sale_date) as first_sale,
        MAX(st.sale_date) as last_sale,
        EXTRACT(DAY FROM MAX(st.sale_date) - MIN(st.sale_date)) as days_on_market
    FROM product_catalog p
    LEFT JOIN sales_transactions st ON p.product_id = st.product_id
    WHERE p.is_active = TRUE
    GROUP BY p.product_id, p.product_name, p.product_category
)
SELECT 
    product_id,
    product_name,
    product_category,
    sales_count,
    units_sold,
    days_on_market,
    CASE 
        WHEN days_on_market > 0 THEN ROUND(units_sold::DECIMAL / days_on_market, 2)
        ELSE 0
    END as units_per_day,
    CASE 
        WHEN days_on_market > 0 AND (units_sold::DECIMAL / days_on_market) > 10 THEN 'FAST'
        WHEN days_on_market > 0 AND (units_sold::DECIMAL / days_on_market) > 5 THEN 'MEDIUM'
        WHEN days_on_market > 0 THEN 'SLOW'
        ELSE 'NO_SALES'
    END as velocity_category
FROM product_sales
ORDER BY units_per_day DESC;
```

---

## Exercise 3.11: Discount Impact Analysis
**Objective:** Analyze the impact of discounts on sales

```sql
-- Your query here

```

**Solution:**
```sql
SELECT 
    CASE 
        WHEN discount_amount = 0 THEN 'No Discount'
        WHEN discount_amount / total_amount < 0.1 THEN '< 10%'
        WHEN discount_amount / total_amount < 0.2 THEN '10-20%'
        WHEN discount_amount / total_amount < 0.3 THEN '20-30%'
        ELSE '> 30%'
    END as discount_tier,
    COUNT(*) as transaction_count,
    AVG(total_amount) as avg_sale_value,
    SUM(total_amount) as total_revenue,
    SUM(discount_amount) as total_discounts,
    AVG(quantity) as avg_quantity
FROM sales_transactions
GROUP BY discount_tier
ORDER BY 
    CASE discount_tier
        WHEN 'No Discount' THEN 1
        WHEN '< 10%' THEN 2
        WHEN '10-20%' THEN 3
        WHEN '20-30%' THEN 4
        ELSE 5
    END;
```

---

## Exercise 3.12: Cross-Sell Opportunities
**Objective:** Find products frequently purchased together

```sql
-- Your query here

```

**Hint:** Use self-join on transaction_id

**Solution:**
```sql
SELECT 
    p1.product_name as product_1,
    p2.product_name as product_2,
    COUNT(*) as times_purchased_together
FROM sales_transactions st1
JOIN sales_transactions st2 ON st1.transaction_id = st2.transaction_id
    AND st1.product_id < st2.product_id
JOIN product_catalog p1 ON st1.product_id = p1.product_id
JOIN product_catalog p2 ON st2.product_id = p2.product_id
GROUP BY p1.product_id, p1.product_name, p2.product_id, p2.product_name
HAVING COUNT(*) > 10
ORDER BY times_purchased_together DESC
LIMIT 20;
```

---

## Challenge Exercises

### Challenge 3.1: Sales Seasonality
Identify seasonal patterns in sales data by analyzing month-over-month and year-over-year trends

### Challenge 3.2: Customer Purchase Patterns
Analyze average time between purchases and identify customers with regular buying patterns

### Challenge 3.3: Product Launch Performance
Compare new product performance (launched in last 6 months) vs established products

---

## Next Steps
Once you're comfortable with sales analysis, move on to:
- **Level 4:** KPI Dashboards & Metrics
- **Level 6:** Fraud Detection (Advanced)

