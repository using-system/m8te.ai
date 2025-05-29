FROM nginx:stable-perl

# Create a non-root user and group with specific IDs
RUN addgroup --gid 1001 appgroup && adduser --uid 1001 --ingroup appgroup --disabled-password appuser

# Copy the custom Nginx configuration file
COPY nginx.conf /etc/nginx/nginx.conf

# Copy a custom health check HTML file to the Nginx HTML directory
COPY health.html /usr/share/nginx/html/health.html

# Change ownership of the Nginx directories to the non-root user
RUN chown -R appuser:appgroup /usr/share/nginx/html
RUN chown -R appuser:appgroup /var/cache/nginx
RUN chown -R appuser:appgroup /var/run
RUN chown -R appuser:appgroup /etc/nginx/conf.d
RUN chown -R appuser:appgroup /etc/nginx/nginx.conf
RUN chown -R appuser:appgroup /tmp

# Switch to the non-root user
USER appuser

# Expose port 3000
EXPOSE 3000

# Add a health check instruction
#HEALTHCHECK --interval=30s --timeout=10s --retries=3 CMD curl -f http://localhost:3000/health || exit 1

# Start Nginx without creating a PID file
CMD ["nginx", "-g", "daemon off; pid /dev/null;", "-c", "/etc/nginx/nginx.conf"]