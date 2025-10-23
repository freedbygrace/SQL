# Level 1: Basic SQL Queries

## Introduction
Welcome to the Financial Fraud Detection SQL learning path! In this first level, you'll learn the fundamentals of SQL by querying a realistic fraud detection database.

## Learning Objectives
- Understand SELECT statements
- Use WHERE clauses for filtering
- Sort results with ORDER BY
- Limit result sets
- Work with basic comparison operators

## Exercises

### Exercise 1.1: View All Customers
**Objective:** Retrieve all customer records

```sql
-- Your query here
SELECT * FROM customers;
```

**Expected Result:** All customer records with all columns

---

### Exercise 1.2: Find a Specific Customer
**Objective:** Find customer with customer_id = 1

```sql
-- Your query here
SELECT * FROM customers WHERE customer_id = 1;
```

---

### Exercise 1.3: High-Risk Customers
**Objective:** Find all customers with a risk_score greater than 80

```sql
-- Your query here

```

**Hint:** Use the WHERE clause with the > operator

**Solution:**
```sql
SELECT customer_id, first_name, last_name, email, risk_score
FROM customers
WHERE risk_score > 80
ORDER BY risk_score DESC;
```

---

### Exercise 1.4: Recent Registrations
**Objective:** Find customers who registered in 2024

```sql
-- Your query here

```

**Hint:** Use WHERE with date comparison

**Solution:**
```sql
SELECT customer_id, first_name, last_name, email, registration_date
FROM customers
WHERE registration_date >= '2024-01-01'
ORDER BY registration_date DESC;
```

---

### Exercise 1.5: Inactive Accounts
**Objective:** Find all inactive customer accounts

```sql
-- Your query here

```

**Solution:**
```sql
SELECT customer_id, first_name, last_name, email, is_active
FROM customers
WHERE is_active = FALSE;
```

---

### Exercise 1.6: Top 10 Largest Transactions
**Objective:** Find the 10 largest transactions by amount

```sql
-- Your query here

```

**Hint:** Use ORDER BY with LIMIT

**Solution:**
```sql
SELECT transaction_id, account_id, amount, transaction_date, description
FROM transactions
ORDER BY amount DESC
LIMIT 10;
```

---

### Exercise 1.7: Flagged Transactions
**Objective:** Find all transactions that have been flagged for review

```sql
-- Your query here

```

**Solution:**
```sql
SELECT transaction_id, account_id, amount, fraud_score, flagged_reason
FROM transactions
WHERE is_flagged = TRUE
ORDER BY fraud_score DESC;
```

---

### Exercise 1.8: International Transactions
**Objective:** Find all international transactions over $1,000

```sql
-- Your query here

```

**Solution:**
```sql
SELECT transaction_id, account_id, amount, country_id, city
FROM transactions
WHERE is_international = TRUE AND amount > 1000
ORDER BY amount DESC;
```

---

### Exercise 1.9: Specific Merchant Categories
**Objective:** Find all merchants in the 'Gambling' or 'Cryptocurrency' categories

```sql
-- Your query here

```

**Hint:** Join merchants with merchant_categories, use IN or OR

**Solution:**
```sql
SELECT m.merchant_id, m.merchant_name, mc.category_name, m.risk_rating
FROM merchants m
JOIN merchant_categories mc ON m.category_id = mc.category_id
WHERE mc.category_name IN ('Gambling', 'Cryptocurrency')
ORDER BY m.risk_rating DESC;
```

---

### Exercise 1.10: Critical Alerts
**Objective:** Find all open alerts with CRITICAL severity

```sql
-- Your query here

```

**Solution:**
```sql
SELECT alert_id, customer_id, alert_type, description, alert_date
FROM alerts
WHERE severity = 'CRITICAL' AND status = 'OPEN'
ORDER BY alert_date DESC;
```

---

## Challenge Exercises

### Challenge 1.1: PEP Customers
Find all Politically Exposed Persons (PEPs) with high risk scores (> 70)

### Challenge 1.2: Expired Cards
Find all cards that have expired (expiry_date < current_date)

### Challenge 1.3: Large Cash Advances
Find all cash advance transactions over $5,000

---

## Next Steps
Once you're comfortable with these basic queries, move on to:
- **Level 2:** JOIN operations
- **Level 3:** Aggregate functions and GROUP BY

