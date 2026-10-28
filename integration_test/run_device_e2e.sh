#!/usr/bin/env bash
# TEST-ONLY: runs integration_test/e2e_journeys_test.dart on an Android
# emulator against the LOCAL Firebase emulators and saves an adb screenshot
# for every "SHOT:<name>" line the test prints.
#
# Prereqs (see the header of e2e_journeys_test.dart):
#   - emulators running: firebase emulators:start --only auth,firestore,storage,functions
#       --project moyoapptanzania-cf0e7   (run it logged-out, e.g. XDG_CONFIG_HOME=<empty dir>,
#       so nothing can reach production; functions/.env.local + .secret.local provide
#       ADMIN_EMAILS / a dummy CLICKPESA_API_KEY for the emulator)
#   - seeded: FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 \
#             node functions/test/device/seed-device-e2e.js
#
# Usage: bash integration_test/run_device_e2e.sh [device-serial] [screenshot-dir]
set -u
SERIAL="${1:-emulator-5554}"
SHOTS="${2:-./build/device-shots}"
ADB="${ADB:-$LOCALAPPDATA/Android/Sdk/platform-tools/adb.exe}"
mkdir -p "$SHOTS"
cd "$(dirname "$0")/.."

flutter test integration_test/e2e_journeys_test.dart -d "$SERIAL" \
  --dart-define=USE_FIREBASE_EMULATORS=true 2>&1 |
while IFS= read -r line; do
  printf '%s\n' "$line"
  case "$line" in
    *SHOT:*)
      name="${line##*SHOT:}"; name="${name//[^A-Za-z0-9_-]/}"
      "$ADB" -s "$SERIAL" exec-out screencap -p > "$SHOTS/$name.png" && echo "[shot] $SHOTS/$name.png"
      ;;
  esac
done
exit "${PIPESTATUS[0]}"
