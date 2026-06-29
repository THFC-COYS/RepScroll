#!/usr/bin/env bash
# Pre-launch checks before archiving RepScroll.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
FAIL=0

pass() { echo "  ✓ $1"; }
fail() { echo "  ✗ $1"; FAIL=1; }
warn() { echo "  ! $1"; }

echo "RepScroll preflight"
echo "==================="

# Xcode project loads
if xcodebuild -list -project RepScroll.xcodeproj >/dev/null 2>&1; then
  pass "Xcode project opens"
else
  fail "Xcode project is damaged — fix project.pbxproj"
fi

# App icon
ICON="$ROOT/RepScroll/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
if [[ -f "$ICON" ]]; then
  W=$(sips -g pixelWidth "$ICON" 2>/dev/null | awk '/pixelWidth/{print $2}')
  H=$(sips -g pixelHeight "$ICON" 2>/dev/null | awk '/pixelHeight/{print $2}')
  ALPHA=$(sips -g hasAlpha "$ICON" 2>/dev/null | awk '/hasAlpha/{print $2}')
  if [[ "$W" == "1024" && "$H" == "1024" ]]; then
    pass "App icon 1024×1024"
  else
    fail "App icon must be 1024×1024 (got ${W}×${H})"
  fi
  if [[ "$ALPHA" == "no" ]]; then
    pass "App icon has no alpha channel"
  else
    fail "App icon must not have transparency (App Store rejection)"
  fi
else
  fail "Missing AppIcon.png"
fi

# Required plist keys
for KEY in NSCameraUsageDescription NSUserNotificationsUsageDescription ITSAppUsesNonExemptEncryption; do
  if plutil -extract "$KEY" xml1 -o /dev/null "$ROOT/RepScroll/Resources/Info.plist" 2>/dev/null; then
    pass "Info.plist: $KEY"
  else
    fail "Info.plist missing $KEY"
  fi
done

# Legal pages
for PAGE in privacy.html terms.html; do
  if [[ -f "$ROOT/docs/$PAGE" ]]; then
    pass "docs/$PAGE exists"
  else
    fail "Missing docs/$PAGE"
  fi
done

# Metadata
if [[ -f "$ROOT/AppStore/metadata.json" ]]; then
  pass "App Store metadata.json"
else
  fail "Missing AppStore/metadata.json"
fi

# Signing
if [[ -n "${DEVELOPMENT_TEAM:-}" ]]; then
  pass "DEVELOPMENT_TEAM is set ($DEVELOPMENT_TEAM)"
else
  warn "DEVELOPMENT_TEAM not set — export before ./scripts/ship.sh"
fi

IDENTITIES=$(security find-identity -v -p codesigning 2>/dev/null | grep -c "valid identities" || true)
if security find-identity -v -p codesigning 2>/dev/null | grep -q "valid identities found"; then
  if security find-identity -v -p codesigning 2>/dev/null | head -1 | grep -q "0 valid"; then
    warn "No code signing certificates — sign into Xcode with Apple Developer account"
  else
    pass "Code signing identity available"
  fi
fi

# StoreKit product IDs match AppConfig
MONTHLY=$(grep monthlyProductID "$ROOT/RepScroll/Utilities/AppConfig.swift" | grep -o '"[^"]*"' | tr -d '"')
if grep -q "$MONTHLY" "$ROOT/Products.storekit"; then
  pass "StoreKit monthly product ID matches AppConfig"
else
  fail "Products.storekit monthly ID mismatch"
fi

echo ""
if [[ $FAIL -eq 0 ]]; then
  echo "Preflight passed. Ready to archive."
  exit 0
else
  echo "Preflight failed. Fix issues above before shipping."
  exit 1
fi