#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Firebase Deployment Script${NC}"
echo ""

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo -e "${RED}❌ Firebase CLI is not installed!${NC}"
    echo ""
    echo "Install it with:"
    echo "  npm install -g firebase-tools"
    exit 1
fi

# Check if user is logged in
if ! firebase projects:list &> /dev/null; then
    echo -e "${YELLOW}⚠️  Not logged in to Firebase. Please login first:${NC}"
    echo "  firebase login"
    exit 1
fi

# Check current Firebase project
CURRENT_PROJECT=$(firebase use 2>&1 | grep -oP '(?<=Using )\S+' || echo "")
if [ -z "$CURRENT_PROJECT" ]; then
    echo -e "${YELLOW}⚠️  No Firebase project selected.${NC}"
    echo "Selecting project from .firebaserc..."
    firebase use default || {
        echo -e "${RED}❌ Failed to select Firebase project${NC}"
        exit 1
    }
fi

echo -e "${GREEN}✅ Firebase CLI ready${NC}"
echo ""

# Check for environment variables
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
    echo -e "${YELLOW}⚠️  SUPABASE_URL or SUPABASE_ANON_KEY not set in environment${NC}"
    echo ""
    echo "Options:"
    echo "  1. Use default values from config (development)"
    echo "  2. Set environment variables now"
    echo "  3. Exit and set them manually"
    echo ""
    read -p "Choose option (1/2/3): " choice
    
    case $choice in
        1)
            echo -e "${BLUE}📝 Using default Supabase values from config${NC}"
            echo "   (These are the values in lib/config/supabase_config.dart)"
            ;;
        2)
            echo ""
            read -p "Enter SUPABASE_URL: " SUPABASE_URL
            read -p "Enter SUPABASE_ANON_KEY: " SUPABASE_ANON_KEY
            export SUPABASE_URL
            export SUPABASE_ANON_KEY
            echo -e "${GREEN}✅ Environment variables set${NC}"
            ;;
        3)
            echo "Exiting. Set environment variables and run again:"
            echo "  export SUPABASE_URL=\"https://your-project.supabase.co\""
            echo "  export SUPABASE_ANON_KEY=\"your-anon-key\""
            echo "  ./deploy.sh"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid choice. Exiting.${NC}"
            exit 1
            ;;
    esac
else
    echo -e "${GREEN}✅ Environment variables found${NC}"
    echo "  SUPABASE_URL: ${SUPABASE_URL:0:30}..."
    echo "  SUPABASE_ANON_KEY: ${SUPABASE_ANON_KEY:0:30}..."
fi

echo ""

# Generate build info with real metadata
echo -e "${BLUE}📝 Generating build info...${NC}"
if [ -f "$SCRIPT_DIR/generate_build_info.sh" ]; then
    bash "$SCRIPT_DIR/generate_build_info.sh"
    echo -e "${GREEN}✅ Build info generated${NC}"
else
    echo -e "${YELLOW}⚠️  generate_build_info.sh not found, skipping build info${NC}"
fi

# Stamp the deploy timestamp into build_info.dart BEFORE building
# so it gets compiled into the deployed app
DEPLOY_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
BUILD_INFO="$SCRIPT_DIR/lib/config/build_info.dart"
if [ -f "$BUILD_INFO" ]; then
    sed -i '' "s/deployTimestamp = '.*'/deployTimestamp = '$DEPLOY_TIMESTAMP'/" "$BUILD_INFO"
    echo -e "${GREEN}✅ Deploy timestamp set: $DEPLOY_TIMESTAMP${NC}"
fi

echo ""
echo -e "${BLUE}📦 Starting deployment...${NC}"
echo ""

# Deploy to Firebase Hosting
# The predeploy hook in firebase.json will automatically run build.sh
if firebase deploy --only hosting; then
    echo ""
    echo -e "${GREEN}✅ Deployment successful!${NC}"
    echo ""
    echo "Your app should be available at:"
    echo "  https://$(firebase use 2>&1 | grep -oP '(?<=Using )\S+' || echo 'your-project').web.app"
    echo "  https://$(firebase use 2>&1 | grep -oP '(?<=Using )\S+' || echo 'your-project').firebaseapp.com"
else
    echo ""
    echo -e "${RED}❌ Deployment failed!${NC}"
    echo "Check the error messages above for details."
    exit 1
fi

