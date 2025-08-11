#!/bin/bash

# Diagnostic script for MCP configuration issues

echo "🔍 BulleoApp MCP Diagnostic Tool"
echo "================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project configuration
PROJECT_ID="doublenumerique-yann"

echo "${BLUE}📋 System Information:${NC}"
echo "  OS: $OSTYPE"
echo "  User: $USER"
echo "  Home: $HOME"
echo ""

# Check Node.js
echo "${BLUE}🟢 Node.js Check:${NC}"
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo "  ✅ Node.js installed: $NODE_VERSION"
else
    echo "  ${RED}❌ Node.js not found${NC}"
fi
echo ""

# Check gcloud
echo "${BLUE}☁️ Google Cloud CLI Check:${NC}"
if command -v gcloud &> /dev/null; then
    echo "  ✅ gcloud installed"
    CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null)
    echo "  Current project: $CURRENT_PROJECT"
    if [ "$CURRENT_PROJECT" != "$PROJECT_ID" ]; then
        echo "  ${YELLOW}⚠️  Project mismatch! Expected: $PROJECT_ID${NC}"
    fi
else
    echo "  ${RED}❌ gcloud not found${NC}"
fi
echo ""

# Check MCP installation
echo "${BLUE}📦 MCP Installation Check:${NC}"
MCP_DIR="$HOME/bulleoapp-mcp"
if [ -d "$MCP_DIR/google-cloud-mcp" ]; then
    echo "  ✅ MCP directory exists: $MCP_DIR/google-cloud-mcp"
    if [ -f "$MCP_DIR/google-cloud-mcp/dist/index.js" ]; then
        echo "  ✅ MCP build found"
    else
        echo "  ${RED}❌ MCP build not found (dist/index.js missing)${NC}"
        echo "  ${YELLOW}   Run: cd $MCP_DIR/google-cloud-mcp && npm run build${NC}"
    fi
else
    echo "  ${RED}❌ MCP not installed at $MCP_DIR${NC}"
fi
echo ""

# Check credentials
echo "${BLUE}🔑 Credentials Check:${NC}"
KEY_PATH="$HOME/.config/gcloud/bulleoapp-credentials.json"
if [ -f "$KEY_PATH" ]; then
    echo "  ✅ Service account key exists: $KEY_PATH"
    # Check if the key is valid JSON
    if python3 -m json.tool "$KEY_PATH" > /dev/null 2>&1; then
        echo "  ✅ Key is valid JSON"
        # Extract project ID from key
        KEY_PROJECT=$(python3 -c "import json; print(json.load(open('$KEY_PATH'))['project_id'])" 2>/dev/null)
        if [ "$KEY_PROJECT" ]; then
            echo "  Key project: $KEY_PROJECT"
            if [ "$KEY_PROJECT" != "$PROJECT_ID" ]; then
                echo "  ${YELLOW}⚠️  Key is for different project! Expected: $PROJECT_ID${NC}"
            fi
        fi
    else
        echo "  ${RED}❌ Key is not valid JSON${NC}"
    fi
else
    echo "  ${RED}❌ Service account key not found${NC}"
    echo "  ${YELLOW}   Expected at: $KEY_PATH${NC}"
fi

# Check default credentials
DEFAULT_CREDS="$HOME/.config/gcloud/application_default_credentials.json"
if [ -f "$DEFAULT_CREDS" ]; then
    echo "  ✅ Default credentials exist"
else
    echo "  ${YELLOW}⚠️  No default credentials (run: gcloud auth application-default login)${NC}"
fi
echo ""

# Check Claude configuration
echo "${BLUE}🤖 Claude Configuration Check:${NC}"

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

echo "  Config path: $CONFIG_FILE"

if [ -f "$CONFIG_FILE" ]; then
    echo "  ✅ Config file exists"
    
    # Check if it's valid JSON
    if python3 -m json.tool "$CONFIG_FILE" > /dev/null 2>&1; then
        echo "  ✅ Config is valid JSON"
        
        # Check if bulleoapp-gcp is configured
        if grep -q "bulleoapp-gcp" "$CONFIG_FILE"; then
            echo "  ✅ bulleoapp-gcp MCP is configured"
        else
            echo "  ${RED}❌ bulleoapp-gcp not found in config${NC}"
        fi
        
        # Display the config
        echo ""
        echo "  ${BLUE}Current configuration:${NC}"
        echo "  ----------------------------------------"
        cat "$CONFIG_FILE" | python3 -m json.tool
        echo "  ----------------------------------------"
    else
        echo "  ${RED}❌ Config is not valid JSON${NC}"
        echo "  Content:"
        cat "$CONFIG_FILE"
    fi
else
    echo "  ${RED}❌ Config file not found${NC}"
    echo "  ${YELLOW}   Creating config directory and file...${NC}"
    mkdir -p "$CONFIG_DIR"
    
    # Create the config
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
    echo "  ${GREEN}✅ Config file created${NC}"
fi
echo ""

# Test MCP server
echo "${BLUE}🧪 MCP Server Test:${NC}"
if [ -f "$MCP_DIR/google-cloud-mcp/dist/index.js" ]; then
    echo "  Testing MCP server..."
    cd "$MCP_DIR/google-cloud-mcp"
    
    # Set environment variables
    export GOOGLE_APPLICATION_CREDENTIALS="$KEY_PATH"
    export GCP_PROJECT_ID="$PROJECT_ID"
    
    # Try to run the server briefly
    timeout 2 node dist/index.js 2>&1 | head -5
    
    if [ $? -eq 124 ]; then
        echo "  ✅ MCP server starts successfully (timeout expected)"
    else
        echo "  ${YELLOW}⚠️  Check the output above for errors${NC}"
    fi
else
    echo "  ${RED}❌ Cannot test - MCP not built${NC}"
fi
echo ""

# Check if Claude is running
echo "${BLUE}💻 Claude Desktop Status:${NC}"
if [[ "$OSTYPE" == "darwin"* ]]; then
    if pgrep -x "Claude" > /dev/null; then
        echo "  ${YELLOW}⚠️  Claude is currently running${NC}"
        echo "  ${YELLOW}   You must completely quit Claude (Cmd+Q) and restart it${NC}"
    else
        echo "  ✅ Claude is not running (good for config changes)"
    fi
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if pgrep -f "claude" > /dev/null; then
        echo "  ${YELLOW}⚠️  Claude might be running${NC}"
        echo "  ${YELLOW}   Make sure to completely close Claude before restarting${NC}"
    else
        echo "  ✅ Claude is not running"
    fi
fi
echo ""

# Summary and recommendations
echo "${BLUE}📊 Summary & Recommendations:${NC}"
echo "================================="

ISSUES=0

# Check all requirements
if [ ! -f "$CONFIG_FILE" ]; then
    echo "${RED}❌ Issue $((++ISSUES)): Claude config file missing${NC}"
    echo "   Run: ./setup.sh"
fi

if [ ! -f "$KEY_PATH" ]; then
    echo "${RED}❌ Issue $((++ISSUES)): Service account key missing${NC}"
    echo "   Run: ./setup.sh"
fi

if [ ! -f "$MCP_DIR/google-cloud-mcp/dist/index.js" ]; then
    echo "${RED}❌ Issue $((++ISSUES)): MCP not built${NC}"
    echo "   Run: cd $MCP_DIR/google-cloud-mcp && npm run build"
fi

if [ "$CURRENT_PROJECT" != "$PROJECT_ID" ]; then
    echo "${YELLOW}⚠️  Issue $((++ISSUES)): Wrong GCP project${NC}"
    echo "   Run: gcloud config set project $PROJECT_ID"
fi

if [ $ISSUES -eq 0 ]; then
    echo "${GREEN}✅ Everything looks good!${NC}"
    echo ""
    echo "If MCP still doesn't appear in Claude:"
    echo "1. Make sure Claude is COMPLETELY closed (not just minimized)"
    echo "2. On macOS: Use Cmd+Q or Claude > Quit Claude"
    echo "3. Wait 5 seconds"
    echo "4. Restart Claude"
    echo "5. Look for the 🔨 icon in the text input area"
else
    echo ""
    echo "${YELLOW}Found $ISSUES issue(s) to fix${NC}"
fi

echo ""
echo "Need help? Visit: https://github.com/yannabadie/bulleoapp-mcp-config"