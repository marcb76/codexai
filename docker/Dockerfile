# ------------------------------------------------------------------------------
# codexAI full stack project - OCR solution
# Dockerfile
#
# Marc Bonet
# The Eniac Corporation
# Copyright TEC - Ago.2025
# ------------------------------------------------------------------------------




# ------------------------------------------------------------------------------
# Ultra light base: Alpine Linux
# ------------------------------------------------------------------------------
FROM python:3.12-slim


# ------------------------------------------------------------------------------
# Environment Variables
# ------------------------------------------------------------------------------
ENV LANG=C.UTF-8 \
    PYTHONUNBUFFERED=1 \
    PATH="/usr/local/bin:$PATH"


# ------------------------------------------------------------------------------
# Install OS packages
# ------------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    coreutils \
    sed \
    jq \
    nano \
    curl \
    git \
    gnupg \
    tesseract-ocr \
    tesseract-ocr-spa \
    tesseract-ocr-eng \
    imagemagick \
    build-essential \
    libjpeg-dev \
    libpng-dev \
    libtiff-dev \
    ffmpeg \
    nginx \
    procps \
    file \
    tini
    


# ------------------------------------------------------------------------------
# Install Python packages for OCR
# ------------------------------------------------------------------------------
RUN pip install --no-cache-dir pillow numpy opencv-python-headless


# ------------------------------------------------------------------------------
# Install Node.js LTS
# ------------------------------------------------------------------------------
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g npm


# ------------------------------------------------------------------------------
# Verify installation
# ------------------------------------------------------------------------------
RUN node -v \
    && npm -v \
    && python --version \
    && convert --version \
    && tesseract --version
    
    
# -------------------------------------------------------------------------------
# Cleanup temporary files
RUN rm -rf /var/lib/apt/lists/* /tmp/* /root/.cache
# -------------------------------------------------------------------------------




# -------------------------------------------------------------------------------
# Create non-root user: appuser
# -------------------------------------------------------------------------------
#RUN adduser -D -h /app appuser


# -------------------------------------------------------------------------------
# Create application directories
# -------------------------------------------------------------------------------
WORKDIR /app
RUN mkdir -p /app/frontend
RUN mkdir -p /app/backend
RUN mkdir -p /app/uploads
RUN mkdir -p /app/ssl
RUN mkdir -p /app/logs
RUN mkdir -p /app/run
#RUN chown -R appuser:appuser /app


# ------------------------------------------------------------------------------
# Copy backend files and final configuration
# ------------------------------------------------------------------------------
COPY ./backend /app/backend
COPY ./backend.env /app/backend/.env
WORKDIR /app/backend
RUN npm install --omit=dev
WORKDIR /app


# ------------------------------------------------------------------------------
# Copy frontend files and final configuration
# ------------------------------------------------------------------------------
COPY ./frontend /app/frontend


# ------------------------------------------------------------------------------
# Copy nginx and SSH Configuration
# ------------------------------------------------------------------------------
COPY ./nginx/nginx.conf /etc/nginx/nginx.conf
COPY ./nginx/mime.types /etc/nginx/mime.types
COPY ./nginx/frontend.conf /etc/nginx/conf.d/default.conf
COPY ./ssl/ssl.key /app/ssl/ssl.key
COPY ./ssl/ssl.crt /app/ssl/ssl.crt
RUN chmod 644 /app/ssl/ssl.crt
RUN chmod 640 /app/ssl/ssl.key
#RUN chown root:nginx /app/ssl/ssl.crt /app/ssl/ssl.key


# ------------------------------------------------------------------------------
# Copy start script
# ------------------------------------------------------------------------------
COPY ./ocr-container-start.sh /usr/local/bin/ocr-container-start.sh
RUN chmod +x /usr/local/bin/ocr-container-start.sh


# ------------------------------------------------------------------------------
# Expose Ports: 443 (Nginx), 8443 (Node.js / Express)
# ------------------------------------------------------------------------------
EXPOSE 443 8443


# ------------------------------------------------------------------------------
# Entrypoint
# ------------------------------------------------------------------------------
#USER appuser
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/ocr-container-start.sh"]
# ------------------------------------------------------------------------------