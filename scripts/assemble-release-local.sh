#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_PROFILE="$PROJECT_ROOT/build-profile.json5"
LOCAL_SIGNING_PROFILE="$PROJECT_ROOT/signature/build-profile.signing.json5"
HVIGORW="${HVIGORW:-}"

if [[ -z "$HVIGORW" || ! -x "$HVIGORW" ]]; then
  echo 'Set HVIGORW to the executable DevEco hvigorw path.' >&2
  exit 1
fi

if [[ -z "${DEVECO_SDK_HOME:-}" || ! -d "$DEVECO_SDK_HOME" ]]; then
  echo 'Set DEVECO_SDK_HOME to the DevEco SDK directory that contains default/.' >&2
  exit 1
fi

if [[ ! -f "$LOCAL_SIGNING_PROFILE" ]]; then
  echo "Missing local signing profile: $LOCAL_SIGNING_PROFILE" >&2
  exit 1
fi

SAFE_PROFILE="$(mktemp "$PROJECT_ROOT/.build-profile.XXXXXX")"
cp "$BUILD_PROFILE" "$SAFE_PROFILE"

restore_profile() {
  cp "$SAFE_PROFILE" "$BUILD_PROFILE"
  rm -f "$SAFE_PROFILE"
}
trap restore_profile EXIT

cp "$LOCAL_SIGNING_PROFILE" "$BUILD_PROFILE"
"$HVIGORW" assembleApp -p product=default -p buildMode=release --no-daemon --no-incremental --no-parallel --stacktrace
