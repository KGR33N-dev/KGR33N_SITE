#!/bin/bash
# =============================================================================
# START BACKEND LOCALLY (Development)
# =============================================================================
#
# DEPRECATED: Use the new ./scripts/dev.sh from project root instead!
#
# This script is kept for backward compatibility.
# For full stack development, use:
#   cd /path/to/KGR33N_SITE
#   ./scripts/dev.sh
#
# =============================================================================

echo "⚠️  DEPRECATED: Use ./scripts/dev.sh from project root instead!"
echo ""
echo "🚀 Starting Portfolio Backend Locally..."

# Check if .env exists
if [ ! -f .env ]; then
    echo "❌ .env file not found!"
    echo "Create one with:"
    echo "  DATABASE_URL=postgresql://kgr33n:dev_password_123@localhost:5432/kgr33n_dev"
    echo "  SECRET_KEY=dev-secret-key-not-for-production"
    echo "  ENVIRONMENT=development"
    echo "  DEBUG=true"
    echo "  RESEND_API_KEY=optional-for-dev"
    exit 1
fi

# Load environment variables
set -a
source .env
set +a

# Check if PostgreSQL is running (docker or local)
echo "🔍 Checking database connection..."
if command -v pg_isready &> /dev/null; then
    if pg_isready -h localhost -p 5432 &> /dev/null; then
        echo "✅ PostgreSQL is ready"
    else
        echo "⚠️  PostgreSQL not reachable. Starting container..."
        docker run -d --name kgr33n-postgres-standalone \
            -e POSTGRES_DB=kgr33n_dev \
            -e POSTGRES_USER=kgr33n \
            -e POSTGRES_PASSWORD=dev_password_123 \
            -p 5432:5432 \
            postgres:15-alpine
        sleep 5
    fi
fi

# Run database migrations
echo "📦 Running database migrations..."
alembic upgrade head

# Start uvicorn with hot-reload
echo "🚀 Starting development server..."
echo ""
echo "  🌐 API:  http://localhost:8080"
echo "  📚 Docs: http://localhost:8080/docs"
echo ""
echo "  Press Ctrl+C to stop"
echo ""

uvicorn app.main:app --host 0.0.0.0 --port 8080 --reload