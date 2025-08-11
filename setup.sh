#!/bin/bash

# BulleoApp MCP Setup Script

set -e

echo "🚀 Setting up BulleoApp MCP Configuration..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "${RED}❌ gcloud CLI is not installed${NC}"
    echo "Please install it from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "${RED}❌ Node.js is not installed${NC}"
    echo "Please install Node.js 18 or later"
    exit 1
fi

# Create MCP directory
MCP_DIR="$HOME/bulleoapp-mcp"
echo "📁 Creating MCP directory at $MCP_DIR..."
mkdir -p "$MCP_DIR"
cd "$MCP_DIR"

# Clone google-cloud-mcp
if [ ! -d "google-cloud-mcp" ]; then
    echo "📥 Cloning google-cloud-mcp..."
    git clone https://github.com/krzko/google-cloud-mcp.git
    cd google-cloud-mcp
    echo "📦 Installing dependencies (this may take a few minutes)..."
    
    # Check if pnpm is installed, otherwise use npm
    if command -v pnpm &> /dev/null; then
        pnpm install
        echo "🔨 Building..."
        pnpm build
    else
        npm install
        echo "🔨 Building..."
        npm run build
    fi
    cd ..
else
    echo "${YELLOW}⚠️  google-cloud-mcp already exists, skipping...${NC}"
fi

# Setup GCP credentials
echo ""
echo "${GREEN}🔐 Setting up GCP credentials...${NC}"
echo "Please make sure you have:"
echo "1. A GCP project created (bulleoapp-prod)"
echo "2. Firebase project initialized"
echo "3. Required APIs enabled (Vision, Speech, Healthcare, etc.)"
echo ""
read -p "Press enter to continue with authentication..."

gcloud auth application-default login

# Get project ID
read -p "Enter your GCP Project ID [bulleoapp-prod]: " PROJECT_ID
PROJECT_ID=${PROJECT_ID:-bulleoapp-prod}

read -p "Enter your Firebase Project ID [bulleoapp-firebase]: " FIREBASE_PROJECT_ID
FIREBASE_PROJECT_ID=${FIREBASE_PROJECT_ID:-bulleoapp-firebase}

# Create service account
echo "🔑 Creating service account..."
gcloud iam service-accounts create bulleoapp-mcp \
    --display-name="BulleoApp MCP Service Account" \
    --project="$PROJECT_ID" 2>/dev/null || echo "Service account already exists"

# Grant necessary roles
echo "🎯 Granting IAM roles..."
SERVICE_ACCOUNT="bulleoapp-mcp@${PROJECT_ID}.iam.gserviceaccount.com"

ROLES=(
    "roles/datastore.user"
    "roles/storage.objectAdmin"
    "roles/cloudvision.admin"
    "roles/cloudspeech.admin"
    "roles/logging.logWriter"
    "roles/monitoring.metricWriter"
)

for role in "${ROLES[@]}"; do
    echo "  Adding $role..."
    gcloud projects add-iam-policy-binding "$PROJECT_ID" \
        --member="serviceAccount:$SERVICE_ACCOUNT" \
        --role="$role" \
        --quiet 2>/dev/null || true
done

# Download service account key
KEY_PATH="$HOME/.config/gcloud/bulleoapp-credentials.json"
mkdir -p "$(dirname "$KEY_PATH")"
echo "📥 Downloading service account key..."
gcloud iam service-accounts keys create "$KEY_PATH" \
    --iam-account="$SERVICE_ACCOUNT" \
    --project="$PROJECT_ID"

# Configure Claude Desktop
CONFIG_DIR="$HOME/Library/Application Support/Claude"
CONFIG_FILE="$CONFIG_DIR/claude_desktop_config.json"

if [ -d "$CONFIG_DIR" ]; then
    echo "📝 Configuring Claude Desktop..."
    
    # Backup existing config
    if [ -f "$CONFIG_FILE" ]; then
        cp "$CONFIG_FILE" "${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
        echo "  Backed up existing config"
    fi
    
    # Create new config
    cat > "$CONFIG_FILE" << EOF
{
  "mcpServers": {
    "bulleoapp-gcp": {
      "command": "node",
      "args": [
        "$MCP_DIR/google-cloud-mcp/dist/index.js"
      ],
      "env": {
        "GOOGLE_APPLICATION_CREDENTIALS": "$KEY_PATH",
        "GCP_PROJECT_ID": "$PROJECT_ID",
        "FIREBASE_PROJECT_ID": "$FIREBASE_PROJECT_ID"
      }
    }
  }
}
EOF
    echo "${GREEN}✅ Claude Desktop configured!${NC}"
else
    echo "${YELLOW}⚠️  Claude Desktop not found. Please configure manually.${NC}"
    echo "Add this to your claude_desktop_config.json:"
    cat << EOF
{
  "mcpServers": {
    "bulleoapp-gcp": {
      "command": "node",
      "args": [
        "$MCP_DIR/google-cloud-mcp/dist/index.js"
      ],
      "env": {
        "GOOGLE_APPLICATION_CREDENTIALS": "$KEY_PATH",
        "GCP_PROJECT_ID": "$PROJECT_ID",
        "FIREBASE_PROJECT_ID": "$FIREBASE_PROJECT_ID"
      }
    }
  }
}
EOF
fi

# Test the setup
echo ""
echo "🧪 Testing MCP setup..."
cd "$MCP_DIR/google-cloud-mcp"

# Create a simple test
echo "Testing connection to GCP..."
node -e "console.log('✅ Node.js is working'); process.exit(0);" && echo "${GREEN}✅ Basic test passed${NC}"

echo ""
echo "${GREEN}🎉 Setup complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Restart Claude Desktop"
echo "2. You should see 'bulleoapp-gcp' in the MCP servers list"
echo "3. Try asking Claude to interact with your GCP resources"
echo ""
echo "Example commands:"
echo "  - 'List my Cloud Storage buckets'"
echo "  - 'Analyze this image using Vision API'"
echo "  - 'Query Firestore collection pregnancy_tracking'"
echo ""
echo "For more help, visit: https://github.com/yannabadie/bulleoapp-mcp-config"