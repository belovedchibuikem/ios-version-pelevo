#!/bin/bash

# Flutter iOS Build Fix for Codemagic
# This script fixes common iOS build issues

set -e

echo "🔧 Starting iOS build fix..."

# Clean Flutter
echo "🧹 Cleaning Flutter..."
flutter clean

# Get dependencies
echo "📦 Getting Flutter dependencies..."
flutter pub get

# Clean iOS build
echo "🧹 Cleaning iOS build..."
cd ios
rm -rf build/
rm -rf Pods/
rm -rf Podfile.lock

# Update CocoaPods
echo "📱 Updating CocoaPods..."
pod repo update
pod install --repo-update

# Go back to root
cd ..

# Precompile Flutter
echo "⚡ Precompiling Flutter..."
flutter precache --ios

# Build for iOS
echo "🚀 Building for iOS..."
flutter build ios --release --no-codesign

echo "✅ iOS build fix completed!"
