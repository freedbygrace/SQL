#!/bin/bash

# ============================================================================
# Business Analytics - Data Generation Script - IDEMPOTENT
# ============================================================================
# Generates realistic test data for business analytics and reporting
# This script is IDEMPOTENT - it will clear and regenerate all data
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

# Data volumes
NUM_CUSTOMERS=100000
NUM_ACCOUNTS=150000
NUM_MERCHANTS=50000
NUM_DEVICES=75000
NUM_CARDS=200000
NUM_TRANSACTIONS=5000000
FRAUD_PERCENTAGE=7  # 7% of transactions will be fraudulent

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}Business Analytics Database - Data Generation${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo -e "Target Database: ${GREEN}$DB_NAME@$DB_HOST:$DB_PORT${NC}"
echo -e "Customers: ${GREEN}$NUM_CUSTOMERS${NC}"
echo -e "Accounts: ${GREEN}$NUM_ACCOUNTS${NC}"
echo -e "Merchants: ${GREEN}$NUM_MERCHANTS${NC}"
echo -e "Cards: ${GREEN}$NUM_CARDS${NC}"
echo -e "Transactions: ${GREEN}$NUM_TRANSACTIONS${NC} (${YELLOW}${FRAUD_PERCENTAGE}% fraudulent${NC})"
echo -e "${BLUE}============================================================================${NC}"
echo ""

# Check for required dependencies
check_dependencies() {
    local missing_deps=()

    # Check for psql
    if ! command -v psql >/dev/null 2>&1; then
        missing_deps+=("psql (PostgreSQL client)")
    fi

    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo -e "${RED}✗ Missing required dependencies:${NC}"
        for dep in "${missing_deps[@]}"; do
            echo -e "  - ${YELLOW}$dep${NC}"
        done
        echo ""
        echo -e "${YELLOW}Would you like to run the dependency installer? (y/n)${NC}"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            if [ -f "$PROJECT_ROOT/scripts/install-dependencies.sh" ]; then
                chmod +x "$PROJECT_ROOT/scripts/install-dependencies.sh"
                "$PROJECT_ROOT/scripts/install-dependencies.sh"
                echo ""
                echo -e "${GREEN}Dependencies installed. Please re-run this script.${NC}"
                exit 0
            else
                echo -e "${RED}✗ install-dependencies.sh not found${NC}"
                echo -e "${YELLOW}Please install PostgreSQL client manually${NC}"
                exit 1
            fi
        else
            echo -e "${RED}✗ Cannot proceed without required dependencies${NC}"
            exit 1
        fi
    fi

    echo -e "${GREEN}✓ All required dependencies are installed${NC}"
    echo ""
}

# Run dependency check
check_dependencies

echo -e "${RED}WARNING: This will DELETE all existing data and regenerate it!${NC}"
echo -e "${YELLOW}Press Ctrl+C within 5 seconds to cancel...${NC}"
sleep 5
echo ""

# Function to execute SQL
execute_sql() {
    PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "$1" 2>&1
}

# Function to execute SQL file
execute_sql_file() {
    PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f "$1" 2>&1
}

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Clear existing data (preserve reference tables)
echo -e "${YELLOW}[0/15] Clearing existing data...${NC}"
execute_sql "TRUNCATE TABLE audit_log CASCADE;"
execute_sql "TRUNCATE TABLE suspicious_activity_reports CASCADE;"
execute_sql "TRUNCATE TABLE case_alerts CASCADE;"
execute_sql "TRUNCATE TABLE case_transactions CASCADE;"
execute_sql "TRUNCATE TABLE fraud_cases CASCADE;"
execute_sql "TRUNCATE TABLE alerts CASCADE;"
execute_sql "TRUNCATE TABLE transfers CASCADE;"
execute_sql "TRUNCATE TABLE beneficiaries CASCADE;"
execute_sql "TRUNCATE TABLE transactions CASCADE;"
execute_sql "TRUNCATE TABLE login_sessions CASCADE;"
execute_sql "TRUNCATE TABLE devices RESTART IDENTITY CASCADE;"
execute_sql "TRUNCATE TABLE cards RESTART IDENTITY CASCADE;"
execute_sql "TRUNCATE TABLE accounts RESTART IDENTITY CASCADE;"
execute_sql "TRUNCATE TABLE customer_relationships RESTART IDENTITY CASCADE;"
execute_sql "TRUNCATE TABLE customers RESTART IDENTITY CASCADE;"
execute_sql "TRUNCATE TABLE merchants RESTART IDENTITY CASCADE;"
echo -e "${GREEN}✓ Existing data cleared${NC}"
echo ""

# Load geographic reference data
echo -e "${YELLOW}[1/15] Loading geographic reference data...${NC}"
execute_sql_file "$SCRIPT_DIR/reference/load_geographic_data.sql" > /dev/null
echo -e "${GREEN}✓ Geographic data loaded (100 US cities, 210 world cities)${NC}"
echo ""

echo -e "${YELLOW}[2/15] Generating Customers...${NC}"
cat > /tmp/generate_customers.sql << 'EOF'
-- Generate customers with realistic geographic data
INSERT INTO customers (
    first_name, last_name, email, phone, date_of_birth, ssn_hash,
    address_line1, city, state, postal_code, country_id,
    registration_date, kyc_status, risk_score, is_pep, is_active
)
SELECT
    'Customer' || gs.id AS first_name,
    'User' || gs.id AS last_name,
    'customer' || gs.id || '@email.com' AS email,
    '+1' || LPAD((1000000000 + (gs.id % 9000000000))::TEXT, 10, '0') AS phone,
    DATE '1950-01-01' + (random() * 25000)::INT AS date_of_birth,
    encode(digest('SSN' || gs.id::TEXT, 'sha256'), 'hex') AS ssn_hash,
    (gs.id % 10000) || ' Main Street' AS address_line1,
    -- Use real US cities from temp table
    (SELECT city FROM temp_us_cities WHERE id = ((gs.id % 100) + 1)) AS city,
    (SELECT state_code FROM temp_us_cities WHERE id = ((gs.id % 100) + 1)) AS state,
    LPAD((10000 + (gs.id % 90000))::TEXT, 5, '0') AS postal_code,
    CASE
        WHEN random() < 0.85 THEN 1  -- 85% US
        WHEN random() < 0.90 THEN 2  -- 5% Canada
        WHEN random() < 0.95 THEN 3  -- 5% UK
        ELSE (3 + (gs.id % 37))      -- 5% other countries
    END AS country_id,
    TIMESTAMP '2020-01-01' + (random() * 1460)::INT * INTERVAL '1 day' AS registration_date,
    CASE
        WHEN random() < 0.90 THEN 'VERIFIED'
        WHEN random() < 0.95 THEN 'PENDING'
        ELSE 'REJECTED'
    END AS kyc_status,
    (random() * 100)::DECIMAL(5,2) AS risk_score,
    random() < 0.02 AS is_pep,  -- 2% are PEPs
    random() < 0.98 AS is_active  -- 98% active
FROM generate_series(1, 100000) AS gs(id);
EOF

execute_sql_file /tmp/generate_customers.sql > /dev/null
echo -e "${GREEN}✓ Generated $NUM_CUSTOMERS customers${NC}"
echo ""

echo -e "${YELLOW}[3/15] Generating Accounts...${NC}"
cat > /tmp/generate_accounts.sql << 'EOF'
-- Generate accounts (1-2 accounts per customer on average)
INSERT INTO accounts (
    customer_id, account_number, account_type, currency,
    opening_date, status, current_balance, available_balance,
    credit_limit, overdraft_limit, is_primary
)
SELECT
    (gs.id % 100000) + 1 AS customer_id,
    'ACC' || LPAD(gs.id::TEXT, 12, '0') AS account_number,
    CASE (gs.id % 10)
        WHEN 0 THEN 'CHECKING'
        WHEN 1 THEN 'CHECKING'
        WHEN 2 THEN 'CHECKING'
        WHEN 3 THEN 'SAVINGS'
        WHEN 4 THEN 'SAVINGS'
        WHEN 5 THEN 'CREDIT'
        WHEN 6 THEN 'CREDIT'
        WHEN 7 THEN 'INVESTMENT'
        ELSE 'CHECKING'
    END AS account_type,
    'USD' AS currency,
    DATE '2020-01-01' + (random() * 1460)::INT AS opening_date,
    CASE 
        WHEN random() < 0.95 THEN 'ACTIVE'
        WHEN random() < 0.98 THEN 'SUSPENDED'
        ELSE 'CLOSED'
    END AS status,
    (random() * 50000)::DECIMAL(15,2) AS current_balance,
    (random() * 50000)::DECIMAL(15,2) AS available_balance,
    CASE 
        WHEN (gs.id % 10) IN (5, 6) THEN (5000 + random() * 45000)::DECIMAL(15,2)
        ELSE NULL
    END AS credit_limit,
    CASE 
        WHEN (gs.id % 10) IN (0, 1, 2) THEN (random() * 1000)::DECIMAL(15,2)
        ELSE 0
    END AS overdraft_limit,
    (gs.id % 2) = 0 AS is_primary
FROM generate_series(1, 150000) AS gs(id);
EOF

execute_sql_file /tmp/generate_accounts.sql > /dev/null
echo -e "${GREEN}✓ Generated $NUM_ACCOUNTS accounts${NC}"
echo ""

echo -e "${YELLOW}[4/15] Generating Merchants...${NC}"
cat > /tmp/generate_merchants.sql << 'EOF'
-- Generate merchants with realistic geographic data
INSERT INTO merchants (
    merchant_name, merchant_code, category_id, country_id,
    city, registration_date, status, risk_rating, is_verified
)
SELECT
    CASE (gs.id % 15)
        WHEN 0 THEN 'Walmart Store #' || gs.id
        WHEN 1 THEN 'Amazon Marketplace #' || gs.id
        WHEN 2 THEN 'Shell Gas Station #' || gs.id
        WHEN 3 THEN 'McDonalds #' || gs.id
        WHEN 4 THEN 'Starbucks #' || gs.id
        WHEN 5 THEN 'Target Store #' || gs.id
        WHEN 6 THEN 'Best Buy #' || gs.id
        WHEN 7 THEN 'CVS Pharmacy #' || gs.id
        WHEN 8 THEN 'Home Depot #' || gs.id
        WHEN 9 THEN 'Costco #' || gs.id
        WHEN 10 THEN 'Apple Store #' || gs.id
        WHEN 11 THEN 'Marriott Hotel #' || gs.id
        WHEN 12 THEN 'Delta Airlines #' || gs.id
        WHEN 13 THEN 'Online Casino #' || gs.id
        ELSE 'Merchant #' || gs.id
    END AS merchant_name,
    'MER' || LPAD(gs.id::TEXT, 10, '0') AS merchant_code,
    ((gs.id % 35) + 1) AS category_id,
    CASE
        WHEN random() < 0.80 THEN 1  -- 80% US merchants
        WHEN random() < 0.90 THEN 2  -- 10% Canada
        ELSE (3 + (gs.id % 37))      -- 10% international
    END AS country_id,
    -- Use real cities based on country
    CASE
        WHEN random() < 0.80 THEN (SELECT city FROM temp_us_cities WHERE id = ((gs.id % 100) + 1))
        ELSE (SELECT city FROM temp_world_cities WHERE id = ((gs.id % 210) + 1))
    END AS city,
    DATE '2015-01-01' + (random() * 3000)::INT AS registration_date,
    CASE
        WHEN random() < 0.95 THEN 'ACTIVE'
        WHEN random() < 0.98 THEN 'SUSPENDED'
        ELSE 'BLACKLISTED'
    END AS status,
    CASE
        WHEN (gs.id % 35) + 1 IN (21, 22, 23, 24, 25, 26, 31, 32, 33, 34, 35) THEN
            CASE
                WHEN random() < 0.5 THEN 'HIGH'
                ELSE 'CRITICAL'
            END
        WHEN random() < 0.80 THEN 'LOW'
        ELSE 'MEDIUM'
    END AS risk_rating,
    random() < 0.90 AS is_verified
FROM generate_series(1, 50000) AS gs(id);
EOF

execute_sql_file /tmp/generate_merchants.sql > /dev/null
echo -e "${GREEN}✓ Generated $NUM_MERCHANTS merchants${NC}"
echo ""

echo -e "${YELLOW}[5/15] Generating Devices...${NC}"
cat > /tmp/generate_devices.sql << 'EOF'
-- Generate devices
INSERT INTO devices (
    device_fingerprint, device_type, os_name, os_version,
    browser_name, browser_version, is_trusted, is_blacklisted
)
SELECT
    encode(digest('DEVICE' || gs.id::TEXT, 'sha256'), 'hex') AS device_fingerprint,
    CASE (gs.id % 4)
        WHEN 0 THEN 'MOBILE'
        WHEN 1 THEN 'DESKTOP'
        WHEN 2 THEN 'TABLET'
        ELSE 'MOBILE'
    END AS device_type,
    CASE (gs.id % 5)
        WHEN 0 THEN 'iOS'
        WHEN 1 THEN 'Android'
        WHEN 2 THEN 'Windows'
        WHEN 3 THEN 'macOS'
        ELSE 'Linux'
    END AS os_name,
    CASE (gs.id % 5)
        WHEN 0 THEN '15.0'
        WHEN 1 THEN '12.0'
        WHEN 2 THEN '11.0'
        WHEN 3 THEN '13.0'
        ELSE '10.0'
    END AS os_version,
    CASE (gs.id % 4)
        WHEN 0 THEN 'Chrome'
        WHEN 1 THEN 'Safari'
        WHEN 2 THEN 'Firefox'
        ELSE 'Edge'
    END AS browser_name,
    '100.0' AS browser_version,
    random() < 0.85 AS is_trusted,
    random() < 0.03 AS is_blacklisted
FROM generate_series(1, 75000) AS gs(id);
EOF

execute_sql_file /tmp/generate_devices.sql > /dev/null
echo -e "${GREEN}✓ Generated $NUM_DEVICES devices${NC}"
echo ""

echo -e "${YELLOW}[6/15] Generating Cards...${NC}"
cat > /tmp/generate_cards.sql << 'EOF'
-- Generate cards (1-2 cards per account on average)
INSERT INTO cards (
    account_id, card_number_hash, card_last_four, card_type, card_network,
    issue_date, expiry_date, cvv_hash, status, daily_limit, monthly_limit,
    is_contactless, is_international
)
SELECT
    ((gs.id - 1) % 150000) + 1 AS account_id,
    encode(digest('CARD' || gs.id::TEXT, 'sha256'), 'hex') AS card_number_hash,
    LPAD((gs.id % 10000)::TEXT, 4, '0') AS card_last_four,
    CASE (gs.id % 4)
        WHEN 0 THEN 'DEBIT'
        WHEN 1 THEN 'CREDIT'
        WHEN 2 THEN 'DEBIT'
        ELSE 'CREDIT'
    END AS card_type,
    CASE (gs.id % 4)
        WHEN 0 THEN 'VISA'
        WHEN 1 THEN 'MASTERCARD'
        WHEN 2 THEN 'AMEX'
        ELSE 'DISCOVER'
    END AS card_network,
    DATE '2020-01-01' + (random() * 1000)::INT AS issue_date,
    DATE '2025-01-01' + (random() * 1825)::INT AS expiry_date,
    encode(digest('CVV' || gs.id::TEXT, 'sha256'), 'hex') AS cvv_hash,
    CASE
        WHEN random() < 0.95 THEN 'ACTIVE'
        WHEN random() < 0.97 THEN 'BLOCKED'
        WHEN random() < 0.99 THEN 'LOST'
        ELSE 'STOLEN'
    END AS status,
    (1000 + random() * 9000)::DECIMAL(10,2) AS daily_limit,
    (10000 + random() * 90000)::DECIMAL(12,2) AS monthly_limit,
    random() < 0.90 AS is_contactless,
    random() < 0.30 AS is_international
FROM generate_series(1, 200000) AS gs(id);
EOF

execute_sql_file /tmp/generate_cards.sql > /dev/null
echo -e "${GREEN}✓ Generated $NUM_CARDS cards${NC}"
echo ""

echo -e "${YELLOW}[7/15] Generating Login Sessions...${NC}"
cat > /tmp/generate_sessions.sql << 'EOF'
-- Generate login sessions with realistic geographic data
INSERT INTO login_sessions (
    customer_id, device_id, ip_address, country_id, city,
    login_timestamp, logout_timestamp, session_duration_seconds,
    is_successful, risk_score
)
SELECT
    ((gs.id - 1) % 100000) + 1 AS customer_id,
    ((gs.id - 1) % 75000) + 1 AS device_id,
    ('192.168.' || ((gs.id % 255) + 1) || '.' || ((gs.id % 255) + 1))::INET AS ip_address,
    CASE
        WHEN random() < 0.85 THEN 1
        ELSE ((gs.id % 40) + 1)
    END AS country_id,
    -- Use real cities
    CASE
        WHEN random() < 0.85 THEN (SELECT city FROM temp_us_cities WHERE id = ((gs.id % 100) + 1))
        ELSE (SELECT city FROM temp_world_cities WHERE id = ((gs.id % 210) + 1))
    END AS city,
    TIMESTAMP '2023-01-01' + (random() * 730)::INT * INTERVAL '1 day' + (random() * 86400)::INT * INTERVAL '1 second' AS login_timestamp,
    TIMESTAMP '2023-01-01' + (random() * 730)::INT * INTERVAL '1 day' + (random() * 86400)::INT * INTERVAL '1 second' + (random() * 7200)::INT * INTERVAL '1 second' AS logout_timestamp,
    (300 + random() * 7200)::INT AS session_duration_seconds,
    random() < 0.98 AS is_successful,
    (random() * 100)::DECIMAL(5,2) AS risk_score
FROM generate_series(1, 500000) AS gs(id);
EOF

execute_sql_file /tmp/generate_sessions.sql > /dev/null
echo -e "${GREEN}✓ Generated 500,000 login sessions${NC}"
echo ""

echo -e "${YELLOW}[8/15] Generating Transactions (this may take a while)...${NC}"
echo -e "${BLUE}This step generates $NUM_TRANSACTIONS transactions with fraud patterns${NC}"

# Generate transactions in batches to avoid memory issues
BATCH_SIZE=500000
NUM_BATCHES=$((NUM_TRANSACTIONS / BATCH_SIZE))

for batch in $(seq 1 $NUM_BATCHES); do
    START_ID=$(( (batch - 1) * BATCH_SIZE + 1 ))
    END_ID=$(( batch * BATCH_SIZE ))

    echo -e "${BLUE}  Batch $batch/$NUM_BATCHES (transactions $START_ID to $END_ID)...${NC}"

    cat > /tmp/generate_transactions_batch.sql << EOF
-- Generate transactions batch
INSERT INTO transactions (
    account_id, type_id, transaction_date, amount, currency,
    merchant_id, card_id, device_id, ip_address, country_id, city,
    description, reference_number, status, is_online, is_international,
    is_card_present, fraud_score, is_flagged
)
SELECT
    ((gs.id - 1) % 150000) + 1 AS account_id,
    ((gs.id % 15) + 1) AS type_id,
    TIMESTAMP '2023-01-01' + (random() * 730)::INT * INTERVAL '1 day' + (random() * 86400)::INT * INTERVAL '1 second' AS transaction_date,
    CASE
        WHEN random() < 0.60 THEN (5 + random() * 95)::DECIMAL(15,2)
        WHEN random() < 0.85 THEN (100 + random() * 400)::DECIMAL(15,2)
        WHEN random() < 0.95 THEN (500 + random() * 2000)::DECIMAL(15,2)
        WHEN random() < 0.98 THEN (2500 + random() * 7500)::DECIMAL(15,2)
        ELSE (10000 + random() * 90000)::DECIMAL(15,2)
    END AS amount,
    'USD' AS currency,
    CASE
        WHEN ((gs.id % 15) + 1) IN (1, 7, 13) THEN ((gs.id % 50000) + 1)
        ELSE NULL
    END AS merchant_id,
    CASE
        WHEN ((gs.id % 15) + 1) IN (1, 7, 13) THEN ((gs.id % 200000) + 1)
        ELSE NULL
    END AS card_id,
    ((gs.id % 75000) + 1) AS device_id,
    ('10.' || ((gs.id % 255) + 1) || '.' || ((gs.id % 255) + 1) || '.' || ((gs.id % 255) + 1))::INET AS ip_address,
    CASE
        WHEN random() < 0.90 THEN 1
        ELSE ((gs.id % 40) + 1)
    END AS country_id,
    -- Use real cities based on country
    CASE
        WHEN random() < 0.90 THEN (SELECT city FROM temp_us_cities WHERE id = ((gs.id % 100) + 1))
        ELSE (SELECT city FROM temp_world_cities WHERE id = ((gs.id % 210) + 1))
    END AS city,
    'Transaction #' || gs.id AS description,
    'REF' || LPAD(gs.id::TEXT, 15, '0') AS reference_number,
    CASE
        WHEN random() < 0.95 THEN 'COMPLETED'
        WHEN random() < 0.98 THEN 'PENDING'
        ELSE 'FAILED'
    END AS status,
    random() < 0.70 AS is_online,
    random() < 0.10 AS is_international,
    random() < 0.30 AS is_card_present,
    (random() * 100)::DECIMAL(5,2) AS fraud_score,
    random() < 0.07 AS is_flagged
FROM generate_series($START_ID, $END_ID) AS gs(id);
EOF

    execute_sql_file /tmp/generate_transactions_batch.sql > /dev/null
    echo -e "${GREEN}  ✓ Batch $batch/$NUM_BATCHES completed${NC}"
done

echo -e "${GREEN}✓ Generated $NUM_TRANSACTIONS transactions${NC}"
echo ""

echo -e "${YELLOW}[9/15] Generating Fraud Cases and Alerts...${NC}"

# Generate alerts for flagged transactions
execute_sql "
INSERT INTO alerts (transaction_id, customer_id, account_id, alert_type, severity, description, risk_score, status)
SELECT
    t.transaction_id,
    a.customer_id,
    t.account_id,
    CASE
        WHEN t.amount > 10000 THEN 'AMOUNT_ANOMALY'
        WHEN t.is_international THEN 'GEOGRAPHIC_ANOMALY'
        WHEN t.fraud_score > 80 THEN 'MERCHANT_RISK'
        ELSE 'VELOCITY_CHECK'
    END AS alert_type,
    CASE
        WHEN t.fraud_score > 80 THEN 'CRITICAL'
        WHEN t.fraud_score > 60 THEN 'HIGH'
        ELSE 'MEDIUM'
    END AS severity,
    'Suspicious transaction detected: ' || t.description AS description,
    t.fraud_score,
    CASE
        WHEN random() < 0.30 THEN 'CLOSED'
        WHEN random() < 0.50 THEN 'FALSE_POSITIVE'
        WHEN random() < 0.70 THEN 'INVESTIGATING'
        ELSE 'OPEN'
    END AS status
FROM transactions t
JOIN accounts a ON t.account_id = a.account_id
WHERE t.is_flagged = TRUE
LIMIT 50000;
" > /dev/null

echo -e "${GREEN}✓ Generated alerts for flagged transactions${NC}"

# Generate fraud cases
execute_sql "
INSERT INTO fraud_cases (
    case_number, customer_id, account_id, fraud_type_id,
    detection_date, detection_method, amount_lost, status, priority
)
SELECT
    'CASE' || LPAD(ROW_NUMBER() OVER (ORDER BY a.alert_id)::TEXT, 10, '0') AS case_number,
    a.customer_id,
    a.account_id,
    ((a.alert_id % 20) + 1) AS fraud_type_id,
    a.alert_date AS detection_date,
    CASE
        WHEN random() < 0.70 THEN 'AUTOMATED'
        WHEN random() < 0.85 THEN 'MANUAL_REVIEW'
        ELSE 'CUSTOMER_REPORT'
    END AS detection_method,
    (random() * 50000)::DECIMAL(15,2) AS amount_lost,
    CASE
        WHEN random() < 0.40 THEN 'RESOLVED'
        WHEN random() < 0.60 THEN 'INVESTIGATING'
        ELSE 'OPEN'
    END AS status,
    CASE
        WHEN a.severity = 'CRITICAL' THEN 'CRITICAL'
        WHEN a.severity = 'HIGH' THEN 'HIGH'
        ELSE 'MEDIUM'
    END AS priority
FROM alerts a
WHERE a.status = 'CONFIRMED_FRAUD'
   OR (a.severity IN ('CRITICAL', 'HIGH') AND random() < 0.20)
LIMIT 5000;
" > /dev/null

echo -e "${GREEN}✓ Generated fraud cases${NC}"
echo ""

# Final statistics
echo -e "${BLUE}============================================================================${NC}"
echo -e "${GREEN}✓ Data generation completed successfully!${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo ""
echo -e "${YELLOW}Database Statistics:${NC}"

customer_count=$(execute_sql "SELECT COUNT(*) FROM customers;" | grep -E '^\s*[0-9]+' | tr -d ' ')
echo -e "Customers: ${GREEN}$customer_count${NC}"

account_count=$(execute_sql "SELECT COUNT(*) FROM accounts;" | grep -E '^\s*[0-9]+' | tr -d ' ')
echo -e "Accounts: ${GREEN}$account_count${NC}"

merchant_count=$(execute_sql "SELECT COUNT(*) FROM merchants;" | grep -E '^\s*[0-9]+' | tr -d ' ')
echo -e "Merchants: ${GREEN}$merchant_count${NC}"

card_count=$(execute_sql "SELECT COUNT(*) FROM cards;" | grep -E '^\s*[0-9]+' | tr -d ' ')
echo -e "Cards: ${GREEN}$card_count${NC}"

transaction_count=$(execute_sql "SELECT COUNT(*) FROM transactions;" | grep -E '^\s*[0-9]+' | tr -d ' ')
echo -e "Transactions: ${GREEN}$transaction_count${NC}"

alert_count=$(execute_sql "SELECT COUNT(*) FROM alerts;" | grep -E '^\s*[0-9]+' | tr -d ' ')
echo -e "Alerts: ${GREEN}$alert_count${NC}"

case_count=$(execute_sql "SELECT COUNT(*) FROM fraud_cases;" | grep -E '^\s*[0-9]+' | tr -d ' ')
echo -e "Fraud Cases: ${GREEN}$case_count${NC}"

echo ""
echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}Generating Analytics Data (Customer, Sales, KPIs)${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo ""

# ============================================================================
# GENERATE CUSTOMER ANALYTICS DATA
# ============================================================================

echo -e "${YELLOW}[10/15] Generating Customer Lifetime Value data...${NC}"
cat > /tmp/generate_clv.sql << 'EOF'
-- Generate CLV for all customers based on their transaction history
INSERT INTO customer_lifetime_value (
    customer_id, calculation_date, total_revenue, total_transactions,
    average_order_value, predicted_future_value, clv_score, segment_id
)
SELECT
    c.customer_id,
    CURRENT_DATE as calculation_date,
    COALESCE(SUM(t.amount), 0) as total_revenue,
    COUNT(t.transaction_id) as total_transactions,
    COALESCE(AVG(t.amount), 0) as average_order_value,
    COALESCE(SUM(t.amount) * 1.5, 0) as predicted_future_value,
    COALESCE(SUM(t.amount) / 100, 0) as clv_score,
    CASE
        WHEN COALESCE(SUM(t.amount), 0) >= 50000 THEN 1  -- VIP
        WHEN COALESCE(SUM(t.amount), 0) >= 10000 THEN 2  -- High Value
        WHEN COALESCE(SUM(t.amount), 0) >= 2000 THEN 3   -- Medium Value
        WHEN COALESCE(SUM(t.amount), 0) >= 500 THEN 4    -- Low Value
        ELSE 6  -- New Customer
    END as segment_id
FROM customers c
LEFT JOIN accounts a ON c.customer_id = a.customer_id
LEFT JOIN transactions t ON a.account_id = t.account_id
GROUP BY c.customer_id;
EOF

execute_sql_file /tmp/generate_clv.sql > /dev/null
echo -e "${GREEN}✓ Generated CLV for all customers${NC}"
echo ""

echo -e "${YELLOW}[11/15] Generating Churn Predictions...${NC}"
cat > /tmp/generate_churn.sql << 'EOF'
-- Generate churn predictions based on transaction recency
INSERT INTO churn_predictions (
    customer_id, prediction_date, churn_probability, risk_level,
    last_transaction_date, days_since_last_transaction, engagement_score
)
SELECT
    c.customer_id,
    CURRENT_DATE as prediction_date,
    CASE
        WHEN MAX(t.transaction_date) IS NULL THEN 90
        WHEN CURRENT_DATE - MAX(t.transaction_date) > 180 THEN 85
        WHEN CURRENT_DATE - MAX(t.transaction_date) > 90 THEN 60
        WHEN CURRENT_DATE - MAX(t.transaction_date) > 30 THEN 30
        ELSE 10
    END as churn_probability,
    CASE
        WHEN MAX(t.transaction_date) IS NULL THEN 'HIGH'
        WHEN CURRENT_DATE - MAX(t.transaction_date) > 180 THEN 'CRITICAL'
        WHEN CURRENT_DATE - MAX(t.transaction_date) > 90 THEN 'HIGH'
        WHEN CURRENT_DATE - MAX(t.transaction_date) > 30 THEN 'MEDIUM'
        ELSE 'LOW'
    END as risk_level,
    MAX(t.transaction_date) as last_transaction_date,
    COALESCE(CURRENT_DATE - MAX(t.transaction_date), 999) as days_since_last_transaction,
    CASE
        WHEN MAX(t.transaction_date) IS NULL THEN 0
        WHEN CURRENT_DATE - MAX(t.transaction_date) > 180 THEN 10
        WHEN CURRENT_DATE - MAX(t.transaction_date) > 90 THEN 30
        WHEN CURRENT_DATE - MAX(t.transaction_date) > 30 THEN 60
        ELSE 90
    END as engagement_score
FROM customers c
LEFT JOIN accounts a ON c.customer_id = a.customer_id
LEFT JOIN transactions t ON a.account_id = t.account_id
GROUP BY c.customer_id;
EOF

execute_sql_file /tmp/generate_churn.sql > /dev/null
echo -e "${GREEN}✓ Generated churn predictions${NC}"
echo ""

echo -e "${YELLOW}[12/15] Generating Customer Satisfaction data...${NC}"
cat > /tmp/generate_satisfaction.sql << 'EOF'
-- Generate satisfaction scores for random sample of customers
INSERT INTO customer_satisfaction (
    customer_id, survey_date, nps_score, csat_score, category, sentiment
)
SELECT
    customer_id,
    TIMESTAMP '2023-01-01' + (random() * 730)::INT * INTERVAL '1 day' as survey_date,
    (random() * 200 - 100)::INT as nps_score,
    (1 + random() * 4)::DECIMAL(3,2) as csat_score,
    CASE (random() * 5)::INT
        WHEN 0 THEN 'PRODUCT'
        WHEN 1 THEN 'SERVICE'
        WHEN 2 THEN 'SUPPORT'
        WHEN 3 THEN 'BILLING'
        ELSE 'OTHER'
    END as category,
    CASE
        WHEN random() < 0.6 THEN 'POSITIVE'
        WHEN random() < 0.85 THEN 'NEUTRAL'
        ELSE 'NEGATIVE'
    END as sentiment
FROM customers
WHERE random() < 0.3  -- 30% of customers have satisfaction data
LIMIT 30000;
EOF

execute_sql_file /tmp/generate_satisfaction.sql > /dev/null
echo -e "${GREEN}✓ Generated ~30,000 satisfaction records${NC}"
echo ""

# ============================================================================
# GENERATE SALES ANALYTICS DATA
# ============================================================================

echo -e "${YELLOW}[13/15] Generating Sales Transactions...${NC}"
cat > /tmp/generate_sales.sql << 'EOF'
-- Link transactions to products
INSERT INTO sales_transactions (
    transaction_id, product_id, quantity, unit_price, discount_amount,
    tax_amount, total_amount, sale_date, sales_channel, region
)
SELECT
    t.transaction_id,
    ((t.transaction_id % 24) + 1) as product_id,  -- Cycle through 24 products
    (1 + (random() * 3)::INT) as quantity,
    t.amount / (1 + (random() * 3)::INT) as unit_price,
    CASE WHEN random() < 0.2 THEN t.amount * 0.1 ELSE 0 END as discount_amount,
    t.amount * 0.08 as tax_amount,
    t.amount as total_amount,
    t.transaction_date as sale_date,
    CASE (t.transaction_id % 4)
        WHEN 0 THEN 'ONLINE'
        WHEN 1 THEN 'STORE'
        WHEN 2 THEN 'PHONE'
        ELSE 'MOBILE_APP'
    END as sales_channel,
    CASE (t.transaction_id % 5)
        WHEN 0 THEN 'Northeast'
        WHEN 1 THEN 'Southeast'
        WHEN 2 THEN 'Midwest'
        WHEN 3 THEN 'Southwest'
        ELSE 'West'
    END as region
FROM transactions t
WHERE t.status = 'COMPLETED'
LIMIT 1000000;  -- Link 1M transactions to products
EOF

execute_sql_file /tmp/generate_sales.sql > /dev/null
echo -e "${GREEN}✓ Generated 1,000,000 sales transaction records${NC}"
echo ""

# ============================================================================
# GENERATE KPI & METRICS DATA
# ============================================================================

echo -e "${YELLOW}[14/15] Generating Daily Metrics...${NC}"
cat > /tmp/generate_metrics.sql << 'EOF'
-- Generate daily metrics for the past 90 days
INSERT INTO daily_metrics (
    metric_date, kpi_id, metric_value, vs_previous_day_percentage, status
)
SELECT
    date_series.metric_date,
    kpi.kpi_id,
    kpi.target_value * (0.8 + random() * 0.4) as metric_value,
    (-20 + random() * 40)::DECIMAL(5,2) as vs_previous_day_percentage,
    CASE
        WHEN random() < 0.7 THEN 'ON_TARGET'
        WHEN random() < 0.9 THEN 'WARNING'
        ELSE 'CRITICAL'
    END as status
FROM generate_series(
    CURRENT_DATE - INTERVAL '90 days',
    CURRENT_DATE,
    INTERVAL '1 day'
) AS date_series(metric_date)
CROSS JOIN kpi_definitions kpi
WHERE kpi.is_active = TRUE;
EOF

execute_sql_file /tmp/generate_metrics.sql > /dev/null
echo -e "${GREEN}✓ Generated 90 days of daily metrics${NC}"
echo ""

echo -e "${YELLOW}[15/15] Generating Monthly Summaries...${NC}"
cat > /tmp/generate_monthly.sql << 'EOF'
-- Generate monthly summaries for the past 24 months
INSERT INTO monthly_summaries (
    summary_month, summary_year, total_revenue, total_transactions,
    total_customers, new_customers, average_transaction_value
)
SELECT
    EXTRACT(MONTH FROM month_series)::INT as summary_month,
    EXTRACT(YEAR FROM month_series)::INT as summary_year,
    (10000000 + random() * 5000000)::DECIMAL(15,2) as total_revenue,
    (50000 + (random() * 30000)::INT) as total_transactions,
    (80000 + (random() * 20000)::INT) as total_customers,
    (500 + (random() * 1500)::INT) as new_customers,
    (100 + random() * 100)::DECIMAL(15,2) as average_transaction_value
FROM generate_series(
    CURRENT_DATE - INTERVAL '24 months',
    CURRENT_DATE,
    INTERVAL '1 month'
) AS month_series;
EOF

execute_sql_file /tmp/generate_monthly.sql > /dev/null
echo -e "${GREEN}✓ Generated 24 months of summaries${NC}"
echo ""

echo -e "${BLUE}============================================================================${NC}"
echo -e "${GREEN}Data Generation Complete!${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo ""
echo -e "${YELLOW}Database Statistics:${NC}"

customer_count=$(execute_sql "SELECT COUNT(*) FROM customers;" | grep -E '^\s*[0-9]+' | tr -d ' ')
echo -e "Customers: ${GREEN}$customer_count${NC}"

account_count=$(execute_sql "SELECT COUNT(*) FROM accounts;" | grep -E '^\s*[0-9]+' | tr -d ' ')
echo -e "Accounts: ${GREEN}$account_count${NC}"

merchant_count=$(execute_sql "SELECT COUNT(*) FROM merchants;" | grep -E '^\s*[0-9]+' | tr -d ' ')
echo -e "Merchants: ${GREEN}$merchant_count${NC}"

card_count=$(execute_sql "SELECT COUNT(*) FROM cards;" | grep -E '^\s*[0-9]+' | tr -d ' ')
echo -e "Cards: ${GREEN}$card_count${NC}"

transaction_count=$(execute_sql "SELECT COUNT(*) FROM transactions;" | grep -E '^\s*[0-9]+' | tr -d ' ')
echo -e "Transactions: ${GREEN}$transaction_count${NC}"

alert_count=$(execute_sql "SELECT COUNT(*) FROM alerts;" | grep -E '^\s*[0-9]+' | tr -d ' ')
echo -e "Alerts: ${GREEN}$alert_count${NC}"

case_count=$(execute_sql "SELECT COUNT(*) FROM fraud_cases;" | grep -E '^\s*[0-9]+' | tr -d ' ')
echo -e "Fraud Cases: ${GREEN}$case_count${NC}"

clv_count=$(execute_sql "SELECT COUNT(*) FROM customer_lifetime_value;" | grep -E '^\s*[0-9]+' | tr -d ' ')
echo -e "Customer CLV Records: ${GREEN}$clv_count${NC}"

sales_count=$(execute_sql "SELECT COUNT(*) FROM sales_transactions;" | grep -E '^\s*[0-9]+' | tr -d ' ')
echo -e "Sales Records: ${GREEN}$sales_count${NC}"

metrics_count=$(execute_sql "SELECT COUNT(*) FROM daily_metrics;" | grep -E '^\s*[0-9]+' | tr -d ' ')
echo -e "Daily Metrics: ${GREEN}$metrics_count${NC}"

echo ""
echo -e "${YELLOW}Ready for Business Analytics and SQL learning!${NC}"
echo -e "Access DB-UI at: ${BLUE}http://localhost:3000${NC}"
echo ""

