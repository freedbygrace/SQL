# Level 6: Fraud Detection Scenarios

## Introduction
Now you'll apply your SQL skills to real-world fraud detection scenarios. These exercises simulate actual fraud investigation tasks.

## Learning Objectives
- Detect velocity fraud patterns
- Identify geographic anomalies
- Find money mule networks
- Detect account takeover attempts
- Identify structuring patterns

---

## Fraud Pattern Detection

### Scenario 1: Velocity Fraud Detection
**Objective:** Find accounts with more than 5 transactions in a 1-hour window

```sql
-- Detect rapid-fire transactions (velocity check)
WITH transaction_windows AS (
    SELECT 
        t1.account_id,
        t1.transaction_id,
        t1.transaction_date,
        t1.amount,
        COUNT(t2.transaction_id) as transactions_in_hour
    FROM transactions t1
    JOIN transactions t2 ON t1.account_id = t2.account_id
        AND t2.transaction_date BETWEEN t1.transaction_date - INTERVAL '1 hour' 
        AND t1.transaction_date
    GROUP BY t1.account_id, t1.transaction_id, t1.transaction_date, t1.amount
)
SELECT 
    account_id,
    transaction_date,
    transactions_in_hour,
    SUM(amount) as total_amount
FROM transaction_windows
WHERE transactions_in_hour > 5
GROUP BY account_id, transaction_date, transactions_in_hour
ORDER BY transactions_in_hour DESC;
```

---

### Scenario 2: Geographic Impossibility
**Objective:** Find transactions from the same card in different countries within 2 hours

```sql
-- Detect impossible travel (card used in different countries too quickly)
SELECT 
    t1.card_id,
    t1.transaction_id as trans1_id,
    t1.transaction_date as trans1_date,
    c1.country_name as country1,
    t1.city as city1,
    t2.transaction_id as trans2_id,
    t2.transaction_date as trans2_date,
    c2.country_name as country2,
    t2.city as city2,
    EXTRACT(EPOCH FROM (t2.transaction_date - t1.transaction_date))/3600 as hours_between
FROM transactions t1
JOIN transactions t2 ON t1.card_id = t2.card_id
    AND t2.transaction_date > t1.transaction_date
    AND t2.transaction_date <= t1.transaction_date + INTERVAL '2 hours'
JOIN countries c1 ON t1.country_id = c1.country_id
JOIN countries c2 ON t2.country_id = c2.country_id
WHERE t1.country_id != t2.country_id
ORDER BY hours_between ASC;
```

---

### Scenario 3: Money Mule Network Detection
**Objective:** Find clusters of accounts that transfer money in a chain pattern

```sql
-- Detect potential money mule networks (rapid transfer chains)
WITH transfer_chains AS (
    SELECT 
        tr1.from_account_id as account1,
        tr1.to_account_id as account2,
        tr2.to_account_id as account3,
        tr1.transfer_id as transfer1,
        tr2.transfer_id as transfer2,
        t1.amount as amount1,
        t2.amount as amount2,
        t1.transaction_date as date1,
        t2.transaction_date as date2,
        EXTRACT(EPOCH FROM (t2.transaction_date - t1.transaction_date))/3600 as hours_between
    FROM transfers tr1
    JOIN transfers tr2 ON tr1.to_account_id = tr2.from_account_id
    JOIN transactions t1 ON tr1.transaction_id = t1.transaction_id
    JOIN transactions t2 ON tr2.transaction_id = t2.transaction_id
    WHERE t2.transaction_date BETWEEN t1.transaction_date AND t1.transaction_date + INTERVAL '24 hours'
)
SELECT 
    account1,
    account2,
    account3,
    amount1,
    amount2,
    hours_between,
    CASE 
        WHEN ABS(amount1 - amount2) / amount1 < 0.1 THEN 'SUSPICIOUS - Similar amounts'
        ELSE 'Review'
    END as risk_flag
FROM transfer_chains
WHERE hours_between < 24
ORDER BY hours_between ASC;
```

---

### Scenario 4: Account Takeover Detection
**Objective:** Find accounts with sudden changes in transaction patterns

```sql
-- Detect account takeover by analyzing behavior changes
WITH customer_baseline AS (
    SELECT 
        a.customer_id,
        a.account_id,
        AVG(t.amount) as avg_transaction,
        STDDEV(t.amount) as stddev_transaction,
        COUNT(*) as transaction_count
    FROM accounts a
    JOIN transactions t ON a.account_id = t.account_id
    WHERE t.transaction_date < CURRENT_DATE - INTERVAL '30 days'
    GROUP BY a.customer_id, a.account_id
),
recent_transactions AS (
    SELECT 
        a.customer_id,
        a.account_id,
        t.transaction_id,
        t.amount,
        t.transaction_date,
        t.country_id,
        t.device_id
    FROM accounts a
    JOIN transactions t ON a.account_id = t.account_id
    WHERE t.transaction_date >= CURRENT_DATE - INTERVAL '7 days'
)
SELECT 
    rt.customer_id,
    rt.account_id,
    rt.transaction_id,
    rt.amount,
    cb.avg_transaction,
    (rt.amount - cb.avg_transaction) / NULLIF(cb.stddev_transaction, 0) as z_score,
    CASE 
        WHEN ABS((rt.amount - cb.avg_transaction) / NULLIF(cb.stddev_transaction, 0)) > 3 
        THEN 'HIGH RISK - Amount anomaly'
        WHEN ABS((rt.amount - cb.avg_transaction) / NULLIF(cb.stddev_transaction, 0)) > 2 
        THEN 'MEDIUM RISK'
        ELSE 'Normal'
    END as risk_level
FROM recent_transactions rt
JOIN customer_baseline cb ON rt.account_id = cb.account_id
WHERE cb.transaction_count > 10
ORDER BY ABS((rt.amount - cb.avg_transaction) / NULLIF(cb.stddev_transaction, 0)) DESC;
```

---

### Scenario 5: Structuring Detection (Smurfing)
**Objective:** Find patterns of transactions just under $10,000 (reporting threshold)

```sql
-- Detect structuring - multiple transactions just under reporting threshold
WITH daily_transactions AS (
    SELECT 
        account_id,
        DATE(transaction_date) as transaction_day,
        COUNT(*) as num_transactions,
        SUM(amount) as total_amount,
        AVG(amount) as avg_amount,
        MAX(amount) as max_amount
    FROM transactions
    WHERE amount BETWEEN 9000 AND 9999
        AND transaction_date >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY account_id, DATE(transaction_date)
)
SELECT 
    dt.account_id,
    c.first_name,
    c.last_name,
    dt.transaction_day,
    dt.num_transactions,
    dt.total_amount,
    dt.avg_amount,
    CASE 
        WHEN dt.num_transactions >= 3 AND dt.total_amount > 25000 
        THEN 'CRITICAL - Likely structuring'
        WHEN dt.num_transactions >= 2 AND dt.total_amount > 18000 
        THEN 'HIGH - Possible structuring'
        ELSE 'Review'
    END as risk_assessment
FROM daily_transactions dt
JOIN accounts a ON dt.account_id = a.account_id
JOIN customers c ON a.customer_id = c.customer_id
WHERE dt.num_transactions >= 2
ORDER BY dt.total_amount DESC, dt.num_transactions DESC;
```

---

### Scenario 6: High-Risk Merchant Analysis
**Objective:** Find customers with unusual activity at high-risk merchants

```sql
-- Analyze transactions at high-risk merchants
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    c.risk_score as customer_risk,
    mc.category_name,
    m.merchant_name,
    m.risk_rating as merchant_risk,
    COUNT(t.transaction_id) as transaction_count,
    SUM(t.amount) as total_spent,
    AVG(t.amount) as avg_transaction,
    MAX(t.amount) as max_transaction
FROM customers c
JOIN accounts a ON c.customer_id = a.customer_id
JOIN transactions t ON a.account_id = t.account_id
JOIN merchants m ON t.merchant_id = m.merchant_id
JOIN merchant_categories mc ON m.category_id = mc.category_id
WHERE m.risk_rating IN ('HIGH', 'CRITICAL')
    AND t.transaction_date >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY c.customer_id, c.first_name, c.last_name, c.risk_score, 
         mc.category_name, m.merchant_name, m.risk_rating
HAVING COUNT(t.transaction_id) > 5 OR SUM(t.amount) > 10000
ORDER BY total_spent DESC;
```

---

### Scenario 7: Card Testing Detection
**Objective:** Find cards with multiple small failed transactions (testing stolen cards)

```sql
-- Detect card testing patterns
SELECT 
    t.card_id,
    c.card_last_four,
    COUNT(*) as failed_attempts,
    COUNT(DISTINCT t.merchant_id) as different_merchants,
    MIN(t.amount) as min_amount,
    MAX(t.amount) as max_amount,
    MIN(t.transaction_date) as first_attempt,
    MAX(t.transaction_date) as last_attempt,
    EXTRACT(EPOCH FROM (MAX(t.transaction_date) - MIN(t.transaction_date)))/60 as minutes_span
FROM transactions t
JOIN cards c ON t.card_id = c.card_id
WHERE t.status = 'FAILED'
    AND t.amount < 10
    AND t.transaction_date >= CURRENT_DATE - INTERVAL '24 hours'
GROUP BY t.card_id, c.card_last_four
HAVING COUNT(*) >= 3
ORDER BY failed_attempts DESC, minutes_span ASC;
```

---

### Scenario 8: Dormant Account Reactivation
**Objective:** Find dormant accounts that suddenly become active (potential takeover)

```sql
-- Detect dormant account reactivation
WITH account_activity AS (
    SELECT 
        account_id,
        MIN(transaction_date) as first_transaction,
        MAX(transaction_date) as last_transaction,
        COUNT(*) as total_transactions
    FROM transactions
    GROUP BY account_id
),
dormant_accounts AS (
    SELECT 
        account_id,
        last_transaction,
        total_transactions
    FROM account_activity
    WHERE last_transaction < CURRENT_DATE - INTERVAL '180 days'
),
recent_activity AS (
    SELECT 
        t.account_id,
        COUNT(*) as recent_transactions,
        SUM(t.amount) as recent_amount,
        MIN(t.transaction_date) as reactivation_date
    FROM transactions t
    WHERE t.transaction_date >= CURRENT_DATE - INTERVAL '7 days'
    GROUP BY t.account_id
)
SELECT 
    da.account_id,
    c.first_name,
    c.last_name,
    c.email,
    da.last_transaction as last_active,
    EXTRACT(DAY FROM (CURRENT_DATE - da.last_transaction)) as days_dormant,
    ra.reactivation_date,
    ra.recent_transactions,
    ra.recent_amount,
    'CRITICAL - Dormant account reactivated' as alert_type
FROM dormant_accounts da
JOIN recent_activity ra ON da.account_id = ra.account_id
JOIN accounts a ON da.account_id = a.account_id
JOIN customers c ON a.customer_id = c.customer_id
ORDER BY days_dormant DESC;
```

---

## Investigation Exercises

### Exercise 6.1: Full Customer Investigation
Create a comprehensive report for a suspicious customer including:
- All accounts
- All transactions
- All alerts
- All fraud cases
- Related customers (via relationships)

### Exercise 6.2: Fraud Case Summary
Generate a summary report of all open fraud cases with:
- Case details
- Associated transactions
- Total amount at risk
- Investigation status

### Exercise 6.3: Daily Fraud Dashboard
Create a daily dashboard showing:
- New alerts by severity
- High-risk transactions
- Geographic anomalies
- Velocity violations

---

## Next Steps
Congratulations! You've completed the fraud detection scenarios. You now have the skills to:
- Detect complex fraud patterns
- Investigate suspicious activity
- Generate fraud reports
- Analyze customer behavior

Continue practicing with real data and explore advanced topics like:
- Machine learning integration
- Real-time fraud scoring
- Network analysis
- Predictive modeling

