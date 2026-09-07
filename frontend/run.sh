#!/usr/bin/env bash
# Dev helper for the MSS Flutter app (macOS / Linux / Git Bash / CI).
#
# Runs Flutter with the required build-time configuration so you never hit
#   "Missing build-time configuration: SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY".
# Connection values come from dart_defines.json (git-ignored); this script
# always passes --dart-define-from-file so you don't have to remember it.
#
# Usage:
#   ./run.sh                 # = ./run.sh run  (debug on the default device)
#   ./run.sh run-release
#   ./run.sh apk             # debug APK
#   ./run.sh apk-release     # release APK
#   ./run.sh appbundle       # release .aab for Play Store
#   ./run.sh web
#   ./run.sh analyze
#   ./run.sh test
set -euo pipefail
cd "$(dirname "$0")"

DEFINES="dart_defines.json"
EXAMPLE="dart_defines.example.json"

if [ ! -f "$DEFINES" ]; then
  if [ -f "$EXAMPLE" ]; then
    cp "$EXAMPLE" "$DEFINES"
    echo "Created $DEFINES from $EXAMPLE." >&2
    echo "Fill in the real SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY, then run again." >&2
  else
    echo "Missing $DEFINES (and no $EXAMPLE to copy from)." >&2
  fi
  exit 1
fi

FLAG="--dart-define-from-file=$DEFINES"
CMD="${1:-run}"

case "$CMD" in
  run)         exec flutter run "$FLAG" ;;
  run-release) exec flutter run --release "$FLAG" ;;
  apk)         exec flutter build apk --debug "$FLAG" ;;
  apk-release) exec flutter build apk --release "$FLAG" ;;
  appbundle)   exec flutter build appbundle --release "$FLAG" ;;
  web)         exec flutter build web --release "$FLAG" ;;
  analyze)     exec flutter analyze ;;
  test)        exec flutter test ;;
  *)
    echo "Unknown command: $CMD" >&2
    echo "Usage: ./run.sh [run|run-release|apk|apk-release|appbundle|web|analyze|test]" >&2
    exit 1
    ;;
esac
