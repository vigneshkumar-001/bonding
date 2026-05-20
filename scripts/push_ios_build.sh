#!/usr/bin/env bash
set -euo pipefail

BUILD_NUMBER="${1:-8}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXPORT_PLIST="/tmp/twoofus_export_options.plist"

cd "$ROOT_DIR"

echo "Setting iOS build number to 1.0.0+$BUILD_NUMBER"
/usr/bin/perl -0pi -e "s/^version:\\s*1\\.0\\.0\\+\\d+/version: 1.0.0+$BUILD_NUMBER/m" pubspec.yaml

echo "Creating App Store export options"
rm -f "$EXPORT_PLIST"
/usr/libexec/PlistBuddy -c "Add :destination string export" "$EXPORT_PLIST"
/usr/libexec/PlistBuddy -c "Add :method string app-store-connect" "$EXPORT_PLIST"
/usr/libexec/PlistBuddy -c "Add :signingStyle string automatic" "$EXPORT_PLIST"
/usr/libexec/PlistBuddy -c "Add :stripSwiftSymbols bool true" "$EXPORT_PLIST"
/usr/libexec/PlistBuddy -c "Add :teamID string R28H4GRQ8K" "$EXPORT_PLIST"

echo "Refreshing Flutter and CocoaPods dependencies"
flutter config --no-enable-swift-package-manager
flutter pub get
(cd ios && pod install)

echo "Building IPA for App Store Connect"
flutter build ipa --release --export-options-plist="$EXPORT_PLIST"

IPA_PATH="$ROOT_DIR/build/ios/ipa/Twoofus.ipa"
echo "Opening IPA in Transporter: $IPA_PATH"
open -a Transporter "$IPA_PATH"

echo "Done. In Transporter, click Deliver."
