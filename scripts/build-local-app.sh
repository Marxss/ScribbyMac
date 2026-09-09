#!/bin/bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
xcodebuild -project "$PROJECT_ROOT/ScribbyMac.xcodeproj" -scheme ScribbyMac \
  -configuration Release -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath "$PROJECT_ROOT/build/DerivedData" \
  CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO build
mkdir -p "$PROJECT_ROOT/dist"
ditto "$PROJECT_ROOT/build/DerivedData/Build/Products/Release/ScribbyMac.app" "$PROJECT_ROOT/dist/ScribbyMac.app"
codesign --force --deep --sign - "$PROJECT_ROOT/dist/ScribbyMac.app"
codesign --verify --deep --strict "$PROJECT_ROOT/dist/ScribbyMac.app"
printf '%s\n' "$PROJECT_ROOT/dist/ScribbyMac.app"
