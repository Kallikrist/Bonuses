#!/usr/bin/env bash
# BON-17: local/CI dependency freshness + pub advisory check.
# No secrets. Not a TestFlight/distribution step.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

mkdir -p build/audit

echo "::group::flutter pub get"
flutter pub get 2>&1 | tee build/audit/pub-get.txt
echo "::endgroup::"

if grep -Eiq \
  'Dependencies are affected by security advisories|[[:space:]]affected by advisory:' \
  build/audit/pub-get.txt; then
  echo "::error::Pub reported security advisories. See build/audit/pub-get.txt"
  exit 1
fi

echo "::group::flutter pub outdated"
flutter pub outdated 2>&1 | tee build/audit/pub-outdated.txt
echo "::endgroup::"

# dart pub audit exists on newer Dart SDKs; Flutter 3.27 / Dart 3.6 does not.
if dart pub help audit >/dev/null 2>&1; then
  echo "::group::dart pub audit"
  dart pub audit 2>&1 | tee build/audit/pub-audit.txt
  echo "::endgroup::"
else
  echo "dart pub audit not available on this SDK; pub get advisory text was checked."
fi
