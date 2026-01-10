#!/bin/bash
# =============================================================================
# DATABASE INITIALIZATION SCRIPT
# =============================================================================
#
# This script initializes the database with:
# - Alembic migrations
# - Default roles and ranks
# - Admin user
#
# Usage:
#   ./scripts/init-db.sh              # Interactive mode (prompts for admin credentials)
#   ./scripts/init-db.sh --auto       # Non-interactive mode (uses env vars or defaults)
#
# Environment variables for --auto mode:
#   ADMIN_USERNAME   - Admin username (default: admin)
#   ADMIN_EMAIL      - Admin email (default: admin@example.com)
#   ADMIN_PASSWORD   - Admin password (default: admin123)
#   ADMIN_FULL_NAME  - Admin full name (default: Administrator)
#
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Parse arguments
AUTO_MODE=false
DOCKER_MODE=false

for arg in "$@"; do
    case $arg in
        --auto)
            AUTO_MODE=true
            shift
            ;;
        --docker)
            DOCKER_MODE=true
            shift
            ;;
        *)
            ;;
    esac
done

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    DATABASE INITIALIZATION                      ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check if running with Docker
if [ "$DOCKER_MODE" = true ]; then
    echo -e "${YELLOW}[!] Running in Docker mode${NC}"
    BACKEND_CONTAINER="kgr33n-backend"
    
    # Check if container is running
    if ! docker ps | grep -q "$BACKEND_CONTAINER"; then
        echo -e "${RED}[✗] Backend container not running!${NC}"
        echo -e "${YELLOW}    Start it with: ./scripts/dev.sh${NC}"
        exit 1
    fi
    
    # Wait for database to be ready
    echo -e "${BLUE}[*] Waiting for database connection...${NC}"
    sleep 2
    
    # Run Alembic migrations in container
    echo -e "${BLUE}[*] Running Alembic migrations...${NC}"
    docker exec "$BACKEND_CONTAINER" alembic upgrade head
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[✓] Migrations applied successfully${NC}"
    else
        echo -e "${RED}[✗] Migration failed!${NC}"
        exit 1
    fi
    
    # Run admin creation script
    echo -e "${BLUE}[*] Initializing database with default data...${NC}"
    
    if [ "$AUTO_MODE" = true ]; then
        # Set env vars for non-interactive mode
        ADMIN_USERNAME="${ADMIN_USERNAME:-admin}"
        ADMIN_EMAIL="${ADMIN_EMAIL:-admin@example.com}"
        ADMIN_PASSWORD="${ADMIN_PASSWORD:-admin123}"
        ADMIN_FULL_NAME="${ADMIN_FULL_NAME:-Administrator}"
        
        docker exec -e ADMIN_USERNAME="$ADMIN_USERNAME" \
                    -e ADMIN_EMAIL="$ADMIN_EMAIL" \
                    -e ADMIN_PASSWORD="$ADMIN_PASSWORD" \
                    -e ADMIN_FULL_NAME="$ADMIN_FULL_NAME" \
                    "$BACKEND_CONTAINER" python -m app.create_admin
    else
        docker exec -it "$BACKEND_CONTAINER" python -m app.create_admin
    fi
    
    # Sync posts
    echo -e "${BLUE}[*] Synchronizing blog posts from markdown...${NC}"
    docker exec "$BACKEND_CONTAINER" python -m app.scripts.sync_posts
    
else
    # Local mode (run directly in Python environment)
    echo -e "${YELLOW}[!] Running in local mode${NC}"
    
    cd "$PROJECT_ROOT/backend"
    
    # Check if virtual environment exists
    if [ ! -d ".venv" ] && [ ! -d "venv" ]; then
        echo -e "${YELLOW}[!] No virtual environment found, using system Python${NC}"
    else
        # Activate virtual environment
        if [ -d ".venv" ]; then
            source .venv/bin/activate
        elif [ -d "venv" ]; then
            source venv/bin/activate
        fi
    fi
    
    # Check if .env exists
    if [ ! -f ".env" ]; then
        echo -e "${RED}[✗] .env file not found!${NC}"
        echo -e "${YELLOW}    Create from template: cp .env.example .env${NC}"
        exit 1
    fi
    
    # Run Alembic migrations
    echo -e "${BLUE}[*] Running Alembic migrations...${NC}"
    alembic upgrade head
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[✓] Migrations applied successfully${NC}"
    else
        echo -e "${RED}[✗] Migration failed!${NC}"
        exit 1
    fi
    
    # Run admin creation script
    echo -e "${BLUE}[*] Initializing database with default data...${NC}"
    
    if [ "$AUTO_MODE" = true ]; then
        export ADMIN_USERNAME="${ADMIN_USERNAME:-admin}"
        export ADMIN_EMAIL="${ADMIN_EMAIL:-admin@example.com}"
        export ADMIN_PASSWORD="${ADMIN_PASSWORD:-admin123}"
        export ADMIN_FULL_NAME="${ADMIN_FULL_NAME:-Administrator}"
    fi
    
    python -m app.create_admin
    
    # Sync posts
    echo -e "${BLUE}[*] Synchronizing blog posts from markdown...${NC}"
    export CONTENT_DIR="../frontend/src/content/blog"
    python -m app.scripts.sync_posts
fi

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✓ Database initialization complete!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${BLUE}Initialized:${NC}"
echo -e "    • Alembic migrations applied"
echo -e "    • User roles (User, Moderator, Admin)"
echo -e "    • User ranks (Newbie → VIP)"
echo -e "    • Admin user account"
echo -e "    • Blog posts synced from markdown"
echo ""
