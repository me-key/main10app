#!/bin/bash

# 1. Find the current version line in pubspec.yaml
# It looks for something like 'version: 1.0.0+5'
VERSION_LINE=$(grep "version: " pubspec.yaml)

if [ -z "$VERSION_LINE" ]; then
    echo "Error: Could not find version line in pubspec.yaml"
    exit 1
fi

# 2. Extract the Name and Code
# version_name = 1.0.0, version_code = 5
VERSION_NAME=$(echo $VERSION_LINE | cut -d' ' -f2 | cut -d'+' -f1)
VERSION_CODE=$(echo $VERSION_LINE | cut -d'+' -f2)

# 3. Increment the Version Code
NEW_CODE=$((VERSION_CODE + 1))
NEW_VERSION="version: $VERSION_NAME+$NEW_CODE"

echo "Updating version from $VERSION_NAME+$VERSION_CODE to $VERSION_NAME+$NEW_CODE..."

# 4. Update the file (using sed)
# The '' is required for macOS compatibility; on Linux you can just use sed -i
sed -i "s/$VERSION_LINE/$NEW_VERSION/" pubspec.yaml

echo "Running Flutter commands..."

# 5. Run Flutter Commands
flutter clean && \
flutter pub get && \
flutter build appbundle

# 6. Check if build was successful
if [ $? -eq 0 ]; then
    echo "Build Successful! Opening Nautilus..."
    # 7. Open Nautilus at the AAB location
    nautilus build/app/outputs/bundle/release/
else
    echo "Build failed. Please check the logs above."
    exit 1
fi
