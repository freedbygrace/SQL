# Quick Start Guide

## 🚀 Get Up and Running in 5 Minutes

### Step 1: Start Docker Containers (1 minute)

```bash
# From the project root directory
docker-compose up -d
```

**What this does:**
- Starts PostgreSQL 16 database
- Starts DB-UI web interface
- Creates network and volumes

**Verify it's running:**
```bash
docker-compose ps
```

You should see both `fraud_detection_db` and `fraud_detection_ui` running.

---

### Step 2: Initialize Database Schema (1 minute)

```bash
# Make script executable (first time only)
chmod +x scripts/setup-database.sh

# Run setup
./scripts/setup-database.sh
```

**What this does:**
- Creates all 20+ tables
- Sets up indexes and constraints
- Loads reference data (countries, merchant categories, etc.)

**Expected output:**
```
✓ PostgreSQL is ready
✓ Creating tables, indexes, and constraints
✓ Loading reference data
✓ Database setup completed successfully!
```

---

### Step 3: Generate Test Data (15-30 minutes)

```bash
# Make script executable (first time only)
chmod +x data/generate_data.sh

# Run data generation
./data/generate_data.sh
```

**What this does:**
- Generates 100,000 customers
- Creates 150,000 accounts
- Generates 5,000,000 transactions
- Creates fraud patterns and alerts

**⏱️ Time estimate:**
- Fast machine (SSD, 16GB RAM): ~15 minutes
- Average machine: ~20-25 minutes
- Slower machine: ~30 minutes

**You can monitor progress:**
The script shows progress for each step:
```
[1/9] Loading geographic reference data...
[2/9] Generating Customers...
[3/9] Generating Accounts...
...
```

---

### Step 4: Access the Database

#### Option A: DB-UI Web Interface (Recommended for Beginners)

1. Open your browser to: **http://localhost:3000**
2. You'll see the database tables in the sidebar
3. Click any table to browse data
4. Use the "Custom SQL" tab to run queries

**Features:**
- Visual table browser
- SQL query editor with syntax highlighting
- Export results to CSV
- Schema introspection

#### Option B: Command Line (psql)

```bash
docker exec -it fraud_detection_db psql -U fraud_analyst -d fraud_detection
```

**Quick commands:**
```sql
-- List all tables
\dt

-- Describe a table
\d customers

-- Run a query
SELECT COUNT(*) FROM transactions;

-- Exit
\q
```

#### Option C: Your Favorite SQL Client

**Connection Details:**
```
Host:     localhost
Port:     5432
Database: fraud_detection
Username: fraud_analyst
Password: SecurePass123!
```

**Popular clients:**
- DBeaver (free, cross-platform)
- pgAdmin (free, PostgreSQL-specific)
- DataGrip (paid, JetBrains)
- TablePlus (paid, macOS/Windows)

---

## 🎓 Your First Queries

### 1. Check Data Counts

```sql
-- How many customers?
SELECT COUNT(*) FROM customers;

-- How many transactions?
SELECT COUNT(*) FROM transactions;

-- How many fraud alerts?
SELECT COUNT(*) FROM alerts WHERE status = 'OPEN';
```

### 2. Find High-Risk Customers

```sql
SELECT 
    customer_id,
    first_name,
    last_name,
    email,
    risk_score
FROM customers
WHERE risk_score > 80
ORDER BY risk_score DESC
LIMIT 10;
```

### 3. View Recent Transactions

```sql
SELECT 
    transaction_id,
    account_id,
    amount,
    transaction_date,
    is_flagged
FROM transactions
ORDER BY transaction_date DESC
LIMIT 20;
```

### 4. Find Flagged Transactions

```sql
SELECT 
    t.transaction_id,
    t.amount,
    t.fraud_score,
    t.flagged_reason,
    c.first_name,
    c.last_name
FROM transactions t
JOIN accounts a ON t.account_id = a.account_id
JOIN customers c ON a.customer_id = c.customer_id
WHERE t.is_flagged = TRUE
ORDER BY t.fraud_score DESC
LIMIT 10;
```

---

## 📚 Next Steps

### Start Learning SQL

1. **Begin with basics:** `exercises/01-basic-queries/README.md`
2. **Progress through levels:** Work through exercises 01-06
3. **Practice fraud detection:** `exercises/06-fraud-detection/README.md`

### Explore the Data

```sql
-- What countries are represented?
SELECT country_name, COUNT(*) as customer_count
FROM customers c
JOIN countries co ON c.country_id = co.country_id
GROUP BY country_name
ORDER BY customer_count DESC;

-- What are the top merchant categories?
SELECT mc.category_name, COUNT(*) as transaction_count
FROM transactions t
JOIN merchants m ON t.merchant_id = m.merchant_id
JOIN merchant_categories mc ON m.category_id = mc.category_id
GROUP BY mc.category_name
ORDER BY transaction_count DESC;

-- How many fraud cases by type?
SELECT ft.fraud_name, COUNT(*) as case_count
FROM fraud_cases fc
JOIN fraud_types ft ON fc.fraud_type_id = ft.fraud_type_id
GROUP BY ft.fraud_name
ORDER BY case_count DESC;
```

---

## 🔧 Troubleshooting

### Database won't start

```bash
# Check logs
docker-compose logs postgres

# Restart containers
docker-compose restart
```

### Can't connect to database

```bash
# Check if PostgreSQL is ready
docker exec fraud_detection_db pg_isready -U fraud_analyst

# Check port is not in use
netstat -an | grep 5432
```

### Data generation fails

```bash
# Check disk space
df -h

# Check memory
free -h

# Try with smaller dataset
# Edit data/generate_data.sh and reduce:
NUM_CUSTOMERS=10000
NUM_TRANSACTIONS=500000
```

### Reset everything

```bash
# Stop and remove everything
docker-compose down -v

# Start fresh
docker-compose up -d
./scripts/setup-database.sh
./data/generate_data.sh
```

---

## 💡 Tips

1. **Use DB-UI for exploration** - Great for browsing and understanding the schema
2. **Use psql for practice** - Best for learning SQL commands
3. **Start simple** - Begin with basic SELECT queries before complex joins
4. **Check the exercises** - They're designed to build your skills progressively
5. **Experiment** - The database is yours to explore and learn from!

---

## 🎯 Learning Goals

After completing this tutorial, you'll be able to:

- ✅ Write complex SQL queries
- ✅ Understand database relationships
- ✅ Detect fraud patterns in data
- ✅ Use window functions and CTEs
- ✅ Optimize queries with indexes
- ✅ Investigate financial crimes

---

**Ready to start? Head to `exercises/01-basic-queries/README.md`!** 🚀

