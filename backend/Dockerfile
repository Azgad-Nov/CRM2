# =============================================================================
# Dockerfile — CRM Doctor Backend (Flask + Gunicorn)
# =============================================================================
# Multi-stage build for the Flask API + Jinja2 template renderer.
# Stage 1: Compile Python dependencies (needs gcc for scikit-learn)
# Stage 2: Clean production image with non-root user
#
# Build context: project root (needs app.py, backend/, frontend/templates/)
# =============================================================================

# ---- Stage 1: Build dependencies ----
FROM python:3.11-alpine AS deps

# Build tools for compiling native extensions:
# - gcc, g++, musl-dev: C/C++ compiler for scikit-learn, pydantic-core
# - libffi-dev: Foreign function interface for cffi-based packages
RUN apk add --no-cache gcc musl-dev g++ libffi-dev

WORKDIR /build

# Install Python packages to a separate prefix (no pip cache in final image)
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ---- Stage 2: Production image ----
FROM python:3.11-alpine AS production

# Runtime-only dependencies (no compilers):
# - libstdc++: Required by scikit-learn's compiled C++ extensions
# - libffi: Required by cffi-based packages at runtime
RUN apk add --no-cache libstdc++ libffi

# Create non-root user for security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copy compiled Python packages from the build stage
COPY --from=deps /install /usr/local

# Copy application code
COPY app.py .
COPY Procfile .
COPY backend/ backend/
# Backend needs templates for Jinja2 rendering and static for url_for()
COPY frontend/templates/ frontend/templates/
COPY frontend/static/ frontend/static/

# Set ownership to non-root user
RUN chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser

# Railway injects $PORT at runtime; default to 8080 if not set
ENV PORT=8080
EXPOSE 8080

# Shell form to allow $PORT variable expansion at runtime
CMD gunicorn app:app --bind 0.0.0.0:$PORT --workers 2 --timeout 120 --access-logfile - --error-logfile -
