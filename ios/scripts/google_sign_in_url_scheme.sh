#!/bin/sh
# Registers Google Sign-In's redirect URL scheme (the reversed iOS client ID)
# in the built Info.plist, from GOOGLE_IOS_CLIENT_ID in the dart-defines
# (--dart-define or --dart-define-from-file). Without it the build is left
# alone and the app hides the Google button.
set -eu

client_id=""
for define in $(echo "${DART_DEFINES:-}" | tr ',' ' '); do
  pair=$(echo "$define" | base64 --decode)
  case "$pair" in
    GOOGLE_IOS_CLIENT_ID=*) client_id="${pair#GOOGLE_IOS_CLIENT_ID=}" ;;
  esac
done

if [ -z "$client_id" ]; then
  echo "GOOGLE_IOS_CLIENT_ID not set; skipping the Google Sign-In URL scheme"
  exit 0
fi

# 1234-abc.apps.googleusercontent.com -> com.googleusercontent.apps.1234-abc
scheme="com.googleusercontent.apps.${client_id%.apps.googleusercontent.com}"
plist="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"

if /usr/libexec/PlistBuddy -c "Print :CFBundleURLTypes" "$plist" | grep -q "$scheme"; then
  exit 0
fi
/usr/libexec/PlistBuddy \
  -c "Add :CFBundleURLTypes: dict" \
  -c "Add :CFBundleURLTypes:1:CFBundleURLSchemes array" \
  -c "Add :CFBundleURLTypes:1:CFBundleURLSchemes:0 string $scheme" \
  "$plist"
echo "Registered Google Sign-In URL scheme $scheme"
