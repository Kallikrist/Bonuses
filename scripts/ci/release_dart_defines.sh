#!/usr/bin/env bash
# Shared flags for TestFlight / Firebase App Distribution builds.
#
# Source this file (do not execute it):
#   source scripts/ci/release_dart_defines.sh
#   flutter build apk --release --build-number="$RELEASE_BUILD_NUMBER" "${RELEASE_DART_DEFINES[@]}"
#
# Payments stay mock: DEMO_MODE is hardcoded true and Stripe keys are never passed.
# Do not add STRIPE_SECRET_KEY or STRIPE_PUBLISHABLE_KEY here.

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "Source this file: source scripts/ci/release_dart_defines.sh" >&2
  exit 1
fi

RELEASE_BUILD_NUMBER="${GITHUB_RUN_NUMBER:-1}"

RELEASE_DART_DEFINES=(
  --dart-define=DEMO_MODE=true
  --dart-define=DEBUG_MODE=false
)

if [[ -n "${SUPABASE_URL:-}" ]]; then
  RELEASE_DART_DEFINES+=(--dart-define=SUPABASE_URL="${SUPABASE_URL}")
fi

if [[ -n "${SUPABASE_ANON_KEY:-}" ]]; then
  RELEASE_DART_DEFINES+=(--dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}")
fi
