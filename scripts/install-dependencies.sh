#!/bin/bash

# ============================================================================
# Dependency Installation Script
# ============================================================================
# Automatically detects OS and installs required packages:
# - PostgreSQL client (psql)
# - Docker & Docker Compose
# - curl, wget, git (if missing)
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}Business Analytics Database - Dependency Installer${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo ""

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS=$ID
            VER=$VERSION_ID
        else
            OS="unknown"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        OS="windows"
    else
        OS="unknown"
    fi
    
    echo -e "${BLUE}Detected OS: ${GREEN}$OS${NC}"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install PostgreSQL client
install_psql() {
    echo -e "\n${YELLOW}[1/4] Checking PostgreSQL client (psql)...${NC}"
    
    if command_exists psql; then
        PSQL_VERSION=$(psql --version | awk '{print $3}')
        echo -e "${GREEN}✓ psql is already installed (version $PSQL_VERSION)${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}Installing PostgreSQL client...${NC}"
    
    case $OS in
        ubuntu|debian)
            sudo apt-get update
            sudo apt-get install -y postgresql-client
            ;;
        centos|rhel|fedora)
            sudo yum install -y postgresql
            ;;
        arch)
            sudo pacman -S --noconfirm postgresql-libs
            ;;
        macos)
            if command_exists brew; then
                brew install postgresql
            else
                echo -e "${RED}✗ Homebrew not found. Please install Homebrew first: https://brew.sh${NC}"
                exit 1
            fi
            ;;
        windows)
            echo -e "${YELLOW}On Windows, please install PostgreSQL client manually:${NC}"
            echo -e "  1. Download from: https://www.postgresql.org/download/windows/"
            echo -e "  2. Or use WSL2 with Ubuntu"
            echo -e "  3. Or use Docker Desktop (includes psql in containers)"
            exit 1
            ;;
        *)
            echo -e "${RED}✗ Unsupported OS. Please install PostgreSQL client manually.${NC}"
            exit 1
            ;;
    esac
    
    if command_exists psql; then
        echo -e "${GREEN}✓ PostgreSQL client installed successfully${NC}"
    else
        echo -e "${RED}✗ Failed to install PostgreSQL client${NC}"
        exit 1
    fi
}

# Install Docker
install_docker() {
    echo -e "\n${YELLOW}[2/4] Checking Docker...${NC}"
    
    if command_exists docker; then
        DOCKER_VERSION=$(docker --version | awk '{print $3}' | sed 's/,//')
        echo -e "${GREEN}✓ Docker is already installed (version $DOCKER_VERSION)${NC}"
        
        # Check if Docker daemon is running
        if docker ps >/dev/null 2>&1; then
            echo -e "${GREEN}✓ Docker daemon is running${NC}"
        else
            echo -e "${YELLOW}⚠ Docker is installed but daemon is not running${NC}"
            echo -e "${YELLOW}  Please start Docker and try again${NC}"
        fi
        return 0
    fi
    
    echo -e "${YELLOW}Installing Docker...${NC}"
    
    case $OS in
        ubuntu|debian)
            # Install Docker using official script
            curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
            sudo sh /tmp/get-docker.sh
            sudo usermod -aG docker $USER
            echo -e "${YELLOW}⚠ You may need to log out and back in for Docker group membership to take effect${NC}"
            ;;
        centos|rhel|fedora)
            sudo yum install -y yum-utils
            sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            sudo yum install -y docker-ce docker-ce-cli containerd.io
            sudo systemctl start docker
            sudo systemctl enable docker
            sudo usermod -aG docker $USER
            ;;
        macos)
            echo -e "${YELLOW}On macOS, please install Docker Desktop manually:${NC}"
            echo -e "  Download from: https://www.docker.com/products/docker-desktop"
            exit 1
            ;;
        windows)
            echo -e "${YELLOW}On Windows, please install Docker Desktop manually:${NC}"
            echo -e "  Download from: https://www.docker.com/products/docker-desktop"
            exit 1
            ;;
        *)
            echo -e "${RED}✗ Unsupported OS for automatic Docker installation${NC}"
            exit 1
            ;;
    esac
    
    if command_exists docker; then
        echo -e "${GREEN}✓ Docker installed successfully${NC}"
    else
        echo -e "${RED}✗ Failed to install Docker${NC}"
        exit 1
    fi
}

# Install Docker Compose
install_docker_compose() {
    echo -e "\n${YELLOW}[3/4] Checking Docker Compose...${NC}"
    
    # Check for docker-compose (standalone) or docker compose (plugin)
    if command_exists docker-compose || docker compose version >/dev/null 2>&1; then
        if command_exists docker-compose; then
            COMPOSE_VERSION=$(docker-compose --version | awk '{print $3}' | sed 's/,//')
        else
            COMPOSE_VERSION=$(docker compose version --short)
        fi
        echo -e "${GREEN}✓ Docker Compose is already installed (version $COMPOSE_VERSION)${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}Installing Docker Compose...${NC}"
    
    case $OS in
        ubuntu|debian|centos|rhel|fedora)
            # Install Docker Compose plugin
            COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
            sudo curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            sudo chmod +x /usr/local/bin/docker-compose
            ;;
        macos)
            echo -e "${GREEN}✓ Docker Compose is included with Docker Desktop${NC}"
            return 0
            ;;
        windows)
            echo -e "${GREEN}✓ Docker Compose is included with Docker Desktop${NC}"
            return 0
            ;;
        *)
            echo -e "${RED}✗ Unsupported OS for automatic Docker Compose installation${NC}"
            exit 1
            ;;
    esac
    
    if command_exists docker-compose; then
        echo -e "${GREEN}✓ Docker Compose installed successfully${NC}"
    else
        echo -e "${RED}✗ Failed to install Docker Compose${NC}"
        exit 1
    fi
}

# Install utility packages
install_utilities() {
    echo -e "\n${YELLOW}[4/4] Checking utility packages...${NC}"
    
    local missing_packages=()
    
    # Check for required utilities
    if ! command_exists curl; then
        missing_packages+=("curl")
    fi
    
    if ! command_exists wget; then
        missing_packages+=("wget")
    fi
    
    if ! command_exists git; then
        missing_packages+=("git")
    fi
    
    if [ ${#missing_packages[@]} -eq 0 ]; then
        echo -e "${GREEN}✓ All utility packages are installed${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}Installing missing utilities: ${missing_packages[*]}${NC}"
    
    case $OS in
        ubuntu|debian)
            sudo apt-get update
            sudo apt-get install -y "${missing_packages[@]}"
            ;;
        centos|rhel|fedora)
            sudo yum install -y "${missing_packages[@]}"
            ;;
        arch)
            sudo pacman -S --noconfirm "${missing_packages[@]}"
            ;;
        macos)
            if command_exists brew; then
                brew install "${missing_packages[@]}"
            else
                echo -e "${YELLOW}⚠ Some utilities are missing but Homebrew is not installed${NC}"
            fi
            ;;
        *)
            echo -e "${YELLOW}⚠ Cannot automatically install utilities on this OS${NC}"
            ;;
    esac
    
    echo -e "${GREEN}✓ Utility packages installed${NC}"
}

# Main installation flow
main() {
    detect_os
    
    echo -e "\n${BLUE}Starting dependency installation...${NC}"
    echo -e "${YELLOW}This script will install:${NC}"
    echo -e "  - PostgreSQL client (psql)"
    echo -e "  - Docker"
    echo -e "  - Docker Compose"
    echo -e "  - Utility packages (curl, wget, git)"
    echo ""
    echo -e "${YELLOW}Some installations may require sudo privileges.${NC}"
    echo -e "${YELLOW}Press Ctrl+C to cancel, or wait 5 seconds to continue...${NC}"
    sleep 5
    echo ""
    
    install_psql
    install_docker
    install_docker_compose
    install_utilities
    
    echo -e "\n${BLUE}============================================================================${NC}"
    echo -e "${GREEN}✓ All dependencies installed successfully!${NC}"
    echo -e "${BLUE}============================================================================${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo -e "  1. If Docker was just installed, you may need to log out and back in"
    echo -e "  2. Start Docker if it's not running"
    echo -e "  3. Fix permissions: ${GREEN}./scripts/fix-permissions.sh${NC}"
    echo -e "  4. Start containers: ${GREEN}docker-compose up -d${NC}"
    echo -e "  5. Setup database: ${GREEN}./scripts/setup-database.sh${NC}"
    echo -e "  6. Generate data: ${GREEN}./data/generate_data.sh${NC}"
    echo ""
}

main

