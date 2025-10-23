# Level 2: Customer Analytics

## Introduction
Learn to analyze customer behavior, calculate lifetime value, identify churn risks, and segment customers - essential skills for Data Analysts working with customer data.

## Learning Objectives
- Calculate customer lifetime value (CLV)
- Identify at-risk customers
- Segment customers by behavior
- Analyze satisfaction trends
- Track engagement metrics

---

## Exercise 2.1: Customer Segmentation
**Objective:** Find the distribution of customers across segments

```sql
SELECT 
    cs.segment_name,
    COUNT(clv.customer_id) as customer_count,
    AVG(clv.clv_score) as avg_clv_score,
    SUM(clv.total_revenue) as total_segment_revenue
FROM customer_segments cs
LEFT JOIN customer_lifetime_value clv ON cs.segment_id = clv.segment_id
GROUP BY cs.segment_id, cs.segment_name
ORDER BY total_segment_revenue DESC;
```

**Expected Result:** Segment breakdown with counts and revenue

---

## Exercise 2.2: High-Value Customers
**Objective:** Identify top 10 customers by lifetime value

```sql
-- Your query here

```

**Hint:** Use customer_lifetime_value table and ORDER BY

**Solution:**
```sql
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    clv.total_revenue,
    clv.total_transactions,
    clv.clv_score,
    cs.segment_name
FROM customer_lifetime_value clv
JOIN customers c ON clv.customer_id = c.customer_id
JOIN customer_segments cs ON clv.segment_id = cs.segment_id
ORDER BY clv.clv_score DESC
LIMIT 10;
```

---

## Exercise 2.3: Churn Risk Analysis
**Objective:** Find customers at CRITICAL or HIGH churn risk

```sql
-- Your query here

```

**Solution:**
```sql
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    cp.churn_probability,
    cp.risk_level,
    cp.days_since_last_transaction,
    cp.engagement_score
FROM churn_predictions cp
JOIN customers c ON cp.customer_id = c.customer_id
WHERE cp.risk_level IN ('CRITICAL', 'HIGH')
ORDER BY cp.churn_probability DESC;
```

---

## Exercise 2.4: Customer Satisfaction Trends
**Objective:** Calculate average NPS score by month

```sql
-- Your query here

```

**Hint:** Use DATE_TRUNC or EXTRACT to group by month

**Solution:**
```sql
SELECT 
    DATE_TRUNC('month', survey_date) as month,
    COUNT(*) as survey_count,
    AVG(nps_score) as avg_nps,
    AVG(csat_score) as avg_csat,
    COUNT(CASE WHEN sentiment = 'POSITIVE' THEN 1 END) as positive_count,
    COUNT(CASE WHEN sentiment = 'NEGATIVE' THEN 1 END) as negative_count
FROM customer_satisfaction
GROUP BY DATE_TRUNC('month', survey_date)
ORDER BY month DESC;
```

---

## Exercise 2.5: Engagement Score Analysis
**Objective:** Find customers with declining engagement

```sql
-- Your query here

```

**Hint:** Compare recent engagement to historical average

**Solution:**
```sql
WITH recent_engagement AS (
    SELECT 
        customer_id,
        AVG(engagement_score) as recent_score
    FROM engagement_metrics
    WHERE metric_date >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY customer_id
),
historical_engagement AS (
    SELECT 
        customer_id,
        AVG(engagement_score) as historical_score
    FROM engagement_metrics
    WHERE metric_date < CURRENT_DATE - INTERVAL '30 days'
    GROUP BY customer_id
)
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    re.recent_score,
    he.historical_score,
    (re.recent_score - he.historical_score) as score_change
FROM customers c
JOIN recent_engagement re ON c.customer_id = re.customer_id
JOIN historical_engagement he ON c.customer_id = he.customer_id
WHERE re.recent_score < he.historical_score
ORDER BY score_change ASC
LIMIT 20;
```

---

## Exercise 2.6: Customer Cohort Analysis
**Objective:** Analyze customer retention by registration cohort

```sql
-- Your query here

```

**Solution:**
```sql
SELECT 
    DATE_TRUNC('month', c.registration_date) as cohort_month,
    COUNT(DISTINCT c.customer_id) as total_customers,
    COUNT(DISTINCT CASE WHEN cp.risk_level = 'LOW' THEN c.customer_id END) as active_customers,
    COUNT(DISTINCT CASE WHEN cp.risk_level IN ('HIGH', 'CRITICAL') THEN c.customer_id END) as at_risk_customers,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN cp.risk_level = 'LOW' THEN c.customer_id END) / 
          COUNT(DISTINCT c.customer_id), 2) as retention_rate
FROM customers c
LEFT JOIN churn_predictions cp ON c.customer_id = cp.customer_id
WHERE c.registration_date >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY DATE_TRUNC('month', c.registration_date)
ORDER BY cohort_month DESC;
```

---

## Exercise 2.7: Customer Lifetime Value by Segment
**Objective:** Compare CLV metrics across customer segments

```sql
-- Your query here

```

**Solution:**
```sql
SELECT 
    cs.segment_name,
    COUNT(clv.customer_id) as customer_count,
    MIN(clv.clv_score) as min_clv,
    AVG(clv.clv_score) as avg_clv,
    MAX(clv.clv_score) as max_clv,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY clv.clv_score) as median_clv,
    SUM(clv.total_revenue) as total_revenue,
    AVG(clv.total_transactions) as avg_transactions
FROM customer_segments cs
JOIN customer_lifetime_value clv ON cs.segment_id = clv.segment_id
GROUP BY cs.segment_id, cs.segment_name
ORDER BY avg_clv DESC;
```

---

## Exercise 2.8: Satisfaction by Category
**Objective:** Analyze satisfaction scores by feedback category

```sql
-- Your query here

```

**Solution:**
```sql
SELECT 
    category,
    COUNT(*) as feedback_count,
    AVG(nps_score) as avg_nps,
    AVG(csat_score) as avg_csat,
    ROUND(100.0 * COUNT(CASE WHEN sentiment = 'POSITIVE' THEN 1 END) / COUNT(*), 2) as positive_pct,
    ROUND(100.0 * COUNT(CASE WHEN sentiment = 'NEGATIVE' THEN 1 END) / COUNT(*), 2) as negative_pct
FROM customer_satisfaction
GROUP BY category
ORDER BY avg_nps DESC;
```

---

## Exercise 2.9: Customer Engagement Patterns
**Objective:** Find most engaged customers in the last 30 days

```sql
-- Your query here

```

**Solution:**
```sql
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    SUM(em.login_count) as total_logins,
    SUM(em.page_views) as total_page_views,
    SUM(em.time_spent_minutes) as total_time_spent,
    AVG(em.engagement_score) as avg_engagement_score
FROM customers c
JOIN engagement_metrics em ON c.customer_id = em.customer_id
WHERE em.metric_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING AVG(em.engagement_score) > 75
ORDER BY avg_engagement_score DESC
LIMIT 20;
```

---

## Exercise 2.10: Churn Prevention Priority List
**Objective:** Create a priority list for customer retention efforts

```sql
-- Your query here

```

**Hint:** Combine churn risk with customer value

**Solution:**
```sql
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    clv.clv_score,
    clv.total_revenue,
    cp.churn_probability,
    cp.risk_level,
    cp.days_since_last_transaction,
    (clv.clv_score * cp.churn_probability / 100) as retention_priority_score
FROM customers c
JOIN customer_lifetime_value clv ON c.customer_id = clv.customer_id
JOIN churn_predictions cp ON c.customer_id = cp.customer_id
WHERE cp.risk_level IN ('HIGH', 'CRITICAL')
  AND clv.clv_score > 1000
ORDER BY retention_priority_score DESC
LIMIT 50;
```

---

## Challenge Exercises

### Challenge 2.1: Customer Journey Analysis
Create a query that shows the customer journey from registration to current status, including:
- Registration date
- First transaction date
- Total transactions
- Current segment
- Churn risk
- Latest satisfaction score

### Challenge 2.2: Segment Migration Analysis
Identify customers who have moved between segments over time (requires historical CLV data)

### Challenge 2.3: Engagement Correlation
Analyze the correlation between engagement scores and satisfaction scores

---

## Next Steps
Once you're comfortable with customer analytics, move on to:
- **Level 3:** Sales & Revenue Analysis
- **Level 4:** KPI Dashboards & Metrics

