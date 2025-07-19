#!/bin/bash

echo "🚀 Setting up GitHub Issues for Hello Tetris"
echo "=============================================="

# Check if Python and requests are available
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is required but not installed"
    exit 1
fi

echo "✅ Python 3 found"

# Check if requests library is available
if ! python3 -c "import requests" 2>/dev/null; then
    echo ""
    echo "📦 Installing requests library..."
    pip3 install requests
    if [ $? -ne 0 ]; then
        echo "❌ Failed to install requests library"
        echo "Please install it manually: pip3 install requests"
        exit 1
    fi
fi

echo "✅ Requests library available"
echo ""

# Make the script executable
chmod +x create_issues.py

echo "🔐 GitHub Token Setup"
echo "====================="
echo ""
echo "For security, we'll prompt for your GitHub token instead of using environment variables."
echo "Your token will NOT be saved or logged."
echo ""

# Prompt for GitHub token securely
read -s -p "Enter your GitHub Personal Access Token: " github_token
echo ""

if [ -z "$github_token" ]; then
    echo "❌ No token provided. Exiting."
    exit 1
fi

echo "✅ Token received"
echo ""

# Temporarily set the token for this session only
export GITHUB_TOKEN="$github_token"

echo "📋 Creating GitHub issues..."
echo ""

# Run the issue creation script
python3 create_issues.py

# Clear the token from environment immediately
unset GITHUB_TOKEN

echo ""
echo "🎉 Issue creation complete!"
echo ""
echo "📊 Next steps:"
echo "1. Check your GitHub repository for the new issues"
echo "2. Review and assign issues as needed"
echo "3. Start working on high-priority issues first"
echo ""
echo "🔗 Repository: https://github.com/zhefano/hellotetris"
echo ""
echo "🔒 Security note: Your token has been cleared from memory" 