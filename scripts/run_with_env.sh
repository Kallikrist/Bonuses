#!/bin/bash
# Helper script to run Flutter app with environment variables from .env file
# Usage: ./scripts/run_with_env.sh [device_id]

# Check if .env file exists
if [ ! -f .env ]; then
    echo "❌ Error: .env file not found!"
    echo "📝 Please copy env.example to .env and fill in your credentials:"
    echo "   cp env.example .env"
    echo "   # Then edit .env with your actual Supabase credentials"
    exit 1
fi

# Load environment variables from .env file
export $(grep -v '^#' .env | xargs)

# Check if required variables are set
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
    echo "❌ Error: SUPABASE_URL or SUPABASE_ANON_KEY not set in .env file!"
    echo "📝 Please ensure your .env file contains:"
    echo "   SUPABASE_URL=https://your-project.supabase.co"
    echo "   SUPABASE_ANON_KEY=your_actual_anon_key_here"
    exit 1
fi

# Build dart-define flags
DART_DEFINES="--dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY"

# Optional: Add other environment variables if set
if [ ! -z "$DEMO_MODE" ]; then
    DART_DEFINES="$DART_DEFINES --dart-define=DEMO_MODE=$DEMO_MODE"
fi

if [ ! -z "$DEBUG_MODE" ]; then
    DART_DEFINES="$DART_DEFINES --dart-define=DEBUG_MODE=$DEBUG_MODE"
fi

# Publishable key only. Never pass STRIPE_SECRET_KEY into the app.
if [ ! -z "$STRIPE_PUBLISHABLE_KEY" ]; then
    DART_DEFINES="$DART_DEFINES --dart-define=STRIPE_PUBLISHABLE_KEY=$STRIPE_PUBLISHABLE_KEY"
fi

# Run Flutter app
if [ -z "$1" ]; then
    echo "🚀 Running Flutter app with environment variables..."
    flutter run $DART_DEFINES
else
    echo "🚀 Running Flutter app on device $1 with environment variables..."
    flutter run -d "$1" $DART_DEFINES
fi


