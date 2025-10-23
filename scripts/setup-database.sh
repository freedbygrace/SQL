#!/bin/bash

# ============================================================================
# Database Setup Script - IDEMPOTENT
# ============================================================================
# This script sets up the complete business analytics database
# It can be run multiple times safely - it will recreate everything
# ============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration from environment or defaults
DB_HOST="${POSTGRES_HOST:-localhost}"
DB_PORT="${POSTGRES_PORT:-5432}"
DB_NAME="${POSTGRES_DB:-business_analytics}"
DB_USER="${POSTGRES_USER:-data_analyst}"
DB_PASSWORD="${POSTGRES_PASSWORD:-SecurePass123!}"

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}Business Analytics Database - Setup Script${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo -e "Database: ${GREEN}$DB_NAME${NC}"
echo -e "Host: ${GREEN}$DB_HOST:$DB_PORT${NC}"
echo -e "User: ${GREEN}$DB_USER${NC}"
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

    # Check for docker-compose or docker compose
    if ! command -v docker-compose >/dev/null 2>&1 && ! docker compose version >/dev/null 2>&1; then
        missing_deps+=("docker-compose")
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
            if [ -f "$SCRIPT_DIR/install-dependencies.sh" ]; then
                chmod +x "$SCRIPT_DIR/install-dependencies.sh"
                "$SCRIPT_DIR/install-dependencies.sh"
                echo ""
                echo -e "${GREEN}Dependencies installed. Please re-run this script.${NC}"
                exit 0
            else
                echo -e "${RED}✗ install-dependencies.sh not found${NC}"
                echo -e "${YELLOW}Please install the following manually:${NC}"
                for dep in "${missing_deps[@]}"; do
                    echo -e "  - $dep"
                done
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

# Function to execute SQL command
execute_sql() {
    PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "$1" 2>&1
}

# Function to execute SQL file
execute_sql_file() {
    local file=$1
    local description=$2
    echo -e "${YELLOW}Executing: $description${NC}"
    PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f "$file" 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Success: $description${NC}"
    else
        echo -e "${RED}✗ Failed: $description${NC}"
        exit 1
    fi
    echo ""
}

# Wait for PostgreSQL to be ready
echo -e "${YELLOW}Waiting for PostgreSQL to be ready...${NC}"
max_attempts=30
attempt=0
until PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c '\q' 2>/dev/null; do
    attempt=$((attempt + 1))
    if [ $attempt -ge $max_attempts ]; then
        echo -e "${RED}✗ PostgreSQL is not available after $max_attempts attempts${NC}"
        exit 1
    fi
    echo -e "${YELLOW}Waiting for PostgreSQL... (attempt $attempt/$max_attempts)${NC}"
    sleep 2
done
echo -e "${GREEN}✓ PostgreSQL is ready${NC}"
echo ""

# Step 1: Create schema (drops and recreates all tables)
echo -e "${BLUE}[Step 1/3] Creating database schema...${NC}"
execute_sql_file "$PROJECT_ROOT/schema/01-create-tables.sql" "Creating tables, indexes, and constraints"

# Step 2: Load seed data (reference tables)
echo -e "${BLUE}[Step 2/3] Loading reference data...${NC}"
execute_sql_file "$PROJECT_ROOT/schema/02-seed-data.sql" "Loading countries, merchant categories, transaction types, and fraud types"

# Step 3: Verify setup
echo -e "${BLUE}[Step 3/3] Verifying database setup...${NC}"
echo -e "${YELLOW}Checking table counts...${NC}"

# Get table counts
table_count=$(execute_sql "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE';" | grep -E '^\s*[0-9]+' | tr -d ' ')
echo -e "Tables created: ${GREEN}$table_count${NC}"

# Get reference data counts
country_count=$(execute_sql "SELECT COUNT(*) FROM countries;" | grep -E '^\s*[0-9]+' | tr -d ' ')
echo -e "Countries: ${GREEN}$country_count${NC}"

category_count=$(execute_sql "SELECT COUNT(*) FROM merchant_categories;" | grep -E '^\s*[0-9]+' | tr -d ' ')
echo -e "Merchant categories: ${GREEN}$category_count${NC}"

transaction_type_count=$(execute_sql "SELECT COUNT(*) FROM transaction_types;" | grep -E '^\s*[0-9]+' | tr -d ' ')
echo -e "Transaction types: ${GREEN}$transaction_type_count${NC}"

fraud_type_count=$(execute_sql "SELECT COUNT(*) FROM fraud_types;" | grep -E '^\s*[0-9]+' | tr -d ' ')
echo -e "Fraud types: ${GREEN}$fraud_type_count${NC}"

echo ""
echo -e "${GREEN}============================================================================${NC}"
echo -e "${GREEN}✓ Database setup completed successfully!${NC}"
echo -e "${GREEN}============================================================================${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "1. Generate test data: ${BLUE}./scripts/generate-data.sh${NC}"
echo -e "2. Access DB-UI at: ${BLUE}http://localhost:3000${NC}"
echo -e "3. Start learning SQL with exercises in: ${BLUE}./exercises/${NC}"
echo ""

