# Business Analytics - SQL Learning Database

A comprehensive, production-grade database designed for learning SQL through realistic business analytics, customer insights, sales analysis, and fraud detection scenarios.

## 🎯 Overview

This project provides a complete PostgreSQL database with **5+ million transactions**, **39 tables** across 4 business models, and progressive SQL exercises aligned with **Data Analyst** responsibilities. Perfect for:

- **SQL Beginners** → Learn fundamentals with real-world data
- **Data Analysts** → Practice customer analytics, sales analysis, KPI dashboards
- **Business Analysts** → Understand customer behavior and revenue patterns
- **Security Professionals** → Detect fraud patterns
- **Students** → Hands-on business intelligence and analytics

## 📊 Database Statistics

### Core Data
- **100,000** Customers with KYC data
- **150,000** Bank accounts (checking, savings, credit)
- **200,000** Payment cards
- **50,000** Merchants across 35 categories
- **5,000,000** Transactions (7% fraudulent)
- **1,000,000** Sales records linked to products
- **500,000** Login sessions

### Analytics Data
- **100,000** Customer Lifetime Value calculations
- **100,000** Churn predictions
- **30,000** Customer satisfaction surveys
- **24** Product catalog entries
- **1,500+** Daily KPI metrics
- **24** Monthly business summaries
- **50,000+** Fraud alerts
- **5,000+** Fraud cases

## 🏗️ Architecture

### Data Model Features
- ✅ **39 Tables** across 4 business models
- ✅ **Foreign key constraints** for data integrity
- ✅ **Indexes** for query performance
- ✅ **Realistic geographic data** (100 US cities, 210 world cities)
- ✅ **Customer analytics** (CLV, churn, satisfaction, engagement)
- ✅ **Sales analytics** (products, targets, forecasts)
- ✅ **KPI tracking** (daily metrics, trends, dashboards)
- ✅ **Fraud detection** (velocity, geographic, structuring patterns)
- ✅ **Audit trails** and compliance tables

### Business Models

#### 1. Fraud Detection Model (20 tables)
```
customers → accounts → transactions → alerts → fraud_cases
              ↓
            cards → merchants
```

#### 2. Customer Analytics Model (5 tables)
```
customers → customer_lifetime_value → customer_segments
         → churn_predictions
         → customer_satisfaction
         → engagement_metrics
```

#### 3. Sales & Revenue Model (6 tables)
```
product_catalog → sales_transactions → sales_performance
                                    → sales_targets
                                    → revenue_forecasts
```

#### 4. KPI & Metrics Model (8 tables)
```
kpi_definitions → daily_metrics → trend_analysis
               → monthly_summaries
               → dashboard_snapshots
               → report_definitions → report_executions
               → data_quality_checks
```

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose
- PostgreSQL client (psql)
- 8GB RAM minimum
- 20GB disk space

**🔧 Don't have the prerequisites?** Run the automatic installer:
```bash
chmod +x scripts/install-dependencies.sh
./scripts/install-dependencies.sh
```

This will automatically install:
- ✅ PostgreSQL client (psql)
- ✅ Docker & Docker Compose
- ✅ Required utilities (curl, wget, git)

**Supported OS:** Ubuntu, Debian, CentOS, RHEL, Fedora, Arch Linux, macOS

---

### 1. Clone the Repository
```bash
git clone https://github.com/freedbygrace/SQL.git
cd SQL
```

### 2. Install Dependencies (Optional)
```bash
# Only if you don't have Docker, psql, etc.
chmod +x scripts/install-dependencies.sh
./scripts/install-dependencies.sh
```

### 3. Start the Database
```bash
docker-compose up -d
```

This starts:
- **PostgreSQL 16** on port `5432`
- **DB-UI** web interface on port `3000`

### 4. Initialize the Schema
```bash
chmod +x scripts/setup-database.sh
./scripts/setup-database.sh
```

**Note:** The script will automatically check for required dependencies and prompt you to install them if missing.

### 5. Generate Test Data
```bash
chmod +x data/generate_data.sh
./data/generate_data.sh
```

⏱️ **Note:** Data generation takes 15-30 minutes depending on your system.

### 6. Access the Database

**Option A: DB-UI Web Interface**
```
http://localhost:3000
```

**Option B: Command Line**
```bash
docker exec -it business_analytics_db psql -U data_analyst -d business_analytics
```

**Option C: Your Favorite SQL Client**
```
Host: localhost
Port: 5432
Database: business_analytics
Username: data_analyst
Password: SecurePass123!
```

## 📚 Learning Path

### Level 1: Basic Queries
- SELECT, WHERE, ORDER BY
- Filtering and sorting
- Basic comparisons
- **Location:** `exercises/01-basic-queries/`

### Level 2: Customer Analytics ⭐ NEW
- Customer segmentation
- Lifetime value (CLV) analysis
- Churn prediction
- Satisfaction metrics
- Engagement tracking
- **Location:** `exercises/02-customer-analytics/`

### Level 3: Sales & Revenue Analysis ⭐ NEW
- Sales performance vs targets
- Product analytics
- Channel and regional analysis
- Revenue forecasting
- Profitability analysis
- **Location:** `exercises/03-sales-analysis/`

### Level 4: KPI Dashboards & Metrics ⭐ NEW
- KPI tracking and monitoring
- Trend analysis
- Dashboard creation
- Data quality monitoring
- Executive reporting
- **Location:** `exercises/04-kpi-dashboards/`

### Level 5: Advanced SQL Techniques
- Window functions (ROW_NUMBER, RANK)
- Common Table Expressions (CTEs)
- Running totals and moving averages
- Complex aggregations
- **Location:** `exercises/05-advanced-sql/`

### Level 6: Fraud Detection
- Velocity fraud detection
- Geographic anomalies
- Money mule networks
- Account takeover patterns
- **Location:** `exercises/06-fraud-detection/`

## 💼 Data Analyst Use Cases

This database supports typical **Data Analyst** responsibilities:

### Routine Analysis
- Daily sales summaries
- Customer acquisition metrics
- Transaction volume tracking
- Basic KPI monitoring

### Semi-Routine Reporting
- Weekly customer analytics
- Monthly revenue reports
- Product performance analysis
- Churn risk identification

### Dashboard Creation
- Executive KPI dashboards
- Sales performance dashboards
- Customer health dashboards
- Operational metrics dashboards

### Trend Identification
- Revenue trends (MoM, YoY)
- Customer behavior patterns
- Product sales seasonality
- Engagement score trends

### Data Quality
- Missing data detection
- Anomaly identification
- Validation checks
- Data completeness monitoring

## 🔍 Fraud Patterns Included

### 1. Velocity Fraud
Multiple rapid transactions from the same account

### 2. Geographic Impossibility
Card used in different countries within hours

### 3. Money Mule Networks
Rapid transfer chains between accounts

### 4. Account Takeover
Sudden changes in transaction patterns

### 5. Structuring (Smurfing)
Multiple transactions just under $10,000 reporting threshold

### 6. Card Testing
Multiple small failed transactions

### 7. High-Risk Merchants
Unusual activity at gambling/crypto merchants

### 8. Dormant Account Reactivation
Long-inactive accounts suddenly active

## 📁 Project Structure

```
SQL/
├── docker-compose.yml          # Docker orchestration
├── docker/
│   └── init/                   # Database initialization
├── schema/
│   ├── 01-create-tables.sql    # DDL (idempotent)
│   └── 02-seed-data.sql        # Reference data
├── data/
│   ├── generate_data.sh        # Data generation script
│   └── reference/              # Geographic data
│       ├── us_cities.csv
│       ├── world_cities.csv
│       └── load_geographic_data.sql
├── scripts/
│   ├── setup-database.sh       # Setup automation
│   └── verify-setup.sh         # Verification script
├── exercises/
│   ├── 01-basic-queries/       # SQL fundamentals
│   ├── 02-customer-analytics/  # ⭐ Customer insights
│   ├── 03-sales-analysis/      # ⭐ Sales & revenue
│   ├── 04-kpi-dashboards/      # ⭐ KPI tracking
│   ├── 05-advanced-sql/        # Advanced techniques
│   └── 06-fraud-detection/     # Fraud patterns
└── docs/
    ├── DATA_MODELS.md          # ⭐ Complete model documentation
    ├── WHATS_NEW.md            # ⭐ Recent changes
    └── QUICKSTART.md           # Quick start guide
```

## 🔧 Configuration

### Environment Variables
Edit `docker-compose.yml` to customize:

```yaml
POSTGRES_DB: business_analytics
POSTGRES_USER: data_analyst
POSTGRES_PASSWORD: SecurePass123!
```

### Data Volume
Modify `data/generate_data.sh`:

```bash
NUM_CUSTOMERS=100000      # Adjust as needed
NUM_TRANSACTIONS=5000000  # Adjust as needed
FRAUD_PERCENTAGE=7        # 7% fraudulent
```

## 🔄 Idempotency

All scripts are **idempotent** - safe to run multiple times:

- `setup-database.sh` - Drops and recreates schema
- `generate_data.sh` - Clears and regenerates data
- Schema files use `DROP IF EXISTS`

## 🎓 Sample Queries

### Customer Analytics: High-Value Customers
```sql
SELECT
    c.customer_id, c.first_name, c.last_name,
    clv.clv_score, cs.segment_name
FROM customers c
JOIN customer_lifetime_value clv ON c.customer_id = clv.customer_id
JOIN customer_segments cs ON clv.segment_id = cs.segment_id
WHERE cs.segment_name IN ('VIP', 'High Value')
ORDER BY clv.clv_score DESC
LIMIT 20;
```

### Sales Analytics: Top Products
```sql
SELECT
    p.product_name, p.product_category,
    COUNT(st.transaction_id) as sales_count,
    SUM(st.total_amount) as total_revenue
FROM product_catalog p
JOIN sales_transactions st ON p.product_id = st.product_id
GROUP BY p.product_id, p.product_name, p.product_category
ORDER BY total_revenue DESC
LIMIT 10;
```

### KPI Dashboard: Current Status
```sql
SELECT
    kd.kpi_name, kd.kpi_category,
    dm.metric_value, kd.target_value,
    dm.status
FROM kpi_definitions kd
JOIN daily_metrics dm ON kd.kpi_id = dm.kpi_id
WHERE dm.metric_date = CURRENT_DATE
  AND kd.is_active = TRUE
ORDER BY kd.kpi_category, kd.kpi_name;
```

### Fraud Detection: Velocity Fraud
```sql
SELECT account_id, COUNT(*) as txn_count, SUM(amount) as total
FROM transactions
WHERE transaction_date >= NOW() - INTERVAL '1 hour'
GROUP BY account_id
HAVING COUNT(*) > 5;
```

### Geographic Anomalies
```sql
SELECT t1.card_id, c1.country_name, c2.country_name,
       t2.transaction_date - t1.transaction_date as time_diff
FROM transactions t1
JOIN transactions t2 ON t1.card_id = t2.card_id
JOIN countries c1 ON t1.country_id = c1.country_id
JOIN countries c2 ON t2.country_id = c2.country_id
WHERE t1.country_id != t2.country_id
  AND t2.transaction_date BETWEEN t1.transaction_date
  AND t1.transaction_date + INTERVAL '2 hours';
```

## 🛠️ Maintenance

### Reset Everything
```bash
docker-compose down -v
docker-compose up -d
./scripts/setup-database.sh
./data/generate_data.sh
```

### Backup Database
```bash
docker exec fraud_detection_db pg_dump -U fraud_analyst fraud_detection > backup.sql
```

### Restore Database
```bash
cat backup.sql | docker exec -i fraud_detection_db psql -U fraud_analyst -d fraud_detection
```

## 📖 Documentation

- **[Data Model](docs/data-model.md)** - Complete ER diagram and table descriptions
- **[Fraud Patterns](docs/fraud-patterns.md)** - Detailed fraud scenario explanations
- **[Setup Guide](docs/setup-guide.md)** - Detailed installation instructions

## 🤝 Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Add exercises or improve data generation
4. Submit a pull request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- PostgreSQL community
- DB-UI project (https://github.com/n7olkachev/db-ui)
- Financial crime investigation best practices

## 📧 Support

- **Issues:** GitHub Issues
- **Discussions:** GitHub Discussions
- **Documentation:** `/docs` folder

---

**Happy Learning! 🎉**

Start with `exercises/01-basic-queries/` and work your way up to detecting sophisticated fraud patterns!
