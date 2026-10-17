#!/usr/bin/env bash
# Builds a signed iOS .ipa locally, the same way Codemagic's ios-testflight
# workflow does (flutter build ipa --release with a flavor and dart-defines).
#
# Usage:
#   tool/build_ipa.sh                          # production flavor, .env
#   tool/build_ipa.sh staging                  # staging flavor, .env
#   tool/build_ipa.sh development              # development flavor, dev.env
#
# Options:
#   --env FILE             dart-define file (default: .env, dev.env for development)
#   --build-number N       override the build number from pubspec.yaml
#   --build-name X.Y.Z     override the version name from pubspec.yaml
#   --export-method M      app-store (default), ad-hoc, development, enterprise
#   --check                run format, analyze and tests first (tool/ci_check.sh)
#   --open                 open the archive in Xcode's Organizer when done
#
# Signing is automatic (team UXZV3C926U), so Xcode must be signed in to an
# account on that team. For TestFlight the build number must be higher than
# the latest one uploaded; Codemagic sets it to latest + 1 on its own.

set -euo pipefail

cd "$(dirname "$0")/.."

FLAVOR="production"
ENV_FILE=""
BUILD_NUMBER=""
BUILD_NAME=""
EXPORT_METHOD="app-store"
CHECK=false
OPEN=false

usage() {
  # Print the header comment, stopping at the first line that isn't one.
  awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
  exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    production | staging | development) FLAVOR="$1" ;;
    --env) ENV_FILE="${2:?--env needs a file}"; shift ;;
    --build-number) BUILD_NUMBER="${2:?--build-number needs a value}"; shift ;;
    --build-name) BUILD_NAME="${2:?--build-name needs a value}"; shift ;;
    --export-method) EXPORT_METHOD="${2:?--export-method needs a value}"; shift ;;
    --check) CHECK=true ;;
    --open) OPEN=true ;;
    -h | --help) usage 0 ;;
    *)
      echo "Unknown argument: $1" >&2
      usage 2
      ;;
  esac
  shift
done

if [[ -z "$ENV_FILE" ]]; then
  [[ "$FLAVOR" == "development" ]] && ENV_FILE="dev.env" || ENV_FILE=".env"
fi
if [[ ! -f "$ENV_FILE" ]]; then
  echo "Env file '$ENV_FILE' not found (copy env.example to start one)." >&2
  exit 1
fi

env_value() { grep -m1 "^$1=" "$ENV_FILE" | cut -d= -f2- || true; }

missing=()
for key in SUPABASE_URL SUPABASE_ANON_KEY API_BASE_URL JAMENDO_CLIENT_ID; do
  [[ -n "$(env_value "$key")" ]] || missing+=("$key")
done
if [[ ${#missing[@]} -gt 0 ]]; then
  echo "$ENV_FILE is missing: ${missing[*]}" >&2
  exit 1
fi

# Without API_BASE_URL the app falls back to 127.0.0.1, which a phone can't reach.
api_base="$(env_value API_BASE_URL)"
if [[ "$api_base" =~ (127\.0\.0\.1|localhost) ]]; then
  echo "API_BASE_URL in $ENV_FILE points at $api_base; a device can't reach it." >&2
  exit 1
fi
[[ -n "$(env_value SENTRY_DSN)" ]] || echo "Warning: no SENTRY_DSN in $ENV_FILE; crash reporting is off." >&2

version="$(grep -m1 '^version:' pubspec.yaml | awk '{print $2}')"
name="${BUILD_NAME:-${version%%+*}}"
number="${BUILD_NUMBER:-${version##*+}}"

echo "Building $FLAVOR $name ($number) with $ENV_FILE, export: $EXPORT_METHOD"
echo "Backend: $api_base"

if $CHECK; then
  tool/ci_check.sh format analyze test
fi

flutter pub get
flutter build ipa --release \
  --flavor "$FLAVOR" \
  --target "lib/main_$FLAVOR.dart" \
  --dart-define-from-file="$ENV_FILE" \
  --build-name="$name" \
  --build-number="$number" \
  --export-method="$EXPORT_METHOD"

ipa="$(ls -t build/ios/ipa/*.ipa 2>/dev/null | head -1 || true)"
if [[ -z "$ipa" ]]; then
  echo "Build finished but no .ipa was exported; check signing in Xcode." >&2
  exit 1
fi

echo
echo "IPA: $ipa"
echo "Archive: build/ios/archive/Runner.xcarchive"
echo "Upload with the Transporter app, or Xcode > Organizer > Distribute App."

if $OPEN; then
  open build/ios/archive/Runner.xcarchive
fi
