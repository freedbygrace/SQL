#!/bin/bash

# ============================================================================
# Business Analytics Database - Master Deployment Script
# ============================================================================
# This script does EVERYTHING in one command:
# 1. Tears down existing containers
# 2. Removes all data volumes
# 3. Fixes permissions
# 4. Starts containers
# 5. Initializes database schema
# 6. Generates test data
# 7. Verifies everything works
#
# IDEMPOTENT: Safe to run multiple times - will rebuild from scratch
# ============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo ""
echo -e "${MAGENTA}╔════════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║                                                                            ║${NC}"
echo -e "${MAGENTA}║         ${CYAN}Business Analytics Database - Master Deployment${MAGENTA}                ║${NC}"
echo -e "${MAGENTA}║                                                                            ║${NC}"
echo -e "${MAGENTA}╚════════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}This script will:${NC}"
echo -e "  ${BLUE}1.${NC} Tear down existing containers"
echo -e "  ${BLUE}2.${NC} Remove all data volumes"
echo -e "  ${BLUE}3.${NC} Check and install dependencies (Python, psql, Docker)"
echo -e "  ${BLUE}4.${NC} Fix file permissions"
echo -e "  ${BLUE}5.${NC} Start fresh containers"
echo -e "  ${BLUE}6.${NC} Initialize database schema"
echo -e "  ${BLUE}7.${NC} Generate test data"
echo -e "  ${BLUE}8.${NC} Verify deployment"
echo ""
echo -e "${YELLOW}⚠️  WARNING: This will DELETE all existing data!${NC}"
echo ""
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Deployment cancelled.${NC}"
    exit 0
fi

echo ""
echo -e "${MAGENTA}════════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}[STEP 1/7] Tearing down existing containers...${NC}"
echo -e "${MAGENTA}════════════════════════════════════════════════════════════════════════════${NC}"
echo ""

if command -v docker-compose >/dev/null 2>&1; then
    docker-compose down -v 2>/dev/null || true
    echo -e "${GREEN}✓ Containers stopped and removed${NC}"
else
    echo -e "${YELLOW}⚠ docker-compose not found, skipping...${NC}"
fi

echo ""
echo -e "${MAGENTA}════════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}[STEP 2/7] Removing data volumes...${NC}"
echo -e "${MAGENTA}════════════════════════════════════════════════════════════════════════════${NC}"
echo ""

if command -v docker >/dev/null 2>&1; then
    # Remove named volumes
    docker volume rm sql_postgres_data 2>/dev/null && echo -e "${GREEN}✓ Removed postgres_data volume${NC}" || echo -e "${YELLOW}⚠ postgres_data volume not found${NC}"
    docker volume rm sql_pgadmin_data 2>/dev/null && echo -e "${GREEN}✓ Removed pgadmin_data volume${NC}" || echo -e "${YELLOW}⚠ pgadmin_data volume not found${NC}"
else
    echo -e "${YELLOW}⚠ docker not found, skipping...${NC}"
fi

echo ""
echo -e "${MAGENTA}════════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}[STEP 3/7] Checking dependencies...${NC}"
echo -e "${MAGENTA}════════════════════════════════════════════════════════════════════════════${NC}"
echo ""

# Check for required dependencies
MISSING_DEPS=()

if ! command -v python3 >/dev/null 2>&1; then
    MISSING_DEPS+=("python3")
fi

if ! command -v psql >/dev/null 2>&1; then
    MISSING_DEPS+=("psql")
fi

if ! command -v docker >/dev/null 2>&1; then
    MISSING_DEPS+=("docker")
fi

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo -e "${YELLOW}⚠ Missing dependencies: ${MISSING_DEPS[*]}${NC}"
    echo -e "${YELLOW}Running dependency installer...${NC}"
    echo ""
    chmod +x scripts/install-dependencies.sh 2>/dev/null || true
    ./scripts/install-dependencies.sh
else
    echo -e "${GREEN}✓ All dependencies are installed${NC}"
fi

echo ""
echo -e "${MAGENTA}════════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}[STEP 4/7] Fixing file permissions...${NC}"
echo -e "${MAGENTA}════════════════════════════════════════════════════════════════════════════${NC}"
echo ""

# Make fix-permissions script executable first
chmod +x scripts/fix-permissions.sh 2>/dev/null || true

# Run the fix-permissions script
if [ -f "scripts/fix-permissions.sh" ]; then
    ./scripts/fix-permissions.sh
else
    # Fallback if script doesn't exist
    echo -e "${YELLOW}Running fallback permission fix...${NC}"
    if command -v sudo >/dev/null 2>&1 && [ "$EUID" -ne 0 ]; then
        sudo chown -R $USER:$USER . 2>/dev/null || true
    fi
    find . -name "*.sh" -type f -exec chmod +x {} \; 2>/dev/null || true
    chmod -R 755 data/ schema/ scripts/ 2>/dev/null || true
    echo -e "${GREEN}✓ Permissions fixed${NC}"
fi

echo ""
echo -e "${MAGENTA}════════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}[STEP 5/8] Starting containers...${NC}"
echo -e "${MAGENTA}════════════════════════════════════════════════════════════════════════════${NC}"
echo ""

# Start containers without waiting for health checks (pgAdmin takes longer)
docker-compose up -d --no-deps postgres
echo -e "${GREEN}✓ PostgreSQL container started${NC}"

echo ""
echo -e "${YELLOW}Waiting for PostgreSQL to be ready...${NC}"
sleep 5

# Wait for PostgreSQL to be healthy
MAX_WAIT=120
WAITED=0
while [ $WAITED -lt $MAX_WAIT ]; do
    if docker exec business_analytics_db pg_isready -U data_analyst -d business_analytics >/dev/null 2>&1; then
        echo -e "${GREEN}✓ PostgreSQL is ready!${NC}"
        break
    fi
    echo -e "${YELLOW}  Waiting... ($WAITED/$MAX_WAIT seconds)${NC}"
    sleep 5
    WAITED=$((WAITED + 5))
done

if [ $WAITED -ge $MAX_WAIT ]; then
    echo -e "${RED}✗ PostgreSQL failed to start within $MAX_WAIT seconds${NC}"
    echo -e "${YELLOW}Check logs with: docker-compose logs postgres${NC}"
    exit 1
fi

# Now start pgAdmin (doesn't block database operations)
echo ""
echo -e "${YELLOW}Starting pgAdmin...${NC}"
docker-compose up -d pgadmin
echo -e "${GREEN}✓ pgAdmin container started${NC}"
echo -e "${YELLOW}Note: pgAdmin may take 30-60 seconds to fully initialize${NC}"

echo ""
echo -e "${MAGENTA}════════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}[STEP 6/8] Initializing database schema...${NC}"
echo -e "${MAGENTA}════════════════════════════════════════════════════════════════════════════${NC}"
echo ""

./scripts/setup-database.sh

echo ""
echo -e "${MAGENTA}════════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}[STEP 7/8] Generating test data...${NC}"
echo -e "${MAGENTA}════════════════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}⏱️  This will take 2-5 minutes depending on your system...${NC}"
echo ""

# Generate CSV files using Python
echo -e "${CYAN}Generating CSV files...${NC}"
python3 scripts/generate_csv_data.py
if [ $? -ne 0 ]; then
    echo -e "${RED}✗ CSV generation failed${NC}"
    exit 1
fi

echo ""
echo -e "${CYAN}Importing CSV data into PostgreSQL...${NC}"
chmod +x scripts/import_csv_data.sh
./scripts/import_csv_data.sh
if [ $? -ne 0 ]; then
    echo -e "${RED}✗ CSV import failed${NC}"
    exit 1
fi

echo ""
echo -e "${MAGENTA}════════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}[STEP 8/8] Verifying deployment...${NC}"
echo -e "${MAGENTA}════════════════════════════════════════════════════════════════════════════${NC}"
echo ""

./scripts/verify-setup.sh

echo ""
echo -e "${MAGENTA}╔════════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║                                                                            ║${NC}"
echo -e "${MAGENTA}║                    ${GREEN}✓ DEPLOYMENT COMPLETE!${MAGENTA}                                ║${NC}"
echo -e "${MAGENTA}║                                                                            ║${NC}"
echo -e "${MAGENTA}╚════════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Your Business Analytics Database is ready!${NC}"
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Access Information:${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}📊 pgAdmin Web Interface:${NC}"
echo -e "   URL:      ${GREEN}http://localhost:3000${NC}"
echo -e "   Email:    ${GREEN}admin@example.com${NC}"
echo -e "   Password: ${GREEN}SecurePass123!${NC}"
echo -e "   ${YELLOW}Note: pgAdmin may take 30-60 seconds to fully start${NC}"
echo ""
echo -e "${BLUE}🗄️  PostgreSQL Database:${NC}"
echo -e "   Host:     ${GREEN}localhost${NC}"
echo -e "   Port:     ${GREEN}5432${NC}"
echo -e "   Database: ${GREEN}business_analytics${NC}"
echo -e "   Username: ${GREEN}data_analyst${NC}"
echo -e "   Password: ${GREEN}SecurePass123!${NC}"
echo ""
echo -e "${BLUE}💻 Command Line Access:${NC}"
echo -e "   ${GREEN}psql -h localhost -p 5432 -U data_analyst -d business_analytics${NC}"
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Next Steps:${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${BLUE}1.${NC} Open pgAdmin: ${GREEN}http://localhost:3000${NC}"
echo -e "  ${BLUE}2.${NC} Add server connection (see credentials above)"
echo -e "  ${BLUE}3.${NC} Explore the exercises: ${GREEN}./exercises/${NC}"
echo -e "     - ${CYAN}01-fraud-detection/${NC} - Fraud analysis queries"
echo -e "     - ${CYAN}02-customer-analytics/${NC} - Customer insights"
echo -e "     - ${CYAN}03-sales-analysis/${NC} - Sales performance"
echo -e "     - ${CYAN}04-kpi-dashboards/${NC} - KPI tracking"
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Useful Commands:${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${BLUE}Check pgAdmin status:${NC}  ${GREEN}docker logs business_analytics_ui${NC}"
echo -e "  ${BLUE}View all logs:${NC}         ${GREEN}docker-compose logs -f${NC}"
echo -e "  ${BLUE}Stop containers:${NC}       ${GREEN}docker-compose down${NC}"
echo -e "  ${BLUE}Restart containers:${NC}    ${GREEN}docker-compose restart${NC}"
echo -e "  ${BLUE}Redeploy everything:${NC}   ${GREEN}./deploy.sh${NC}"
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Troubleshooting:${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${BLUE}If pgAdmin shows 'connection refused':${NC}"
echo -e "    - Wait 30-60 seconds for pgAdmin to fully initialize"
echo -e "    - Check status: ${GREEN}docker logs business_analytics_ui${NC}"
echo -e "    - Look for: ${GREEN}'Listening at: http://[::]:80'${NC}"
echo ""
echo -e "${GREEN}Happy learning! 🚀${NC}"
echo ""

