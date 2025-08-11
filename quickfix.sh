#!/bin/bash

# Quick fix script for MCP configuration

echo "🔧 BulleoApp MCP Quick Fix"
echo "=========================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
PROJECT_ID="doublenumerique-yann"
MCP_DIR="$HOME/bulleoapp-mcp"
KEY_PATH="$HOME/.config/gcloud/bulleoapp-credentials.json"

# Detect OS and set config path
if [[ "$OSTYPE" == "darwin"* ]]; then
    CONFIG_DIR="$HOME/Library/Application Support/Claude"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    CONFIG_DIR="$HOME/.config/Claude"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
    CONFIG_DIR="$APPDATA/Claude"
else
    CONFIG_DIR="$HOME/.config/Claude"
fi

CONFIG_FILE="$CONFIG_DIR/claude_desktop_config.json"

echo "📍 Project: $PROJECT_ID"
echo "📁 MCP Dir: $MCP_DIR"
echo "🔑 Key Path: $KEY_PATH"
echo "📝 Config: $CONFIG_FILE"
echo ""

# Create config directory
echo "Creating config directory..."
mkdir -p "$CONFIG_DIR"

# Backup existing config if it exists
if [ -f "$CONFIG_FILE" ]; then
    BACKUP_FILE="${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$CONFIG_FILE" "$BACKUP_FILE"
    echo "✅ Backed up existing config to: $BACKUP_FILE"
fi

# Create the correct configuration
echo "Creating Claude configuration..."
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
        "FIREBASE_PROJECT_ID": "$PROJECT_ID"
      }
    }
  }
}
EOF

echo "${GREEN}✅ Configuration created successfully!${NC}"
echo ""
echo "📄 Configuration content:"
echo "=========================================="
cat "$CONFIG_FILE"
echo "=========================================="
echo ""

# Check if MCP is built
if [ ! -f "$MCP_DIR/google-cloud-mcp/dist/index.js" ]; then
    echo "${YELLOW}⚠️  MCP not built. Building now...${NC}"
    cd "$MCP_DIR/google-cloud-mcp"
    npm run build
    echo "${GREEN}✅ MCP built successfully${NC}"
fi

# Check if credentials exist
if [ ! -f "$KEY_PATH" ]; then
    echo "${YELLOW}⚠️  Service account key not found${NC}"
    echo "Creating service account key..."
    
    # Create service account
    gcloud iam service-accounts create bulleoapp-mcp \
        --display-name="BulleoApp MCP Service Account" \
        --project="$PROJECT_ID" 2>/dev/null || true
    
    # Create key
    mkdir -p "$(dirname "$KEY_PATH")"
    gcloud iam service-accounts keys create "$KEY_PATH" \
        --iam-account="bulleoapp-mcp@${PROJECT_ID}.iam.gserviceaccount.com" \
        --project="$PROJECT_ID"
    
    echo "${GREEN}✅ Service account key created${NC}"
fi

echo ""
echo "${GREEN}🎉 Quick fix complete!${NC}"
echo ""
echo "⚠️  ${YELLOW}IMPORTANT NEXT STEPS:${NC}"
echo "1. COMPLETELY quit Claude (not just close window)"
echo "   - macOS: Cmd+Q or Claude > Quit Claude"
echo "   - Windows: Right-click system tray > Exit"
echo ""
echo "2. Wait 5 seconds"
echo ""
echo "3. Restart Claude"
echo ""
echo "4. Look for the 🔨 icon in the text input area"
echo ""
echo "5. Click it to see 'bulleoapp-gcp' in the list"
echo ""
echo "If it still doesn't work, run: ./diagnose.sh"