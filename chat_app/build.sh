#!/bin/bash
set -e

echo "🚀 Starting Flutter web build for Vercel..."

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
  echo "📦 Flutter not found. Installing Flutter SDK..."
  
  # Install Flutter SDK
  FLUTTER_VERSION="3.24.0"
  FLUTTER_SDK_DIR="$HOME/.flutter"
  
  if [ ! -d "$FLUTTER_SDK_DIR" ]; then
    echo "Downloading Flutter SDK..."
    git clone --branch stable https://github.com/flutter/flutter.git "$FLUTTER_SDK_DIR" --depth 1
  fi
  
  # Add Flutter to PATH
  export PATH="$FLUTTER_SDK_DIR/bin:$PATH"
  
  # Accept licenses
  flutter doctor --android-licenses || true
fi

# Verify Flutter installation
flutter --version

# Get dependencies
echo "📚 Getting Flutter dependencies..."
flutter pub get

# Build web app with environment variables
echo "🔨 Building Flutter web app..."

# Check if environment variables are set
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
  echo "⚠️  Warning: SUPABASE_URL or SUPABASE_ANON_KEY not set. Using default values from config."
  flutter build web --release --base-href="/"
else
  echo "✅ Using environment variables for Supabase configuration"
  flutter build web --release \
    --base-href="/" \
    --dart-define=SUPABASE_URL="$SUPABASE_URL" \
    --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"
fi

echo "✅ Build completed successfully!"
echo "📦 Output directory: build/web"

