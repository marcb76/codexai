#!/bin/bash
# ------------------------------------------------------------------------------
# codexAI full stack project - OCR solution
# ocr-container-start.sh
# Start up script for the TEC CodexAI (OCR solution) Docker container
# Called by Dockerfile as ENTRYPOINT
# Starts Nginx and Node.js backend, then keeps container alive
#
# Marc Bonet
# The Eniac Corporation
# Copyright TEC - Ago.2025
# ------------------------------------------------------------------------------




# --- Config -------------------------------------------------------------------
set -e
CURRENT_DIR="$(pwd)"
BACKEND_NODE_JS_FILE_PATH="/app/backend"
BACKEND_NODE_JS_FILE="codexAI.js"


# --- Helper: logging functions ------------------------------------------------
logInfo() { echo "[STARTUP] $1"; }
logWarn() { echo "[WARN]    $1" >&2; }




# ------------------------------------------------------------------------------
# --- Entry point --------------------------------------------------------------
logInfo "Starting OCR container..."


# --- Signal handling ----------------------------------------------------------
trap 'logInfo "SIGTERM/SIGINT received, shutting down..."; kill $(jobs -p) 2>/dev/null || true; exit 0' SIGTERM SIGINT


# --- Start Node.js backend ----------------------------------------------------
if [ -f "$BACKEND_NODE_JS_FILE_PATH/$BACKEND_NODE_JS_FILE" ]; then
    cd "$BACKEND_NODE_JS_FILE_PATH"
    logInfo "Starting Node-Express (backend) via \"node $BACKEND_NODE_JS_FILE_PATH/$BACKEND_NODE_JS_FILE\"..."
#   logInfo "... and with the following environment file:"
#   cat ".env"
    node "$BACKEND_NODE_JS_FILE" >> /app/logs/node.log 2>&1 &
    cd "$CURRENT_DIR"
else
    logWarn "Node-Express (backend) file not found at $BACKEND_NODE_JS_FILE_PATH/$BACKEND_NODE_JS_FILE, skipping..."
fi


# --- Start Nginx (frontend) (foreground) --------------------------------------
logInfo "Starting Nginx (frontend) in foreground (container will kept here) via \"nginx -g 'daemon off;'\"..."
exec nginx -g 'daemon off;'
# Nginx will keep the container alive, and handle SIGTERM/SIGINT to shut down
# properly when the container is stopped
# ------------------------------------------------------------------------------
