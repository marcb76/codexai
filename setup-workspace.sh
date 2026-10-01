#!/bin/bash

# ============================================
# codexAI full stack project - OCR solution
# Workspace initialization script
# 
# Marc Bonet
# August 2025
# ============================================



clear
echo ""
echo ""
echo "============================================"
echo "# codexAI full stack project"
echo "# Workspace initialization script"
echo "#"
echo "# Marc Bonet"
echo "# August 2025"
echo "============================================"
echo ""
echo ""
echo ""
echo ""
echo "🚀 codexAI workspace setup..."




# Check for required tools
echo "🔍 Checking required tools..."
for tool in git npm ng; do
    if ! command -v $tool &> /dev/null; then
        echo "❌ $tool is not installed. Please install it first."
        exit 1
    fi
done
echo "✅ All required tools are installed."




# Initialize git if not present
if [ ! -d ".git" ]; then
    echo "🗃 Initializing git repository..."
    git init --initial-branch=main || { echo "Failed to initialize git repository"; exit 1; }
    echo "✅ Git repository initialized."

    # Create codexAI.js
    echo "📝 Creating .gitignore..."
    cat << 'EOF' > .gitignore 
# ======================================
# Common (backend & frontend) 
# ======================================
# files and directories
# ======================================
node_modules/
dist/
tmp/
temp/


# Environment variables
# ======================================
.env
.env.*
!.env.sample


# Logs and reports
# ======================================
*.log
npm-debug.log*
coverage/
.nyc_output/
*.lcov


# OS / IDE files
# ======================================
.DS_Store
Thumbs.db
*.swp
*.swo
*.swn
*.swm
*.idea/
*.iml
.vscode/
.history/
*.bak
*.tmp


# Node / Express (backend)
# ======================================
build/
out/
uploads/


# Angular (frontend)
# ======================================
.angular/
.angular/cache/
.angular/config.json
EOF
    if [ $? -ne 0 ]; then
        echo "Failed to create .gitignore"
        exit 1
    else
        echo "✅ .gitignore created successfully."
    fi
else
    echo "ℹ️ Git repository already exists."
fi




# ===========================================
# Backend setup
echo ""
echo ""
echo "🛠 Setting up backend..."
if [ -d "backend" ]; then
    echo "⚠️  backend directory already exists."
    read -p "   Do you want to recreate it? All current content will be lost! (yes/no): " yn
    case "$yn" in
        yes ) 
            echo "🗑 Removing existing backend directory..."
            rm -rf backend || { echo "Failed to remove existing backend directory"; exit 1; }
            ;;
        no )
            echo "ℹ️ Keeping existing backend directory (skipping creation)"
            BACKEND_SKIP=true
            ;;
        * )
            echo "❌ Invalid response. Exiting"
            exit 1
            ;;
    esac
fi
if [ "$BACKEND_SKIP" != true ]; then
  mkdir -p backend || { echo "Failed to create backend directory"; exit 1; }
  cd backend || { echo "Failed to enter backend directory"; exit 1; }


  # Create codexAI.js
  echo "📝 Creating codexAI.js..."
  cat << 'EOF' > codexAI.js 
  const express = require('express');
  const app = express();
  const port = process.env.PORT || 3000;

  app.get('/', (req, res) => {
    res.send('Hello from codexAI backend!');
  });

  app.listen(port, () => {
    console.log(`Server running on http://localhost:${port}`);
  });
EOF
  if [ $? -ne 0 ]; then
      echo "Failed to create codexAI.js"
      exit 1
  fi


  # Create package.json for backend
  echo "📝 Creating package.json for backend..."
  cat > package.json << 'EOF'
  {
    "name": "codexAI-backend",
    "version": "1.0.0",
    "description": "Backend for codexAI",
    "main": "codexAI.js",
    "scripts": {
      "start": "clear && node ./codexAI.js",
      "dev": "clear && nodemon ./codexAI.js",
      "test": "echo 'Error: no test specified' && exit 1",
      "format": "prettier --write '**/*.{js,json,scss,css,ts}'"
    },
    "author": "Marc Bonet <marc.bonet.bretto@gmail.com>",
    "license": "See License in ../shared/assets/license.txt",
    "private": true
  }
EOF
  if [ $? -ne 0 ]; then
      echo "Failed to create package.json for backend"
      exit 1
  fi


  # Install backend dependencies
  echo "📦 Installing backend dependencies..."
  npm install cors dotenv express-validator http-status-codes multer validator || { echo "Failed to install backend dependencies"; exit 1; }
  npm install --save-dev prettier nodemon || { echo "Failed to install backend dev dependencies"; exit 1; }


  # Prettier configuration
  echo "📝 Creating .prettierrc..."
  cat << 'EOF' > .prettierrc
  {
    "semi": true,
    "singleQuote": true,
    "trailingComma": "all",
    "printWidth": 80
  }
EOF
  if [ $? -ne 0 ]; then
      echo "Failed to create .prettierrc"
      exit 1
  fi


  # ===========================================
  # Docker directory
  echo "📂 Creating docker directory..."
  mkdir -p docker || { echo "Failed to create docker directory"; exit 1; }
  cd docker || { echo "Failed to enter docker directory"; exit 1; }
  touch Dockerfile || { echo "Failed to create Dockerfile file"; exit 1; }
  touch buildDockerImage.sh || { echo "Failed to create buildDockerImage.sh file"; exit 1; }
  chmod +x buildDockerImage.sh || { echo "Failed to make buildDockerImage.sh executable"; exit 1; }
  cd .. || { echo "Failed to enter parent directory"; exit 1; }
  echo "✅ Docker directory creation completed"


  # Backend project creation completed
  cd .. || { echo "Failed to enter parent directory"; exit 1; }
  echo "✅ Backend project creation completed"
fi




# ===========================================
# Frontend setup
echo ""
echo ""
echo "🛠 Setting up frontend..."
if [ -d "frontend" ]; then
    echo "⚠️  frontend directory already exists."
    read -p "   Do you want to recreate it? All current content will be lost! (yes/no): " yn
    case "$yn" in
        yes ) 
            echo "🗑 Removing existing frontend directory..."
            rm -rf frontend || { echo "Failed to remove existing frontend directory"; exit 1; }
            ;;
        no )
            echo "ℹ️ Keeping existing frontend directory. Skipping frontend creation."
            FRONTEND_SKIP=true
            ;;
        * )
            echo "❌ Invalid response. Exiting."
            exit 1
            ;;
    esac
fi
if [ "$FRONTEND_SKIP" != true ]; then
  mkdir -p frontend || { echo "Failed to create frontend directory"; exit 1; }
  cd frontend || { echo "Failed to enter frontend directory"; exit 1; }


  # Create Angular project
  echo "📦 Creating Angular project..."
  ng new codexAI --prefix app --routing=true --style=scss --skip-tests=false --ssr=false --strict --standalone --skip-git --directory . || { echo "Failed to create Angular project"; exit 1; }


  # Update frontend package.json metadata
  echo "📝 Updating frontend package.json metadata..."
  tmpfile="package.tmp.json"
  jq '. + {
    "name": "codexAI-frontend",
    "description": "Frontend for codexAI",
    "author": {
      "name": "Marc Bonet",
      "email": "marc.bonet.bretto@gmail.com"
    },
    "private": true,
    "license": "See License in /shared/assets/license.txt",
    "scripts": {
        "ng": "ng",
        "start": "ng serve",
        "build": "ng build",
        "watch": "ng build --watch --configuration development",
        "test": "ng test",
        "format": "prettier --write '\''**/*.{ts,scss,html,json}'\''"
      }
  }' package.json > "$tmpfile" && mv "$tmpfile" package.json || { echo "Failed to update package.json metadata"; exit 1; }


  # Install frontend dependencies
  echo "📦 Installing frontend dependencies..."
  npm install primeng@19 primeflex@3 primeicons@7 @primeuix/themes date-fns || { echo "Failed to install frontend dependencies"; exit 1; }
  npm install --save-dev prettier || { echo "Failed to install frontend dev dependencies"; exit 1; }


  # Prettier configuration
  echo "📝 Creating .prettierrc..."
  cat << 'EOF' > .prettierrc
  {
    "semi": true,
    "singleQuote": true,
    "trailingComma": "all",
    "printWidth": 80
  }
EOF
  if [ $? -ne 0 ]; then
      echo "Failed to create .prettierrc"
      exit 1
  fi


  # ===========================================
  # Docker directory
  echo "📂 Creating docker directory..."
  mkdir -p docker || { echo "Failed to create docker directory"; exit 1; }
  cd docker || { echo "Failed to enter docker directory"; exit 1; }
  touch Dockerfile || { echo "Failed to create Dockerfile file"; exit 1; }
  touch buildDockerImage.sh || { echo "Failed to create buildDockerImage.sh file"; exit 1; }
  chmod +x buildDockerImage.sh || { echo "Failed to make buildDockerImage.sh executable"; exit 1; }
  cd .. || { echo "Failed to enter parent directory"; exit 1; }
  echo "✅ Docker directory creation completed"


  # Frontend project creation completed
  cd .. || { echo "Failed to enter parent directory"; exit 1; }
  echo "✅ Frontend project creation completed"
fi




# ===========================================
# Shared assets directory
echo ""
echo ""
echo "📂 Creating shared assets directory..."
mkdir -p shared/assets || { echo "Failed to create shared assets directory"; exit 1; }
mkdir -p shared/assets/images || { echo "Failed to create shared assets/images directory"; exit 1; }
mkdir -p shared/assets/styles || { echo "Failed to create shared/assets/styles directory"; exit 1; }


# Create license file
echo "📄 Creating license file..."
cat > shared/assets/license.txt << 'EOF'
Proprietary Software License Agreement

Copyright © 2025 Marc Bonet. All rights reserved.

This software and its associated documentation are proprietary products of Marc Bonet and are protected under applicable intellectual property laws of the United States and Puerto Rico. By installing, copying, or otherwise using this software, you agree to be bound by the terms of this license.

1. Grant of License
Marc Bonet grants you a limited, non-exclusive, non-transferable, and revocable license to use this software solely for internal purposes and in accordance with the documentation provided. No other rights are granted.

2. Restrictions
You may not:
- Modify, adapt, translate, reverse engineer, decompile, or disassemble the software.
- Rent, lease, sublicense, distribute, or otherwise transfer the software to any third party.
- Remove or alter any proprietary notices or labels on the software.

3. Ownership
All rights, title, and interest in and to the software, including all intellectual property rights, remain exclusively with Marc Bonet. This license does not constitute a sale of the software or any of its components.

4. Disclaimer of Warranty
This software is provided "AS IS" without warranty of any kind, either express or implied, including but not limited to warranties of merchantability, fitness for a particular purpose, or non-infringement.

5. Limitation of Liability
In no event shall Marc Bonet be liable for any direct, indirect, incidental, special, or consequential damages arising out of the use or inability to use the software, even if Marc Bonet has been advised of the possibility of such damages.

6. Governing Law
This agreement shall be governed by and construed in accordance with the laws of the United States and the Commonwealth of Puerto Rico. Any disputes arising under or in connection with this license shall be subject to the exclusive jurisdiction of the courts located in Puerto Rico.
EOF
if [ $? -ne 0 ]; then
    echo "Failed to create license file"
    exit 1
fi


# Shared assets directory creation completed
echo "✅ Shared assets directory creation completed"


# ===========================================
# Docker (for docker-compose) directory
echo ""
echo ""
echo "📂 Creating docker (docker-compose) directory..."
mkdir -p docker || { echo "Failed to create docker (docker-compose) directory"; exit 1; }
cd docker || { echo "Failed to enter docker (docker-compose) directory"; exit 1; }
touch docker-compose.yml || { echo "Failed to create docker-compose.yml file"; exit 1; }
cd .. || { echo "Failed to enter parent directory"; exit 1; }
echo "✅ Docker (docker-compose) directory creation completed"



# codexAI workspace setup complete!
echo ""
echo ""
echo ""
echo ""
echo "✅ All done!"
echo "✅ codexAI workspace setup complete!"
echo ""
echo "In order to incorporate this project into your GitHub installation, please follow these steps:"
echo "  1. Create a new repository in GitLab."
echo "     This is performed in the GitLab web interface."
echo "       ** remember to get the repository URL! **"
echo "          This value should be in the format: https://github.com/marcb76/codexai.git"
echo "  2. Add the GitLab remote to your local repository."
echo "     This is performed in the command line: "
echo "       git remote add origin <repository-url>"
echo "       git add ."
echo "       git commit -m 'Initial commit'"
echo "  3. Push your changes to the GitLab repository."
echo "       git push --set-upstream origin main"
echo ""
echo "Have a nice day!"
echo ""
echo ""
echo ""
echo ""
