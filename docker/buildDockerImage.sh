#!/bin/bash

# ============================================
# codexAI full stack project - OCR solution
# Docker image build script
# 
# Marc Bonet
# The Eniac Corporation
# October 2025
# ============================================




# ------------------------------------------------------------------------------
# Environment setup
ANGULAR_APP_NAME=codex-ai
DOCKER_USER=marcb76
DOCKER_PASSWORD='KrgaTYsz3YK5Sd)'
DOCKER_IMAGE_NAME=tec-codexai
DOCKER_IMAGE_TAG=1.0
DOCKER_WHOLE_IMAGE_NAME=$DOCKER_USER/$DOCKER_IMAGE_NAME:$DOCKER_IMAGE_TAG
DOCKER_CONTAINER_NAME=$DOCKER_IMAGE_NAME
# ------------------------------------------------------------------------------








# ------------------------------------------------------------------------------
# Entrypoint
# ------------------------------------------------------------------------------
clear
echo ""
echo ""
echo "====================================================="
echo "# codexAI full stack project"
echo "# Docker image build script: $DOCKER_WHOLE_IMAGE_NAME"
echo "#"
echo "# Marc Bonet"
echo "# The Eniac Corporation"
echo "# October 2025"
echo "====================================================="
echo ""
echo ""




# ------------------------------------------------------------------------------
# Refresh backend folder
# ------------------------------------------------------------------------------
echo ""
echo ""
echo "🎯 Creating codexAI's backend folder..."
if [ ! -d "./backend" ]; then
  mkdir -p backend || { echo "Failed to create backend directory"; exit 1; }
  echo "✅ Backend folder created successfully."
else
  echo "  💡 codexAI's backend folder already exists. Skipping creation but deleting current contents..."
  rm -rf ./backend/* || { echo "Failed to delete existing backend contents"; exit 1; }
  echo "✅ Existing backend contents deleted successfully."
fi
cd ../backend || { echo "Failed to change directory to backend"; exit 1; }
find . -maxdepth 1 ! -name "node_modules" ! -name "." -exec cp -r {} ../docker/backend/ \;
cd ../docker || { echo "Failed to change directory to docker"; exit 1; }
echo "✅ Backend folder refreshed successfully."



# ------------------------------------------------------------------------------
# Refresh frontend folder
# ------------------------------------------------------------------------------
echo ""
echo ""
echo "🎯 Creating codexAI's frontend folder..."
if [ ! -d "./frontend" ]; then
  mkdir -p frontend || { echo "Failed to create frontend directory"; exit 1; }
  echo "✅ Frontend folder created successfully."
else
  echo "  💡 codexAI's frontend folder already exists. Skipping creation but deleting current contents..."
  rm -rf ./frontend/* || { echo "Failed to delete existing frontend contents"; exit 1; }
  echo "✅ Existing frontend contents deleted successfully."
fi
cd ../frontend || { echo "Failed to change directory to frontend"; exit 1; }
ng build --configuration production > buildDockerImage.log 2>&1 || { echo "Failed to build frontend"; exit 1; }
cd ../docker || { echo "Failed to change directory to docker"; exit 1; }
cp -r ../frontend/dist/$ANGULAR_APP_NAME/* ./frontend/ || { echo "Failed to copy frontend files"; exit 1; }
echo "✅ Frontend folder refreshed successfully."



# ------------------------------------------------------------------------------
# Refresh ssl folder
# ------------------------------------------------------------------------------
echo ""
echo ""
echo "🎯 Refreshing codexAI's ssl folder..."
if [ -d "./ssl" ]; then
  rm -rf ./ssl || { echo "Failed to remove existing ssl directory"; exit 1; }
fi
mkdir -p ssl || { echo "Failed to recreate ssl directory"; exit 1; }
cp ../shared/assets/ssl/eniac-corp.com.crt ./ssl/ssl.crt || { echo "Failed to copy ssl certificate"; exit 1; }
cp ../shared/assets/ssl/eniac-corp.com.key ./ssl/ssl.key || { echo "Failed to copy ssl key"; exit 1; }
echo "✅ SSL folder refreshed successfully."




# ------------------------------------------------------------------------------
# Create uploads folder (if not existing)
# ------------------------------------------------------------------------------
echo ""
echo ""
echo "🎯 Creating codexAI's uploads folder..."
if [ ! -d "./uploads" ]; then
  mkdir -p uploads || { echo "Failed to create uploads directory"; exit 1; }
  echo "✅ Uploads folder created successfully."
else
  echo "  💡 codexAI's uploads folder already exists. Skipping creation but deleting current contents..."
  rm -rf ./uploads/* || { echo "Failed to delete existing uploads"; exit 1; }
  echo "✅ Existing uploads deleted successfully."
fi




# ------------------------------------------------------------------------------
# Create logs folder (if not existing)
# ------------------------------------------------------------------------------
echo ""
echo ""
echo "🎯 Creating codexAI's logs folder..."
if [ ! -d "./logs" ]; then
  mkdir -p logs || { echo "Failed to create logs directory"; exit 1; }
  echo "✅ Logs folder created successfully."
else
  echo "  💡 codexAI's logs folder already exists. Skipping creation but deleting current contents..."
  rm -rf ./logs/* || { echo "Failed to delete existing logs"; exit 1; }
  echo "✅ Existing logs deleted successfully."
fi




# ------------------------------------------------------------------------------
# Create docker image
# ------------------------------------------------------------------------------
echo ""
echo ""
echo "🎯 Building codexAI's Docker image..."
echo "  ⛏️ Cleaning up any existing Docker containers or images..."
docker stop $DOCKER_CONTAINER_NAME 2>/dev/null || true
docker rm $DOCKER_CONTAINER_NAME 2>/dev/null || true
docker rmi $DOCKER_WHOLE_IMAGE_NAME 2>/dev/null || true
echo "  ✅ Cleanup done."

echo "  ⛏️ Building Docker image $DOCKER_WHOLE_IMAGE_NAME..."
docker build -t $DOCKER_WHOLE_IMAGE_NAME . || { echo "Failed to build Docker image"; exit 1; }
echo "  ✅ Docker image $DOCKER_WHOLE_IMAGE_NAME built."
echo "  ⛏️ Pushing Docker image $DOCKER_WHOLE_IMAGE_NAME..."
docker login --username=$DOCKER_USER --password=$DOCKER_PASSWORD
docker push $DOCKER_WHOLE_IMAGE_NAME
echo "  ✅ Docker image $DOCKER_WHOLE_IMAGE_NAME pushed."
echo "✅ Docker image built successfully."
echo "✅ All done... have a nice day!"
echo ""
echo ""
echo ""
echo ""



