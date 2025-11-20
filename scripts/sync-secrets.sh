#!/bin/bash
# sync-secrets.sh - Add secrets to all Python repos
# For personal GitHub accounts without organization-level secrets

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔐 GitHub Secrets Sync Tool${NC}"
echo "=========================="
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ GitHub CLI not found${NC}"
    echo ""
    echo "Install GitHub CLI:"
    echo "  macOS:  brew install gh"
    echo "  Linux:  sudo apt install gh"
    echo "  Other:  https://cli.github.com/manual/installation"
    exit 1
fi

# Check authentication
if ! gh auth status &> /dev/null; then
    echo -e "${YELLOW}⚠️  Not authenticated with GitHub${NC}"
    echo ""
    echo "Please authenticate:"
    echo "  gh auth login"
    echo ""
    exit 1
fi

# Get username
USERNAME=$(gh api user -q .login)
echo -e "📝 User: ${GREEN}$USERNAME${NC}"
echo ""

# Fetch all Python repos
echo "🔍 Finding Python repositories..."
REPOS=$(gh repo list "$USERNAME" --limit 100 --json name,primaryLanguage -q '.[] | select(.primaryLanguage.name == "Python") | .name')

if [ -z "$REPOS" ]; then
    echo -e "${RED}❌ No Python repositories found${NC}"
    echo ""
    echo "This script only syncs secrets to Python repositories."
    echo "To sync to all repos, remove the language filter in the script."
    exit 1
fi

# Convert to array
readarray -t REPO_ARRAY <<< "$REPOS"
echo -e "${GREEN}✅ Found ${#REPO_ARRAY[@]} Python repositories${NC}"
echo ""

# Prompt for secret name
read -p "Secret name (e.g., QLTY_TOKEN, CODECOV_TOKEN): " SECRET_NAME
if [ -z "$SECRET_NAME" ]; then
    echo -e "${RED}❌ Secret name required${NC}"
    exit 1
fi

# Prompt for secret value (hidden input)
echo -n "Secret value (hidden): "
read -s SECRET_VALUE
echo ""

if [ -z "$SECRET_VALUE" ]; then
    echo -e "${RED}❌ Secret value required${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}📋 Will add secret '${SECRET_NAME}' to ${#REPO_ARRAY[@]} repositories:${NC}"
for repo in "${REPO_ARRAY[@]}"; do
    echo "  - $USERNAME/$repo"
done
echo ""

read -p "Continue? (y/N): " CONFIRM
if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
    echo "Aborted"
    exit 0
fi

echo ""
echo "🚀 Adding secrets..."
echo ""

SUCCESS=0
FAILED=0
FAILED_REPOS=()

for repo in "${REPO_ARRAY[@]}"; do
    FULL_REPO="$USERNAME/$repo"
    printf "  %-50s ... " "$repo"

    if gh secret set "$SECRET_NAME" \
        --repo "$FULL_REPO" \
        --body "$SECRET_VALUE" 2>/dev/null; then
        echo -e "${GREEN}✅${NC}"
        ((SUCCESS++))
    else
        echo -e "${RED}❌${NC}"
        ((FAILED++))
        FAILED_REPOS+=("$repo")
    fi
done

echo ""
echo "=========================="
echo -e "${GREEN}✅ Success: $SUCCESS/${#REPO_ARRAY[@]}${NC}"

if [ $FAILED -gt 0 ]; then
    echo -e "${RED}❌ Failed: $FAILED/${#REPO_ARRAY[@]}${NC}"
    echo ""
    echo "Failed repositories:"
    for repo in "${FAILED_REPOS[@]}"; do
        echo "  - $repo"
    done
fi

echo ""
echo -e "${BLUE}Done!${NC}"
