#!/bin/bash

# BulleoApp MCP Setup Script - Fixed for doublenumerique-yann

set -e

echo "🚀 Setting up BulleoApp MCP Configuration..."
echo "📍 Using GCP Project: doublenumerique-yann"

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
echo "${GREEN}🔐 Setting up GCP credentials for doublenumerique-yann...${NC}"
echo ""

# Set the project
PROJECT_ID="doublenumerique-yann"
FIREBASE_PROJECT_ID="doublenumerique-yann"

echo "Setting default project to $PROJECT_ID..."
gcloud config set project "$PROJECT_ID"

# Authenticate
echo "Authenticating with Google Cloud..."
gcloud auth application-default login

# Create service account
echo "🔑 Creating service account..."
SERVICE_ACCOUNT_NAME="bulleoapp-mcp"
SERVICE_ACCOUNT="$SERVICE_ACCOUNT_NAME@${PROJECT_ID}.iam.gserviceaccount.com"

gcloud iam service-accounts create $SERVICE_ACCOUNT_NAME \
    --display-name="BulleoApp MCP Service Account" \
    --project="$PROJECT_ID" 2>/dev/null || echo "Service account already exists"

# Grant necessary roles
echo "🎯 Granting IAM roles..."

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
echo "📥 Creating service account key..."

# Remove old key if exists
if [ -f "$KEY_PATH" ]; then
    echo "  Removing old key..."
    rm "$KEY_PATH"
fi

gcloud iam service-accounts keys create "$KEY_PATH" \
    --iam-account="$SERVICE_ACCOUNT" \
    --project="$PROJECT_ID"

echo "${GREEN}✅ Service account key created at: $KEY_PATH${NC}"

# Detect OS and set config path
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    CONFIG_DIR="$HOME/Library/Application Support/Claude"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    CONFIG_DIR="$HOME/.config/Claude"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
    # Windows
    CONFIG_DIR="$APPDATA/Claude"
else
    CONFIG_DIR="$HOME/.config/Claude"
fi

CONFIG_FILE="$CONFIG_DIR/claude_desktop_config.json"

echo ""
echo "📝 Configuring Claude Desktop..."
echo "Config directory: $CONFIG_DIR"
echo "Config file: $CONFIG_FILE"

# Create config directory if it doesn't exist
mkdir -p "$CONFIG_DIR"

# Backup existing config if it exists
if [ -f "$CONFIG_FILE" ]; then
    BACKUP_FILE="${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$CONFIG_FILE" "$BACKUP_FILE"
    echo "  ✅ Backed up existing config to: $BACKUP_FILE"
fi

# Create the configuration
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

echo "${GREEN}✅ Claude Desktop configuration created!${NC}"

# Verify the configuration
echo ""
echo "🔍 Verifying configuration..."
echo ""

if [ -f "$CONFIG_FILE" ]; then
    echo "✅ Config file exists at: $CONFIG_FILE"
    echo ""
    echo "📄 Configuration content:"
    echo "----------------------------------------"
    cat "$CONFIG_FILE"
    echo "----------------------------------------"
else
    echo "${RED}❌ Config file not found!${NC}"
fi

# Test the MCP server
echo ""
echo "🧪 Testing MCP setup..."
cd "$MCP_DIR/google-cloud-mcp"

# Check if the built file exists
if [ -f "dist/index.js" ]; then
    echo "✅ MCP server built successfully"
    
    # Try to run a basic test
    echo "Testing Node.js execution..."
    node -e "console.log('✅ Node.js is working')" && echo "${GREEN}✅ Basic test passed${NC}"
else
    echo "${RED}❌ MCP server build not found. Trying to rebuild...${NC}"
    npm run build
fi

echo ""
echo "${GREEN}🎉 Setup complete!${NC}"
echo ""
echo "⚠️  ${YELLOW}IMPORTANT: Claude Desktop Configuration${NC}"
echo "----------------------------------------"
echo ""
echo "1. ${YELLOW}Completely quit Claude Desktop${NC} (not just close the window)"
echo "   - On macOS: Cmd+Q or Claude > Quit Claude from menu bar"
echo "   - On Windows: Right-click system tray icon > Exit"
echo "   - On Linux: Close all Claude windows"
echo ""
echo "2. ${YELLOW}Restart Claude Desktop${NC}"
echo ""
echo "3. ${YELLOW}Check for MCP server:${NC}"
echo "   - Look for the hammer icon (🔨) in the text input area"
echo "   - Click it to see 'bulleoapp-gcp' in the list"
echo ""
echo "4. ${YELLOW}If MCP doesn't appear:${NC}"
echo "   a) Make sure Claude is completely closed (check Activity Monitor/Task Manager)"
echo "   b) Check the config file exists:"
echo "      cat \"$CONFIG_FILE\""
echo "   c) Try manually testing the MCP:"
echo "      cd $MCP_DIR/google-cloud-mcp"
echo "      npx @modelcontextprotocol/inspector node dist/index.js"
echo ""
echo "📊 Your GCP Project: ${GREEN}$PROJECT_ID${NC}"
echo "📁 MCP Installation: ${GREEN}$MCP_DIR${NC}"
echo "🔑 Credentials: ${GREEN}$KEY_PATH${NC}"
echo ""
echo "Example commands to try in Claude:"
echo "  - 'List my Cloud Storage buckets in doublenumerique-yann'"
echo "  - 'Show my Firestore collections'"
echo "  - 'List my GCP services'"
echo ""
echo "For troubleshooting, visit: https://github.com/yannabadie/bulleoapp-mcp-config"