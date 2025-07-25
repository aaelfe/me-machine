#!/bin/bash

# MeMachine iOS Setup Script
# This script helps you set up the iOS client with proper environment configuration

echo "🚀 MeMachine iOS Setup"
echo "====================="

CONFIG_DIR="iOS Client/Config"
CONFIG_FILE="$CONFIG_DIR/Config.xcconfig"
TEMPLATE_FILE="$CONFIG_DIR/Config.xcconfig.template"

# Check if we're in the right directory
if [ ! -d "iOS Client" ]; then
    echo "❌ Please run this script from the project root directory"
    exit 1
fi

# Create config from template if it doesn't exist
if [ ! -f "$CONFIG_FILE" ]; then
    echo "📝 Creating Config.xcconfig from template..."
    cp "$TEMPLATE_FILE" "$CONFIG_FILE"
    echo "✅ Config.xcconfig created"
else
    echo "ℹ️  Config.xcconfig already exists"
fi

echo ""
echo "🔧 Next Steps:"
echo "1. Edit '$CONFIG_FILE' with your actual Supabase credentials"
echo "2. Get your credentials from: https://app.supabase.com/project/your-project/settings/api"
echo "3. Add the Supabase Swift SDK to your Xcode project"
echo "4. Run your database migration: cd backend && supabase migration up"
echo "5. Start your FastAPI backend: cd backend && python -m uvicorn main:app --reload"
echo ""
echo "📖 For detailed instructions, see: iOS Client/SETUP.md"
echo ""

# Check if Supabase CLI is available
if command -v supabase &> /dev/null; then
    echo "✅ Supabase CLI found"
    
    # Check if we're in a Supabase project
    if [ -f "backend/supabase/config.toml" ]; then
        echo "✅ Supabase project detected"
        echo "💡 You can run 'cd backend && supabase start' to start local development"
    fi
else
    echo "⚠️  Supabase CLI not found. Install it from: https://supabase.com/docs/guides/cli"
fi

echo ""
echo "🎉 Setup complete! Open the project in Xcode and build."