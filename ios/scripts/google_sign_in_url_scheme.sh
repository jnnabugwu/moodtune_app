#!/bin/sh
# Registers Google Sign-In's redirect URL scheme (the reversed iOS client ID)
# in the built Info.plist, from GOOGLE_IOS_CLIENT_ID in the dart-defines
# (--dart-define or --dart-define-from-file). Without it the app hides the
# Google button and no scheme is registered.
set -eu

plist="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
buddy=/usr/libexec/PlistBuddy

client_id=""
for define in $(echo "${DART_DEFINES:-}" | tr ',' ' '); do
  pair=$(echo "$define" | base64 --decode)
  case "$pair" in
    GOOGLE_IOS_CLIENT_ID=*) client_id="${pair#GOOGLE_IOS_CLIENT_ID=}" ;;
  esac
done

# Drop any scheme an earlier build registered, so a changed or removed client
# ID never leaves a stale entry behind in a reused build directory.
i=0
while scheme=$("$buddy" -c "Print :CFBundleURLTypes:$i:CFBundleURLSchemes:0" "$plist" 2>/dev/null); do
  case "$scheme" in
    com.googleusercontent.apps.*) "$buddy" -c "Delete :CFBundleURLTypes:$i" "$plist" ;;
    *) i=$((i + 1)) ;;
  esac
done

if [ -z "$client_id" ]; then
  echo "GOOGLE_IOS_CLIENT_ID not set; skipping the Google Sign-In URL scheme"
  exit 0
fi

# 1234-abc.apps.googleusercontent.com -> com.googleusercontent.apps.1234-abc
scheme="com.googleusercontent.apps.${client_id%.apps.googleusercontent.com}"
"$buddy" \
  -c "Add :CFBundleURLTypes:$i dict" \
  -c "Add :CFBundleURLTypes:$i:CFBundleURLSchemes array" \
  -c "Add :CFBundleURLTypes:$i:CFBundleURLSchemes:0 string $scheme" \
  "$plist"
echo "Registered Google Sign-In URL scheme $scheme"
