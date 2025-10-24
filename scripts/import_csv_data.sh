#!/bin/bash

# ============================================================================
# CSV Bulk Import Script for PostgreSQL
# ============================================================================
# Uses PostgreSQL COPY command for fast bulk loading
# Much faster and more reliable than INSERT statements
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Database connection parameters
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-business_analytics}"
DB_USER="${DB_USER:-data_analyst}"
DB_PASSWORD="${DB_PASSWORD:-SecurePass123!}"

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CSV_DIR="$PROJECT_ROOT/data/csv"

# Export password for psql
export PGPASSWORD="$DB_PASSWORD"

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}CSV Bulk Import - Business Analytics Database${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo -e "${CYAN}Database: ${GREEN}$DB_NAME@$DB_HOST:$DB_PORT${NC}"
echo -e "${CYAN}CSV Directory: ${GREEN}$CSV_DIR${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo ""

# Function to execute SQL
execute_sql() {
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "$1" 2>&1
}

# Function to import CSV file
import_csv() {
    local table_name=$1
    local csv_file=$2
    local row_count_var=$3

    if [ ! -f "$csv_file" ]; then
        echo -e "${RED}✗ CSV file not found: $csv_file${NC}"
        return 1
    fi

    echo -e "${YELLOW}Importing $table_name...${NC}"

    # Convert to absolute path
    local abs_csv_file=$(cd "$(dirname "$csv_file")" && pwd)/$(basename "$csv_file")

    # Use COPY command for bulk import
    # Note: \COPY works from client side and can read local files
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
        -c "\COPY $table_name FROM '$abs_csv_file' WITH (FORMAT csv, HEADER true, NULL '')" 2>&1

    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
        # Get row count
        local count=$(execute_sql "SELECT COUNT(*) FROM $table_name;" | sed -n 3p | tr -d ' ')
        eval "$row_count_var=$count"
        echo -e "${GREEN}✓ Imported $count rows into $table_name${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to import $table_name (exit code: $exit_code)${NC}"
        echo -e "${YELLOW}CSV file: $abs_csv_file${NC}"
        return 1
    fi
}

echo -e "${YELLOW}[Step 1/3] Checking CSV files...${NC}"
echo ""

# Check if CSV directory exists
if [ ! -d "$CSV_DIR" ]; then
    echo -e "${RED}✗ CSV directory not found: $CSV_DIR${NC}"
    echo -e "${YELLOW}Please run the CSV generation script first:${NC}"
    echo -e "${GREEN}  python3 scripts/generate_csv_data.py${NC}"
    exit 1
fi

# Count CSV files
csv_count=$(find "$CSV_DIR" -name "*.csv" -type f | wc -l)
if [ "$csv_count" -eq 0 ]; then
    echo -e "${RED}✗ No CSV files found in $CSV_DIR${NC}"
    echo -e "${YELLOW}Please run the CSV generation script first:${NC}"
    echo -e "${GREEN}  python3 scripts/generate_csv_data.py${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Found $csv_count CSV files${NC}"
echo ""

echo -e "${YELLOW}[Step 2/3] Clearing existing data...${NC}"
echo ""

# Clear existing data in correct order (respecting foreign keys)
echo -e "${CYAN}Truncating tables...${NC}"
execute_sql "TRUNCATE TABLE alerts CASCADE;" > /dev/null
execute_sql "TRUNCATE TABLE fraud_cases CASCADE;" > /dev/null
execute_sql "TRUNCATE TABLE transactions CASCADE;" > /dev/null
execute_sql "TRUNCATE TABLE devices CASCADE;" > /dev/null
execute_sql "TRUNCATE TABLE cards CASCADE;" > /dev/null
execute_sql "TRUNCATE TABLE accounts CASCADE;" > /dev/null
execute_sql "TRUNCATE TABLE customer_lifetime_value CASCADE;" > /dev/null
execute_sql "TRUNCATE TABLE customers CASCADE;" > /dev/null
execute_sql "TRUNCATE TABLE merchants CASCADE;" > /dev/null

echo -e "${GREEN}✓ Existing data cleared${NC}"
echo ""

echo -e "${YELLOW}[Step 3/3] Importing CSV data...${NC}"
echo ""
echo -e "${CYAN}This may take a few minutes for large datasets...${NC}"
echo ""

# Import in correct order (respecting foreign keys)
# Start timing
start_time=$(date +%s)

# Core entities first
import_csv "customers" "$CSV_DIR/customers.csv" customer_count
import_csv "accounts" "$CSV_DIR/accounts.csv" account_count
import_csv "merchants" "$CSV_DIR/merchants.csv" merchant_count
import_csv "cards" "$CSV_DIR/cards.csv" card_count
import_csv "devices" "$CSV_DIR/devices.csv" device_count

# Transactions (depends on accounts, cards, merchants)
import_csv "transactions" "$CSV_DIR/transactions.csv" transaction_count

# Fraud detection (depends on transactions, customers)
import_csv "alerts" "$CSV_DIR/alerts.csv" alert_count
import_csv "fraud_cases" "$CSV_DIR/fraud_cases.csv" case_count

# Analytics (depends on customers)
if [ -f "$CSV_DIR/customer_segments.csv" ]; then
    # First, clear and import segments reference data
    execute_sql "TRUNCATE TABLE customer_segments RESTART IDENTITY CASCADE;" > /dev/null
    import_csv "customer_segments" "$CSV_DIR/customer_segments.csv" segment_count
fi

if [ -f "$CSV_DIR/customer_lifetime_value.csv" ]; then
    import_csv "customer_lifetime_value" "$CSV_DIR/customer_lifetime_value.csv" clv_count
fi

# End timing
end_time=$(date +%s)
duration=$((end_time - start_time))

echo ""
echo -e "${BLUE}============================================================================${NC}"
echo -e "${GREEN}✓ CSV Import Complete!${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo ""
echo -e "${CYAN}Import Statistics:${NC}"
echo -e "  Customers: ${GREEN}${customer_count:-0}${NC}"
echo -e "  Accounts: ${GREEN}${account_count:-0}${NC}"
echo -e "  Merchants: ${GREEN}${merchant_count:-0}${NC}"
echo -e "  Cards: ${GREEN}${card_count:-0}${NC}"
echo -e "  Devices: ${GREEN}${device_count:-0}${NC}"
echo -e "  Transactions: ${GREEN}${transaction_count:-0}${NC}"
echo -e "  Alerts: ${GREEN}${alert_count:-0}${NC}"
echo -e "  Fraud Cases: ${GREEN}${case_count:-0}${NC}"
if [ -n "$segment_count" ]; then
    echo -e "  Customer Segments: ${GREEN}${segment_count:-0}${NC}"
fi
if [ -n "$clv_count" ]; then
    echo -e "  Customer CLV Records: ${GREEN}${clv_count:-0}${NC}"
fi
echo ""
echo -e "${CYAN}Import Duration: ${GREEN}${duration} seconds${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo ""

# Verify data
echo -e "${YELLOW}Verifying data integrity...${NC}"
echo ""

# Check for orphaned records
orphaned_accounts=$(execute_sql "SELECT COUNT(*) FROM accounts WHERE customer_id NOT IN (SELECT customer_id FROM customers);" | sed -n 3p | tr -d ' ')
orphaned_transactions=$(execute_sql "SELECT COUNT(*) FROM transactions WHERE account_id NOT IN (SELECT account_id FROM accounts);" | sed -n 3p | tr -d ' ')

if [ "$orphaned_accounts" -eq 0 ] && [ "$orphaned_transactions" -eq 0 ]; then
    echo -e "${GREEN}✓ Data integrity check passed${NC}"
else
    echo -e "${YELLOW}⚠ Found some orphaned records:${NC}"
    echo -e "  Orphaned accounts: $orphaned_accounts"
    echo -e "  Orphaned transactions: $orphaned_transactions"
fi

echo ""
echo -e "${GREEN}Data import successful! You can now query the database.${NC}"
echo ""

