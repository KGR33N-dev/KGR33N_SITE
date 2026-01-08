#!/bin/bash
# =============================================================================
# DEV SCRIPT - Local Development Helper
# =============================================================================
#
# Usage:
#   ./scripts/dev.sh          # Start all services
#   ./scripts/dev.sh up       # Start all services (alias)
#   ./scripts/dev.sh down     # Stop all services
#   ./scripts/dev.sh restart  # Restart all services
#   ./scripts/dev.sh logs     # View logs (follow)
#   ./scripts/dev.sh shell    # Enter backend container
#   ./scripts/dev.sh db       # Enter PostgreSQL shell
#   ./scripts/dev.sh clean    # Remove all containers and volumes
#   ./scripts/dev.sh status   # Check service status
#   ./scripts/dev.sh build    # Rebuild images
#
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project root (directory containing this script's parent)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

# Functions
print_header() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                    KGR33N DEV ENVIRONMENT                       ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed!"
        exit 1
    fi
    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running!"
        exit 1
    fi
}

wait_for_services() {
    echo ""
    print_warn "Waiting for services to be healthy..."
    sleep 5
    
    # Wait for postgres
    echo -n "  PostgreSQL: "
    until docker-compose exec -T postgres pg_isready -U kgr33n &> /dev/null; do
        echo -n "."
        sleep 2
    done
    echo -e " ${GREEN}Ready${NC}"
    
    # Wait for backend
    echo -n "  Backend:    "
    until curl -sf http://localhost:8080/api/health &> /dev/null; do
        echo -n "."
        sleep 2
    done
    echo -e " ${GREEN}Ready${NC}"
    
    # Wait for frontend
    echo -n "  Frontend:   "
    until curl -sf http://localhost:4321 &> /dev/null; do
        echo -n "."
        sleep 2
    done
    echo -e " ${GREEN}Ready${NC}"
}

show_urls() {
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "  ${GREEN}✓ All services are running!${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "  🌐 Frontend:    http://localhost:4321"
    echo "  🔧 Backend API: http://localhost:8080/api"
    echo "  📊 API Docs:    http://localhost:8080/docs"
    echo "  🗄️  PostgreSQL: localhost:5432"
    echo ""
    echo "  📋 Commands:"
    echo "     ./scripts/dev.sh logs    - View logs"
    echo "     ./scripts/dev.sh shell   - Enter backend shell"
    echo "     ./scripts/dev.sh down    - Stop services"
    echo ""
}

# Main command handler
case "${1:-up}" in
    up|start)
        print_header
        check_docker
        print_status "Starting development environment..."
        docker-compose up -d --build
        wait_for_services
        show_urls
        ;;
    
    down|stop)
        print_header
        print_status "Stopping development environment..."
        docker-compose down
        print_status "All services stopped."
        ;;
    
    restart)
        print_header
        check_docker
        print_status "Restarting development environment..."
        docker-compose down
        docker-compose up -d --build
        wait_for_services
        show_urls
        ;;
    
    logs)
        docker-compose logs -f
        ;;
    
    logs-backend)
        docker-compose logs -f backend
        ;;
    
    logs-frontend)
        docker-compose logs -f frontend
        ;;
    
    shell|bash)
        print_status "Entering backend container..."
        docker-compose exec backend /bin/sh
        ;;
    
    db|psql)
        print_status "Entering PostgreSQL shell..."
        docker-compose exec postgres psql -U kgr33n -d kgr33n_dev
        ;;
    
    clean|purge)
        print_header
        print_warn "This will remove all containers, volumes, and images!"
        read -p "Are you sure? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_status "Cleaning up..."
            docker-compose down -v --rmi local
            print_status "Cleanup complete."
        else
            print_status "Cancelled."
        fi
        ;;
    
    status|ps)
        docker-compose ps
        ;;
    
    build)
        print_header
        check_docker
        print_status "Rebuilding images..."
        docker-compose build --no-cache
        print_status "Build complete."
        ;;
    
    test)
        print_header
        check_docker
        print_status "Running backend tests..."
        docker-compose exec backend pytest
        ;;
    
    *)
        echo "Usage: $0 {up|down|restart|logs|shell|db|clean|status|build|test}"
        echo ""
        echo "Commands:"
        echo "  up, start    Start all services"
        echo "  down, stop   Stop all services"
        echo "  restart      Restart all services"
        echo "  logs         View all logs (follow)"
        echo "  logs-backend View backend logs only"
        echo "  shell, bash  Enter backend container shell"
        echo "  db, psql     Enter PostgreSQL shell"
        echo "  clean, purge Remove containers, volumes, and images"
        echo "  status, ps   Show service status"
        echo "  build        Rebuild all images"
        echo "  test         Run backend tests"
        exit 1
        ;;
esac
