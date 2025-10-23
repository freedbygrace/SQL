#!/bin/bash

# ============================================================================
# Fix Permissions Script
# ============================================================================
# Sets proper ownership and permissions for the repository
# This is especially important for Docker bind mounts to work correctly
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}Business Analytics Database - Fix Permissions${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo ""

# Get the script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo -e "${YELLOW}[1/4] Taking ownership of repository...${NC}"
if [ "$EUID" -eq 0 ]; then
    # Running as root - ask for target user
    echo -e "${YELLOW}Running as root. Please specify the target user (or press Enter for current user):${NC}"
    read -r TARGET_USER
    if [ -z "$TARGET_USER" ]; then
        TARGET_USER=$(logname 2>/dev/null || echo $SUDO_USER)
    fi
    chown -R "$TARGET_USER:$TARGET_USER" .
    echo -e "${GREEN}✓ Ownership set to $TARGET_USER${NC}"
else
    # Running as regular user - use sudo
    if command -v sudo >/dev/null 2>&1; then
        sudo chown -R $USER:$USER .
        echo -e "${GREEN}✓ Ownership set to $USER${NC}"
    else
        echo -e "${YELLOW}⚠ sudo not available, skipping ownership change${NC}"
        echo -e "${YELLOW}  You may need to run: chown -R \$USER:\$USER .${NC}"
    fi
fi

echo -e "\n${YELLOW}[2/4] Making all shell scripts executable...${NC}"
SCRIPT_COUNT=$(find . -name "*.sh" -type f | wc -l)
find . -name "*.sh" -type f -exec chmod +x {} \;
echo -e "${GREEN}✓ Made $SCRIPT_COUNT shell scripts executable${NC}"

echo -e "\n${YELLOW}[3/4] Setting directory permissions...${NC}"
# Set proper permissions for directories that Docker will bind mount
if [ -d "data" ]; then
    chmod -R 755 data/
    echo -e "${GREEN}✓ Set permissions for data/ directory${NC}"
fi

if [ -d "schema" ]; then
    chmod -R 755 schema/
    echo -e "${GREEN}✓ Set permissions for schema/ directory${NC}"
fi

if [ -d "scripts" ]; then
    chmod -R 755 scripts/
    echo -e "${GREEN}✓ Set permissions for scripts/ directory${NC}"
fi

if [ -d "docker" ]; then
    chmod -R 755 docker/
    echo -e "${GREEN}✓ Set permissions for docker/ directory${NC}"
fi

if [ -d "exercises" ]; then
    chmod -R 755 exercises/
    echo -e "${GREEN}✓ Set permissions for exercises/ directory${NC}"
fi

if [ -d "docs" ]; then
    chmod -R 755 docs/
    echo -e "${GREEN}✓ Set permissions for docs/ directory${NC}"
fi

echo -e "\n${YELLOW}[4/4] Verifying permissions...${NC}"

# Check if we can read key files
ERRORS=0

if [ ! -r "docker-compose.yml" ]; then
    echo -e "${RED}✗ Cannot read docker-compose.yml${NC}"
    ERRORS=$((ERRORS + 1))
else
    echo -e "${GREEN}✓ docker-compose.yml is readable${NC}"
fi

if [ ! -x "scripts/setup-database.sh" ]; then
    echo -e "${RED}✗ scripts/setup-database.sh is not executable${NC}"
    ERRORS=$((ERRORS + 1))
else
    echo -e "${GREEN}✓ scripts/setup-database.sh is executable${NC}"
fi

if [ ! -x "data/generate_data.sh" ]; then
    echo -e "${RED}✗ data/generate_data.sh is not executable${NC}"
    ERRORS=$((ERRORS + 1))
else
    echo -e "${GREEN}✓ data/generate_data.sh is executable${NC}"
fi

if [ ! -r "schema/01-create-tables.sql" ]; then
    echo -e "${RED}✗ Cannot read schema/01-create-tables.sql${NC}"
    ERRORS=$((ERRORS + 1))
else
    echo -e "${GREEN}✓ schema/01-create-tables.sql is readable${NC}"
fi

echo ""
echo -e "${BLUE}============================================================================${NC}"

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓ All permissions set correctly!${NC}"
    echo -e "${BLUE}============================================================================${NC}"
    echo ""
    echo -e "${GREEN}You can now proceed with:${NC}"
    echo -e "  1. ${YELLOW}docker-compose up -d${NC}          # Start containers"
    echo -e "  2. ${YELLOW}./scripts/setup-database.sh${NC}   # Initialize database"
    echo -e "  3. ${YELLOW}./data/generate_data.sh${NC}       # Generate test data"
    echo ""
else
    echo -e "${RED}✗ Found $ERRORS permission errors${NC}"
    echo -e "${BLUE}============================================================================${NC}"
    echo ""
    echo -e "${YELLOW}Please fix the errors above and try again.${NC}"
    exit 1
fi

