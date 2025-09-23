#!/bin/bash
# ------------------------------------------------------------------------------
# ocr-container-start.sh
# Start up script for the OCR Docker container
# Called by Dockerfile as ENTRYPOINT
# Starts Nginx and Node.js backend, then keeps container alive
#
# Marc Bonet"
# The Eniac Corporation"
# Copyright TEC - Ago.2025"
# ------------------------------------------------------------------------------




# --- Config -------------------------------------------------------------------
set -e
BACKEND_NODE_JS_FILE_PATH="/app/backend"
BACKEND_NODE_JS_FILE="ocr-backend.js"


# --- Helper: logging functions ------------------------------------------------
logInfo() {
  echo "[STARTUP] $1"
}

logWarn() {
  echo "[WARN]    $1" >&2
}








# ------------------------------------------------------------------------------
# --- Entry point --------------------------------------------------------------
logInfo "Starting OCR container..."


# --- Signal handling ----------------------------------------------------------
trap 'logInfo "SIGTERM/SIGINT received, shutting down..."; kill $(jobs -p) 2>/dev/null || true; exit 0' SIGTERM SIGINT


# --- Start Node.js backend ----------------------------------------------------
if [ -f "$BACKEND_NODE_JS_FILE_PATH/$BACKEND_NODE_JS_FILE" ]; then
    logInfo "Starting Node-Express (backend) via $BACKEND_NODE_JS_FILE_PATH/$BACKEND_NODE_JS_FILE"
    node "$BACKEND_NODE_JS_FILE_PATH/$BACKEND_NODE_JS_FILE" >> /app/logs/node.log 2>&1 &
    NODE_PID=$!
else
    logWarn "Node-Express (backend) file not found at $BACKEND_NODE_JS_FILE_PATH/$BACKEND_NODE_JS_FILE, skipping..."
fi


# --- Start Nginx (frontend) ---------------------------------------------------
logInfo "Starting Nginx (frontend)..."
nginx -g 'daemon off;' &


# --- Wait for processes or execute CMD ----------------------------------------
# If the container receives a command, execute it. Otherwise, wait for Node/Nginx
if [ $# -eq 0 ]; then
    logInfo "No CMD provided, keeping container alive..."
    wait -n
else
    logInfo "Executing CMD: $*"
    exec "$@"
fi
