# Financial Fraud Detection - SQL Learning Database

A comprehensive, production-grade database designed for learning SQL through realistic financial fraud investigation scenarios.

## 🎯 Overview

This project provides a complete PostgreSQL database with **5+ million transactions**, embedded fraud patterns, and progressive SQL exercises. Perfect for:

- **SQL Beginners** → Learn fundamentals with real-world data
- **Data Analysts** → Practice fraud detection queries
- **Security Professionals** → Understand fraud patterns
- **Students** → Hands-on financial crime investigation

## 📊 Database Statistics

- **100,000** Customers with KYC data
- **150,000** Bank accounts (checking, savings, credit)
- **200,000** Payment cards
- **50,000** Merchants across 35 categories
- **5,000,000** Transactions (7% fraudulent)
- **50,000+** Fraud alerts
- **5,000+** Fraud cases
- **500,000** Login sessions

## 🏗️ Architecture

### Data Model Features
- ✅ **20+ Tables** with proper relationships
- ✅ **Foreign key constraints** for data integrity
- ✅ **Indexes** for query performance
- ✅ **Realistic geographic data** (100 US cities, 210 world cities)
- ✅ **Embedded fraud patterns** (velocity, geographic, structuring)
- ✅ **Audit trails** and compliance tables

### Key Entities
```
customers → accounts → transactions
                    ↓
                  cards → merchants
                    ↓
                 alerts → fraud_cases
```

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose
- 8GB RAM minimum
- 20GB disk space

### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/SQL.git
cd SQL
```

### 2. Start the Database
```bash
docker-compose up -d
```

This starts:
- **PostgreSQL 16** on port `5432`
- **DB-UI** web interface on port `3000`

### 3. Initialize the Schema
```bash
chmod +x scripts/setup-database.sh
./scripts/setup-database.sh
```

### 4. Generate Test Data
```bash
chmod +x data/generate_data.sh
./data/generate_data.sh
```

⏱️ **Note:** Data generation takes 15-30 minutes depending on your system.

### 5. Access the Database

**Option A: DB-UI Web Interface**
```
http://localhost:3000
```

**Option B: Command Line**
```bash
docker exec -it fraud_detection_db psql -U fraud_analyst -d fraud_detection
```

**Option C: Your Favorite SQL Client**
```
Host: localhost
Port: 5432
Database: fraud_detection
Username: fraud_analyst
Password: SecurePass123!
```

## 📚 Learning Path

### Level 1: Basic Queries
- SELECT, WHERE, ORDER BY
- Filtering and sorting
- Basic comparisons
- **Location:** `exercises/01-basic-queries/`

### Level 2: Joins
- INNER JOIN, LEFT JOIN
- Multiple table queries
- Relationship navigation
- **Location:** `exercises/02-joins/`

### Level 3: Aggregations
- COUNT, SUM, AVG, MAX, MIN
- GROUP BY and HAVING
- Statistical analysis
- **Location:** `exercises/03-aggregations/`

### Level 4: Subqueries
- Nested queries
- Correlated subqueries
- EXISTS and IN
- **Location:** `exercises/04-subqueries/`

### Level 5: Window Functions
- ROW_NUMBER, RANK, DENSE_RANK
- Running totals
- Moving averages
- **Location:** `exercises/05-window-functions/`

### Level 6: Fraud Detection
- Velocity fraud detection
- Geographic anomalies
- Money mule networks
- Account takeover patterns
- **Location:** `exercises/06-fraud-detection/`

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
│   └── setup-database.sh       # Setup automation
├── exercises/
│   ├── 01-basic-queries/
│   ├── 02-joins/
│   ├── 03-aggregations/
│   ├── 04-subqueries/
│   ├── 05-window-functions/
│   └── 06-fraud-detection/
└── docs/
    ├── data-model.md
    ├── fraud-patterns.md
    └── setup-guide.md
```

## 🔧 Configuration

### Environment Variables
Edit `docker-compose.yml` to customize:

```yaml
POSTGRES_DB: fraud_detection
POSTGRES_USER: fraud_analyst
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

### Find High-Risk Customers
```sql
SELECT customer_id, first_name, last_name, risk_score
FROM customers
WHERE risk_score > 80
ORDER BY risk_score DESC;
```

### Detect Velocity Fraud
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
