#!/usr/bin/env bash
# Fix "No simulator runtime version" build errors on Xcode 26 beta.
# Run once after installing Xcode or iOS simulators.

set -euo pipefail

echo "==> Mapping iphoneos26.5 SDK to installed iOS simulator runtime"
xcrun simctl runtime scan-and-mount 2>/dev/null || true

# Xcode 26.5 SDK (23F81a) + iOS 27.0 beta simulator (24A5370g) mismatch
if xcrun simctl runtime match list 2>/dev/null | grep -q iphoneos26.5; then
  xcrun simctl runtime match set iphoneos26.5 24A5370g --sdkBuild 23F81a 2>/dev/null || \
  xcrun simctl runtime match set iphoneos26.5 23F77 --sdkBuild 23F81a 2>/dev/null || true
fi

echo "==> Installed simulator runtimes:"
xcrun simctl list runtimes 2>/dev/null | grep iOS || true

echo ""
echo "If build still fails, install iOS 26.5 Simulator:"
echo "  Xcode → Settings → Platforms → iOS 26.5 → GET"
echo "Or use a physical iPhone as run destination."