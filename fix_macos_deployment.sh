#!/bin/bash

echo "🔧 Fixing macOS deployment target..."

# Update Podfile
sed -i '' 's/platform :osx, '\''10.14'\''/platform :osx, '\''10.15'\''/g' macos/Podfile

# Update Xcode project file
sed -i '' 's/MACOSX_DEPLOYMENT_TARGET = 10.14/MACOSX_DEPLOYMENT_TARGET = 10.15/g' macos/Runner.xcodeproj/project.pbxproj

echo "✅ macOS deployment target updated to 10.15"
echo "📱 Now you can run: flutter run -d macos"
