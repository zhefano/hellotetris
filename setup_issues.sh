#!/bin/bash

echo "🚀 Setting up GitHub Issues for Hello Tetris"
echo "=============================================="

# Check if GitHub token is set
if [ -z "$GITHUB_TOKEN" ]; then
    echo ""
    echo "❌ GITHUB_TOKEN not found. Please set it up:"
    echo ""
    echo "1. Go to GitHub.com → Settings → Developer settings → Personal access tokens"
    echo "2. Generate new token with 'repo' permissions"
    echo "3. Copy the token and run:"
    echo "   export GITHUB_TOKEN=your_token_here"
    echo ""
    echo "Then run this script again."
    exit 1
fi

echo "✅ GitHub token found"
echo ""

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

echo "📋 Creating GitHub issues..."
echo ""

# Run the issue creation script
python3 create_issues.py

echo ""
echo "🎉 Issue creation complete!"
echo ""
echo "📊 Next steps:"
echo "1. Check your GitHub repository for the new issues"
echo "2. Review and assign issues as needed"
echo "3. Start working on high-priority issues first"
echo ""
echo "🔗 Repository: https://github.com/zhefano/hellotetris" 