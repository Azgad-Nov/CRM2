#!/usr/bin/env bash
# =============================================================================
# Railway Project Setup Script — CRM Doctor (Two-Service)
# =============================================================================
# Sets up a Railway project with:
#   - Two environments: staging (dev branch) and production (main branch)
#   - Two services per environment: frontend (Nginx) and backend (Flask)
#   - Environment variables for each service
#
# Usage:
#   chmod +x setup-railway.sh
#   ./setup-railway.sh               # Interactive setup
#   ./setup-railway.sh --dry-run     # Preview commands without executing
#   ./setup-railway.sh --verbose     # Detailed output
#   ./setup-railway.sh --help        # Show usage
#
# Requirements: Railway CLI v3+, bash, jq (optional)
# Compatible with: macOS and Linux
# =============================================================================
set -euo pipefail

# --- Configuration ---
PROJECT_NAME="crm-doctor"
STAGING_ENV="staging"
PRODUCTION_ENV="production"
FRONTEND_SERVICE="frontend"
BACKEND_SERVICE="backend"

# --- Flags ---
DRY_RUN=false
VERBOSE=false

# --- Usage ---
usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Options:
  --dry-run    Show commands without executing them
  --verbose    Show detailed output
  --help       Show this help message

This script sets up a Railway project with two environments (staging,
production) and two services (frontend, backend) in each environment.
EOF
    exit 0
}

# --- Parse Arguments ---
for arg in "$@"; do
    case $arg in
        --dry-run)  DRY_RUN=true ;;
        --verbose)  VERBOSE=true ;;
        --help)     usage ;;
        *)          echo "Unknown argument: $arg"; usage ;;
    esac
done

# --- Helper Functions ---
log()     { printf "[INFO]  %s\n" "$*"; }
warn()    { printf "[WARN]  %s\n" "$*" >&2; }
error()   { printf "[ERROR] %s\n" "$*" >&2; exit 1; }
success() { printf "[OK]    %s\n" "$*"; }

run_cmd() {
    if [ "$DRY_RUN" = true ]; then
        printf "[DRY-RUN] %s\n" "$*"
        return 0
    fi
    if [ "$VERBOSE" = true ]; then
        printf "[RUN] %s\n" "$*"
    fi
    eval "$@"
}

# Prompt for a variable value, skip if empty
prompt_var() {
    local var_name="$1"
    local env_name="$2"
    local service_name="$3"
    local value

    read -rp "  $var_name: " value
    if [ -n "$value" ]; then
        run_cmd "railway variables --set \"$var_name=$value\" --environment \"$env_name\" --service \"$service_name\""
    else
        log "  Skipped $var_name (empty input, keeping existing value)"
    fi
}

# =============================================================================
# STEP 0: Prerequisite Checks
# =============================================================================
log "Checking prerequisites..."

# Check Railway CLI is installed
if ! command -v railway &> /dev/null; then
    error "Railway CLI not found. Install it with: npm install -g @railway/cli"
fi

# Check Railway CLI version (v3+ required)
RAILWAY_VERSION=$(railway version 2>/dev/null || railway --version 2>/dev/null || echo "unknown")
log "Railway CLI version: $RAILWAY_VERSION"

# Check login status
log "Verifying Railway authentication..."
if ! railway whoami &>/dev/null 2>&1; then
    log "Not logged in. Starting login flow..."
    run_cmd "railway login"
fi
success "Authenticated with Railway"

# =============================================================================
# STEP 1: Initialize Project
# =============================================================================
log ""
log "Step 1: Initializing Railway project '$PROJECT_NAME'..."

if railway status &>/dev/null 2>&1; then
    log "Already linked to a Railway project. Skipping init (idempotent)."
else
    run_cmd "railway init --name '$PROJECT_NAME'"
    success "Project '$PROJECT_NAME' created"
fi

# =============================================================================
# STEP 2: Create Environments
# =============================================================================
log ""
log "Step 2: Creating environments..."

# Create staging environment (production exists by default)
if run_cmd "railway environment new '$STAGING_ENV'" 2>/dev/null; then
    success "Staging environment created"
else
    log "Staging environment already exists (idempotent — continuing)"
fi

log "Production environment exists by default"

# =============================================================================
# STEP 3: Create Services
# =============================================================================
log ""
log "Step 3: Creating services in each environment..."
log ""
log "NOTE: Railway CLI may not support creating services directly."
log "If the commands below fail, create the services via the dashboard:"
log "  https://railway.com/dashboard → Project → New Service"
log ""

# Create frontend service
if run_cmd "railway service new '$FRONTEND_SERVICE'" 2>/dev/null; then
    success "Frontend service created"
else
    log "Frontend service may already exist or must be created via dashboard"
fi

# Create backend service
if run_cmd "railway service new '$BACKEND_SERVICE'" 2>/dev/null; then
    success "Backend service created"
else
    log "Backend service may already exist or must be created via dashboard"
fi

# =============================================================================
# STEP 4: Set Backend Variables (Staging)
# =============================================================================
log ""
log "Step 4: Setting backend variables for STAGING..."
log "Press Enter to skip a variable (keeps existing value)."
log ""

if [ "$DRY_RUN" = false ]; then
    prompt_var "FLASK_SECRET_KEY" "$STAGING_ENV" "$BACKEND_SERVICE"
    prompt_var "SUPABASE_URL" "$STAGING_ENV" "$BACKEND_SERVICE"
    prompt_var "SUPABASE_KEY" "$STAGING_ENV" "$BACKEND_SERVICE"
    prompt_var "SUPABASE_SERVICE_KEY" "$STAGING_ENV" "$BACKEND_SERVICE"
    prompt_var "OPENAI_API_KEY" "$STAGING_ENV" "$BACKEND_SERVICE"
    success "Staging backend variables set"
else
    log "[DRY-RUN] Would prompt for: FLASK_SECRET_KEY, SUPABASE_URL, SUPABASE_KEY, SUPABASE_SERVICE_KEY, OPENAI_API_KEY"
    log "[DRY-RUN] Command: railway variables --set KEY=VALUE --environment staging --service backend"
fi

# =============================================================================
# STEP 5: Set Frontend Variables (Staging)
# =============================================================================
log ""
log "Step 5: Setting frontend variables for STAGING..."
log ""

if [ "$DRY_RUN" = false ]; then
    prompt_var "BACKEND_URL" "$STAGING_ENV" "$FRONTEND_SERVICE"
    success "Staging frontend variables set"
else
    log "[DRY-RUN] Would prompt for: BACKEND_URL"
    log "[DRY-RUN] Command: railway variables --set BACKEND_URL=http://backend.railway.internal:PORT --environment staging --service frontend"
fi

# =============================================================================
# STEP 6: Set Backend Variables (Production)
# =============================================================================
log ""
log "Step 6: Setting backend variables for PRODUCTION..."
log "Press Enter to skip a variable (keeps existing value)."
log ""

if [ "$DRY_RUN" = false ]; then
    prompt_var "FLASK_SECRET_KEY" "$PRODUCTION_ENV" "$BACKEND_SERVICE"
    prompt_var "SUPABASE_URL" "$PRODUCTION_ENV" "$BACKEND_SERVICE"
    prompt_var "SUPABASE_KEY" "$PRODUCTION_ENV" "$BACKEND_SERVICE"
    prompt_var "SUPABASE_SERVICE_KEY" "$PRODUCTION_ENV" "$BACKEND_SERVICE"
    prompt_var "OPENAI_API_KEY" "$PRODUCTION_ENV" "$BACKEND_SERVICE"
    success "Production backend variables set"
else
    log "[DRY-RUN] Would prompt for: FLASK_SECRET_KEY, SUPABASE_URL, SUPABASE_KEY, SUPABASE_SERVICE_KEY, OPENAI_API_KEY"
    log "[DRY-RUN] Command: railway variables --set KEY=VALUE --environment production --service backend"
fi

# =============================================================================
# STEP 7: Set Frontend Variables (Production)
# =============================================================================
log ""
log "Step 7: Setting frontend variables for PRODUCTION..."
log ""

if [ "$DRY_RUN" = false ]; then
    prompt_var "BACKEND_URL" "$PRODUCTION_ENV" "$FRONTEND_SERVICE"
    success "Production frontend variables set"
else
    log "[DRY-RUN] Would prompt for: BACKEND_URL"
    log "[DRY-RUN] Command: railway variables --set BACKEND_URL=http://backend.railway.internal:PORT --environment production --service frontend"
fi

# =============================================================================
# STEP 8: Deploy
# =============================================================================
log ""
log "Step 8: Deploying both environments..."

log "Deploying staging..."
run_cmd "railway up --detach --environment '$STAGING_ENV'" 2>/dev/null || \
    warn "Staging deploy may require dashboard trigger (see manual steps below)"

log "Deploying production..."
run_cmd "railway up --detach --environment '$PRODUCTION_ENV'" 2>/dev/null || \
    warn "Production deploy may require dashboard trigger (see manual steps below)"

# =============================================================================
# MANUAL STEPS
# =============================================================================
cat <<'MANUAL'

============================================================
  MANUAL STEPS REQUIRED (Railway Dashboard)
============================================================

The Railway CLI does not support all configuration options.
Complete these steps in the Railway dashboard:

  1. CONNECT GITHUB REPO
     Dashboard → Project → each service → Settings → Source
     Connect your GitHub repository to both services.

  2. LINK BRANCHES TO ENVIRONMENTS
     - Production environment: set deploy branch to "main"
     - Staging environment: set deploy branch to "dev"
     Path: Service → Settings → Source → Branch

  3. CONFIGURE SERVICE DOCKERFILES
     Each service must point to the correct Dockerfile:
     - Frontend service: frontend/Dockerfile
     - Backend service: backend/Dockerfile
     Path: Service → Settings → Build → Dockerfile Path

  4. SET FRONTEND AS PUBLIC, BACKEND AS INTERNAL
     - Frontend: add a Railway domain or custom domain
       Path: Service → Settings → Networking → Generate Domain
     - Backend: enable internal networking only
       Path: Service → Settings → Networking → Private Networking

  5. SET BACKEND_URL ON FRONTEND SERVICE
     After the backend gets its internal URL, update the
     frontend's BACKEND_URL variable to:
       http://backend.railway.internal:<backend-port>

  6. GENERATE PROJECT TOKENS (for CI/CD)
     Dashboard → Project → Settings → Tokens
     Create one token per environment:
       - Staging token  → GitHub secret: RAILWAY_TOKEN_STAGING
       - Production token → GitHub secret: RAILWAY_TOKEN_PRODUCTION

============================================================

MANUAL

success "Setup complete! Review the manual steps above."
