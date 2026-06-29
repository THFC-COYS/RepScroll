#!/usr/bin/env bash
# Archive RepScroll and upload to App Store Connect.
# Usage: DEVELOPMENT_TEAM=XXXXXXXXXX ./scripts/ship.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

TEAM_ID="${DEVELOPMENT_TEAM:-}"
if [[ -z "$TEAM_ID" ]]; then
  echo "error: set DEVELOPMENT_TEAM to your 10-character Apple Team ID"
  echo "  export DEVELOPMENT_TEAM=XXXXXXXXXX"
  exit 1
fi

SCHEME="RepScroll"
ARCHIVE_PATH="$ROOT/build/RepScroll.xcarchive"
EXPORT_DIR="$ROOT/build/export"
EXPORT_PLIST="$ROOT/build/ExportOptions.plist"
mkdir -p "$ROOT/build"

# Inject team ID into export options
sed "s/REPLACE_WITH_TEAM_ID/$TEAM_ID/g" "$ROOT/AppStore/ExportOptions.plist" > "$EXPORT_PLIST"

echo "==> Archiving $SCHEME (team: $TEAM_ID)"
xcodebuild archive \
  -project RepScroll.xcodeproj \
  -scheme "$SCHEME" \
  -configuration Release \
  -archivePath "$ARCHIVE_PATH" \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  -allowProvisioningUpdates \
  | xcbeautify 2>/dev/null || cat

echo "==> Exporting & uploading to App Store Connect"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist "$EXPORT_PLIST" \
  -allowProvisioningUpdates \
  | xcbeautify 2>/dev/null || cat

echo ""
echo "Done. Check App Store Connect → TestFlight for processing status."
echo "Review notes: AppStore/REVIEW_NOTES.txt"
echo "Checklist:    AppStore/MORNING_SHIP.md"