# =============================================================================
# Dockerfile — CRM Doctor Frontend (Nginx)
# =============================================================================
# Serves static assets directly and proxies all other requests to the
# Flask backend service via Railway's internal network.
#
# Build context: project root (so we can access frontend/static/)
# =============================================================================

FROM nginx:1.27-alpine

# Create non-root user for security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Remove default Nginx config
RUN rm /etc/nginx/conf.d/default.conf

# Copy Nginx config template (uses environment variable substitution)
COPY frontend/nginx.conf /etc/nginx/templates/default.conf.template

# Copy static assets into the Nginx serving directory
COPY frontend/static/ /usr/share/nginx/static/

# Nginx's official Docker image runs envsubst on templates in
# /etc/nginx/templates/ and outputs to /etc/nginx/conf.d/ at startup.
# This substitutes ${PORT} and ${BACKEND_URL} from environment variables.

# Railway sets PORT; BACKEND_URL must be set to the backend service's internal URL
ENV PORT=8080
ENV BACKEND_URL=http://localhost:5000

# Expose the port (Railway overrides via $PORT)
EXPOSE 8080

# Use the default Nginx entrypoint which handles template substitution
# and runs Nginx as non-root via nginx.conf's `user` directive
CMD ["nginx", "-g", "daemon off;"]
