# Deployment Guide — Railway (Two-Service)

## Architecture

```
Internet → [Nginx Frontend] → /static/*  → served directly (cached 7 days)
                             → /*         → proxied to Flask backend

           [Flask Backend]   ← Railway internal network (not public)
                             → Supabase (hosted PostgreSQL)
                             → OpenAI API (RAG chat)
```

**Frontend service (Nginx)**: Public-facing reverse proxy that serves static assets (CSS, JS, images) directly and forwards all other requests to the backend.

**Backend service (Flask/Gunicorn)**: Handles API routes, Jinja2 template rendering, AI chat, and churn prediction. Communicates with Supabase and OpenAI. Not publicly exposed.

## Prerequisites

- [Railway account](https://railway.com)
- Railway CLI v3+ (`npm install -g @railway/cli`)
- GitHub repository connected to Railway
- Supabase project(s) for staging and production
- OpenAI API key

## Quick Start

```bash
# 1. Make the setup script executable
chmod +x setup-railway.sh

# 2. Preview what the script will do
./setup-railway.sh --dry-run

# 3. Run the interactive setup
./setup-railway.sh

# 4. Complete the manual steps printed at the end
```

## Environment Variables

### Backend Service

| Variable | Required | Description |
|----------|----------|-------------|
| `FLASK_SECRET_KEY` | Yes | Flask session secret. Generate: `python -c "import secrets; print(secrets.token_hex(32))"` |
| `SUPABASE_URL` | Yes | Supabase project URL |
| `SUPABASE_KEY` | Yes | Supabase anon/public key |
| `SUPABASE_SERVICE_KEY` | Yes | Supabase service role key (admin operations) |
| `OPENAI_API_KEY` | Yes | OpenAI API key (RAG chat + churn) |
| `PORT` | Auto | Set automatically by Railway |

### Frontend Service

| Variable | Required | Description |
|----------|----------|-------------|
| `BACKEND_URL` | Yes | Internal URL of the backend: `http://backend.railway.internal:<port>` |
| `PORT` | Auto | Set automatically by Railway |

## Environments

| Environment | Branch | Purpose |
|-------------|--------|---------|
| staging | `dev` | Pre-production testing |
| production | `main` | Live application |

## Manual Setup (Alternative to Script)

### 1. Create Railway project

```bash
railway login
railway init --name crm-doctor
```

### 2. Create staging environment

```bash
railway environment new staging
```

### 3. Create services

Create two services in the Railway dashboard:
- **frontend** — set Dockerfile path to `frontend/Dockerfile`
- **backend** — set Dockerfile path to `backend/Dockerfile`

### 4. Set variables

```bash
# Backend (staging)
railway variables --set "FLASK_SECRET_KEY=<value>" --environment staging --service backend
railway variables --set "SUPABASE_URL=<value>" --environment staging --service backend
railway variables --set "SUPABASE_KEY=<value>" --environment staging --service backend
railway variables --set "SUPABASE_SERVICE_KEY=<value>" --environment staging --service backend
railway variables --set "OPENAI_API_KEY=<value>" --environment staging --service backend

# Frontend (staging)
railway variables --set "BACKEND_URL=http://backend.railway.internal:<port>" --environment staging --service frontend

# Repeat for production environment...
```

### 5. Link branches (Dashboard only)

Railway CLI doesn't support branch-to-environment linking:
1. **Dashboard** → Project → Service → Settings → Source
2. Production: set branch to `main`
3. Staging: set branch to `dev`

### 6. Configure networking

- **Frontend**: Generate a Railway domain (public)
  - Dashboard → Frontend service → Settings → Networking → Generate Domain
- **Backend**: Enable private networking only (internal)
  - Dashboard → Backend service → Settings → Networking → Private Networking

### 7. Set up CI/CD tokens

1. Dashboard → Project → Settings → Tokens
2. Create token for staging → add as GitHub secret `RAILWAY_TOKEN_STAGING`
3. Create token for production → add as GitHub secret `RAILWAY_TOKEN_PRODUCTION`

## Local Docker Testing

```bash
# Build both images
docker build -f backend/Dockerfile -t crm-backend .
docker build -f frontend/Dockerfile -t crm-frontend .

# Run backend
docker run -p 5000:5000 \
  -e FLASK_SECRET_KEY=test-secret \
  -e SUPABASE_URL=<your-url> \
  -e SUPABASE_KEY=<your-key> \
  -e SUPABASE_SERVICE_KEY=<your-service-key> \
  -e OPENAI_API_KEY=<your-key> \
  crm-backend

# Run frontend (pointing to local backend)
docker run -p 8080:8080 \
  -e PORT=8080 \
  -e BACKEND_URL=http://host.docker.internal:5000 \
  crm-frontend

# Test
curl http://localhost:8080/login  # Should return 200 (proxied through Nginx)
curl http://localhost:8080/static/css/custom.css  # Served directly by Nginx
```

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| 502 Bad Gateway | Backend not running or BACKEND_URL wrong | Check `railway logs` for backend. Verify BACKEND_URL points to correct internal URL |
| Health check failing | Backend slow to start (Supabase init) | Increase `healthcheckTimeout` in railway.toml |
| Static files 404 | Frontend Dockerfile not copying static/ | Verify `COPY frontend/static/` in frontend/Dockerfile |
| scikit-learn import error | Missing libstdc++ in production image | Ensure `apk add libstdc++` in backend/Dockerfile stage 2 |
| Session issues | FLASK_SECRET_KEY not set | Set FLASK_SECRET_KEY (don't rely on default) |
| Nginx template error | BACKEND_URL not set | Set BACKEND_URL env var on the frontend service |

## File Overview

```
railway.toml              → Multi-service config (build, deploy, healthcheck per service)
frontend/Dockerfile       → Nginx Alpine image with static files + proxy config
frontend/nginx.conf       → Nginx config template (envsubst for PORT and BACKEND_URL)
frontend/.railwayignore   → Excludes backend code from frontend builds
backend/Dockerfile        → Multi-stage Python 3.11 Alpine with non-root user
backend/.railwayignore    → Excludes frontend Nginx files from backend builds
.env.staging              → Variable template for staging (placeholders only)
.env.production           → Variable template for production (placeholders only)
setup-railway.sh          → Idempotent CLI setup with --dry-run support
.github/workflows/deploy.yml → CI/CD: test → deploy per branch
```
