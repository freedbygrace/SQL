# Quick Start Guide

## 🚀 Get Up and Running in 5 Minutes

### Step 0: Set Proper Permissions

**Option A: Automated (Recommended)**
```bash
# Use the fix-permissions script
chmod +x scripts/fix-permissions.sh
./scripts/fix-permissions.sh
```

**Option B: Manual**
```bash
# Take ownership of the cloned repository
sudo chown -R $USER:$USER .

# Make all .sh files executable recursively
find . -name "*.sh" -exec chmod +x {} \;

# Set proper permissions for directories
chmod -R 755 data/ schema/ scripts/ docker/
```

**Why this is important:**
- **Ownership:** Ensures your user owns all files (prevents permission denied errors)
- **Executable scripts:** Makes all shell scripts runnable
- **Directory permissions:** Allows Docker to read/write bind-mounted directories
- **Prevents errors:** Avoids "permission denied" issues with Docker volumes

**What the script does:**
1. ✅ Takes ownership of all repository files
2. ✅ Makes all `.sh` files executable (found 6 scripts)
3. ✅ Sets proper permissions for data/, schema/, scripts/, docker/, exercises/, docs/
4. ✅ Verifies permissions are correct

### Step 1: Install Dependencies (Optional - 5 minutes)

**If you don't have Docker, PostgreSQL client (psql), or other required tools:**

```bash
# Run the installer
./scripts/install-dependencies.sh
```

**What this installs:**
- PostgreSQL client (psql)
- Docker & Docker Compose
- Utility packages (curl, wget, git)

**Supported OS:** Ubuntu, Debian, CentOS, RHEL, Fedora, Arch Linux, macOS

**Note:** All other scripts will automatically check for dependencies and prompt you to install them if missing.

---

### Step 2: Start Docker Containers (1 minute)

```bash
# From the project root directory
docker-compose up -d
```

**What this does:**
- Starts PostgreSQL 16 database
- Starts pgAdmin 4 web interface
- Creates network and volumes

**Verify it's running:**
```bash
docker-compose ps
```

You should see both `business_analytics_db` and `business_analytics_ui` running.

---

### Step 3: Initialize Database Schema (1 minute)

```bash
# Run setup
./scripts/setup-database.sh
```

**What this does:**
- Creates all 39 tables across 4 business models
- Sets up indexes and constraints
- Loads reference data (countries, merchant categories, customer segments, products, KPIs, etc.)

**Expected output:**
```
✓ PostgreSQL is ready
✓ Creating tables, indexes, and constraints
✓ Loading reference data
✓ Database setup completed successfully!
```

---

### Step 4: Generate Test Data (15-30 minutes)

```bash
# Run data generation
./data/generate_data.sh
```

**What this does:**
- Generates 100,000 customers
- Creates 150,000 accounts
- Generates 5,000,000 transactions
- Creates fraud patterns and alerts
- Generates customer analytics (CLV, churn, satisfaction)
- Creates sales data (1M sales records)
- Generates KPI metrics (90 days of daily metrics)

**⏱️ Time estimate:**
- Fast machine (SSD, 16GB RAM): ~15 minutes
- Average machine: ~20-25 minutes
- Slower machine: ~30 minutes

**You can monitor progress:**
The script shows progress for each step:
```
[1/15] Loading geographic reference data...
[2/15] Generating Customers...
[3/15] Generating Accounts...
...
[10/15] Generating Customer Lifetime Value data...
[11/15] Generating Churn Predictions...
[12/15] Generating Customer Satisfaction data...
[13/15] Generating Sales Transactions...
[14/15] Generating Daily Metrics...
[15/15] Generating Monthly Summaries...
```

---

### Step 4: Access the Database

#### Option A: pgAdmin Web Interface (Recommended for Beginners)

1. Open your browser to: **http://localhost:3000**
2. **Login:**
   - Email: `admin@businessanalytics.local`
   - Password: `SecurePass123!`
3. **First time setup - Add Server:**
   - Click "Add New Server"
   - **General tab:** Name: `Business Analytics`
   - **Connection tab:**
     - Host: `postgres`
     - Port: `5432`
     - Database: `business_analytics`
     - Username: `data_analyst`
     - Password: `SecurePass123!`
   - Click "Save"
4. Navigate to: **Servers > Business Analytics > Databases > business_analytics > Schemas > public > Tables**
5. Right-click any table and select "View/Edit Data" to browse
6. Use **Tools > Query Tool** to run SQL queries

**Features:**
- Professional database management interface
- Visual query builder
- Data export/import (CSV, JSON, etc.)
- Schema visualization
- Query history and favorites

#### Option B: Command Line (psql)

```bash
docker exec -it business_analytics_db psql -U data_analyst -d business_analytics
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
Database: business_analytics
Username: data_analyst
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

-- How many sales records?
SELECT COUNT(*) FROM sales_transactions;

-- How many KPIs are being tracked?
SELECT COUNT(*) FROM kpi_definitions WHERE is_active = TRUE;
```

### 2. Customer Analytics: High-Value Customers

```sql
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    clv.clv_score,
    cs.segment_name
FROM customers c
JOIN customer_lifetime_value clv ON c.customer_id = clv.customer_id
JOIN customer_segments cs ON clv.segment_id = cs.segment_id
WHERE cs.segment_name IN ('VIP', 'High Value')
ORDER BY clv.clv_score DESC
LIMIT 10;
```

### 3. Sales Analytics: Top Products

```sql
SELECT
    p.product_name,
    p.product_category,
    COUNT(st.transaction_id) as sales_count,
    SUM(st.total_amount) as total_revenue
FROM product_catalog p
JOIN sales_transactions st ON p.product_id = st.product_id
GROUP BY p.product_id, p.product_name, p.product_category
ORDER BY total_revenue DESC
LIMIT 10;
```

### 4. KPI Dashboard: Current Status

```sql
SELECT
    kd.kpi_name,
    kd.kpi_category,
    dm.metric_value,
    kd.target_value,
    dm.status
FROM kpi_definitions kd
JOIN daily_metrics dm ON kd.kpi_id = dm.kpi_id
WHERE dm.metric_date = CURRENT_DATE
  AND kd.is_active = TRUE
ORDER BY kd.kpi_category, kd.kpi_name;
```

### 5. Fraud Detection: Flagged Transactions

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

1. **Use pgAdmin for exploration** - Great for browsing and understanding the schema
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

