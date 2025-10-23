#!/bin/bash

# ============================================================================
# Setup Verification Script
# ============================================================================
# Verifies that the business analytics database is properly set up
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DB_HOST="${POSTGRES_HOST:-localhost}"
DB_PORT="${POSTGRES_PORT:-5432}"
DB_NAME="${POSTGRES_DB:-business_analytics}"
DB_USER="${POSTGRES_USER:-data_analyst}"
DB_PASSWORD="${POSTGRES_PASSWORD:-SecurePass123!}"

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}Business Analytics Database - Verification${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo ""

# Check for required dependencies
check_dependencies() {
    local missing_deps=()

    # Check for psql
    if ! command -v psql >/dev/null 2>&1; then
        missing_deps+=("psql (PostgreSQL client)")
    fi

    # Check for docker
    if ! command -v docker >/dev/null 2>&1; then
        missing_deps+=("docker")
    fi

    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo -e "${RED}✗ Missing required dependencies:${NC}"
        for dep in "${missing_deps[@]}"; do
            echo -e "  - ${YELLOW}$dep${NC}"
        done
        echo ""
        echo -e "${YELLOW}Run the dependency installer:${NC}"
        echo -e "  ${GREEN}./scripts/install-dependencies.sh${NC}"
        exit 1
    fi
}

# Run dependency check
check_dependencies

# Function to execute SQL and get result
execute_sql() {
    PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "$1" 2>/dev/null | xargs
}

# Check 1: Docker containers
echo -e "${YELLOW}[1/10] Checking Docker containers...${NC}"
if docker ps | grep -q "business_analytics_db"; then
    echo -e "${GREEN}✓ PostgreSQL container is running${NC}"
else
    echo -e "${RED}✗ PostgreSQL container is not running${NC}"
    echo -e "${YELLOW}Run: docker-compose up -d${NC}"
    exit 1
fi

if docker ps | grep -q "business_analytics_ui"; then
    echo -e "${GREEN}✓ DB-UI container is running${NC}"
else
    echo -e "${RED}✗ DB-UI container is not running${NC}"
    echo -e "${YELLOW}Run: docker-compose up -d${NC}"
    exit 1
fi
echo ""

# Check 2: Database connectivity
echo -e "${YELLOW}[2/10] Checking database connectivity...${NC}"
if PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c '\q' 2>/dev/null; then
    echo -e "${GREEN}✓ Can connect to database${NC}"
else
    echo -e "${RED}✗ Cannot connect to database${NC}"
    exit 1
fi
echo ""

# Check 3: Tables exist
echo -e "${YELLOW}[3/10] Checking database schema...${NC}"
table_count=$(execute_sql "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE';")
if [ "$table_count" -ge 20 ]; then
    echo -e "${GREEN}✓ Schema created ($table_count tables)${NC}"
else
    echo -e "${RED}✗ Schema incomplete (only $table_count tables)${NC}"
    echo -e "${YELLOW}Run: ./scripts/setup-database.sh${NC}"
    exit 1
fi
echo ""

# Check 4: Reference data
echo -e "${YELLOW}[4/10] Checking reference data...${NC}"
country_count=$(execute_sql "SELECT COUNT(*) FROM countries;")
category_count=$(execute_sql "SELECT COUNT(*) FROM merchant_categories;")
type_count=$(execute_sql "SELECT COUNT(*) FROM transaction_types;")
fraud_type_count=$(execute_sql "SELECT COUNT(*) FROM fraud_types;")

if [ "$country_count" -ge 40 ]; then
    echo -e "${GREEN}✓ Countries loaded ($country_count)${NC}"
else
    echo -e "${RED}✗ Countries not loaded${NC}"
fi

if [ "$category_count" -ge 30 ]; then
    echo -e "${GREEN}✓ Merchant categories loaded ($category_count)${NC}"
else
    echo -e "${RED}✗ Merchant categories not loaded${NC}"
fi

if [ "$type_count" -ge 10 ]; then
    echo -e "${GREEN}✓ Transaction types loaded ($type_count)${NC}"
else
    echo -e "${RED}✗ Transaction types not loaded${NC}"
fi

if [ "$fraud_type_count" -ge 15 ]; then
    echo -e "${GREEN}✓ Fraud types loaded ($fraud_type_count)${NC}"
else
    echo -e "${RED}✗ Fraud types not loaded${NC}"
fi
echo ""

# Check 5: Customer data
echo -e "${YELLOW}[5/10] Checking customer data...${NC}"
customer_count=$(execute_sql "SELECT COUNT(*) FROM customers;")
if [ "$customer_count" -ge 10000 ]; then
    echo -e "${GREEN}✓ Customers generated ($customer_count)${NC}"
else
    echo -e "${YELLOW}⚠ Limited customer data ($customer_count)${NC}"
    echo -e "${YELLOW}Run: ./data/generate_data.sh${NC}"
fi
echo ""

# Check 6: Account data
echo -e "${YELLOW}[6/10] Checking account data...${NC}"
account_count=$(execute_sql "SELECT COUNT(*) FROM accounts;")
if [ "$account_count" -ge 10000 ]; then
    echo -e "${GREEN}✓ Accounts generated ($account_count)${NC}"
else
    echo -e "${YELLOW}⚠ Limited account data ($account_count)${NC}"
fi
echo ""

# Check 7: Transaction data
echo -e "${YELLOW}[7/10] Checking transaction data...${NC}"
transaction_count=$(execute_sql "SELECT COUNT(*) FROM transactions;")
if [ "$transaction_count" -ge 100000 ]; then
    echo -e "${GREEN}✓ Transactions generated ($transaction_count)${NC}"
else
    echo -e "${YELLOW}⚠ Limited transaction data ($transaction_count)${NC}"
fi
echo ""

# Check 8: Fraud data
echo -e "${YELLOW}[8/10] Checking fraud detection data...${NC}"
alert_count=$(execute_sql "SELECT COUNT(*) FROM alerts;")
case_count=$(execute_sql "SELECT COUNT(*) FROM fraud_cases;")

if [ "$alert_count" -ge 100 ]; then
    echo -e "${GREEN}✓ Alerts generated ($alert_count)${NC}"
else
    echo -e "${YELLOW}⚠ Limited alert data ($alert_count)${NC}"
fi

if [ "$case_count" -ge 10 ]; then
    echo -e "${GREEN}✓ Fraud cases generated ($case_count)${NC}"
else
    echo -e "${YELLOW}⚠ Limited fraud case data ($case_count)${NC}"
fi
echo ""

# Check 9: Indexes
echo -e "${YELLOW}[9/10] Checking database indexes...${NC}"
index_count=$(execute_sql "SELECT COUNT(*) FROM pg_indexes WHERE schemaname = 'public';")
if [ "$index_count" -ge 20 ]; then
    echo -e "${GREEN}✓ Indexes created ($index_count)${NC}"
else
    echo -e "${YELLOW}⚠ Limited indexes ($index_count)${NC}"
fi
echo ""

# Check 10: DB-UI accessibility
echo -e "${YELLOW}[10/10] Checking DB-UI web interface...${NC}"
if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 | grep -q "200\|302"; then
    echo -e "${GREEN}✓ DB-UI accessible at http://localhost:3000${NC}"
else
    echo -e "${YELLOW}⚠ DB-UI may not be ready yet (still starting up)${NC}"
fi
echo ""

# Summary
echo -e "${BLUE}============================================================================${NC}"
echo -e "${GREEN}Verification Summary${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo ""
echo -e "${YELLOW}Database Statistics:${NC}"
echo -e "  Customers:     ${GREEN}$customer_count${NC}"
echo -e "  Accounts:      ${GREEN}$account_count${NC}"
echo -e "  Transactions:  ${GREEN}$transaction_count${NC}"
echo -e "  Alerts:        ${GREEN}$alert_count${NC}"
echo -e "  Fraud Cases:   ${GREEN}$case_count${NC}"
echo ""

if [ "$transaction_count" -ge 100000 ]; then
    echo -e "${GREEN}✓ Database is ready for SQL learning!${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo -e "1. Access DB-UI: ${BLUE}http://localhost:3000${NC}"
    echo -e "2. Start learning: ${BLUE}exercises/01-basic-queries/README.md${NC}"
    echo -e "3. Quick start guide: ${BLUE}docs/QUICKSTART.md${NC}"
else
    echo -e "${YELLOW}⚠ Database has minimal data${NC}"
    echo ""
    echo -e "${YELLOW}To generate full dataset:${NC}"
    echo -e "  ${BLUE}./data/generate_data.sh${NC}"
    echo ""
    echo -e "${YELLOW}This will generate:${NC}"
    echo -e "  - 100,000 customers"
    echo -e "  - 150,000 accounts"
    echo -e "  - 5,000,000 transactions"
    echo -e "  - 50,000+ alerts"
    echo -e "  - 5,000+ fraud cases"
fi
echo ""

