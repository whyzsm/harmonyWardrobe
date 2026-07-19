#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

BUNDLE_NAME="${BUNDLE_NAME:-io.wardrobe.tiny}"
ABILITY_NAME="${ABILITY_NAME:-EntryAbility}"
HAP_PATH="${HAP_PATH:-entry/build/default/outputs/default/entry-default-unsigned.hap}"
DEVICE_SCREENSHOT_PATH="${DEVICE_SCREENSHOT_PATH:-/data/local/tmp/harmony_wardrobe_emulator_debug.jpeg}"
SCREENSHOT_PATH="${SCREENSHOT_PATH:-/tmp/harmony_wardrobe_emulator_debug.jpeg}"

resolve_tool() {
  local explicit_path="$1"
  shift

  if [[ -n "$explicit_path" ]]; then
    if [[ -x "$explicit_path" ]]; then
      printf '%s\n' "$explicit_path"
      return 0
    fi

    printf 'Tool path is not executable: %s\n' "$explicit_path" >&2
    return 1
  fi

  for candidate in "$@"; do
    if [[ -n "$candidate" && -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

COMMAND_LINE_TOOLS="${DEVECO_COMMAND_LINE_TOOLS:-}"
DEFAULT_DEVECO_SDK_HOME="/Applications/DevEco-Studio.app/Contents/sdk"

if [[ -z "${DEVECO_SDK_HOME:-}" && -d "$DEFAULT_DEVECO_SDK_HOME" ]]; then
  export DEVECO_SDK_HOME="$DEFAULT_DEVECO_SDK_HOME"
fi

if [[ -n "${DEVECO_SDK_HOME:-}" && ! -d "$DEVECO_SDK_HOME" ]]; then
  echo "DEVECO_SDK_HOME is not a directory: $DEVECO_SDK_HOME" >&2
  exit 1
fi

HVIGORW="$(resolve_tool "${HVIGORW:-}" \
  "${COMMAND_LINE_TOOLS:+$COMMAND_LINE_TOOLS/bin/hvigorw}" \
  "/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw" \
  "$(command -v hvigorw 2>/dev/null || true)")" || {
  echo "Cannot find hvigorw. Set HVIGORW or DEVECO_COMMAND_LINE_TOOLS." >&2
  exit 1
}

HDC="$(resolve_tool "${HDC:-}" \
  "${COMMAND_LINE_TOOLS:+$COMMAND_LINE_TOOLS/sdk/default/openharmony/toolchains/hdc}" \
  "/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc" \
  "$(command -v hdc 2>/dev/null || true)")" || {
  echo "Cannot find hdc. Set HDC or DEVECO_COMMAND_LINE_TOOLS." >&2
  exit 1
}

run_hdc() {
  if [[ -n "${HDC_TARGET:-}" ]]; then
    "$HDC" -t "$HDC_TARGET" "$@"
  else
    "$HDC" "$@"
  fi
}

has_hdc_error() {
  printf '%s\n' "$1" | grep -Eiq '(^|[[:space:]])(error:|failed to|fail(ed)?|\\[Fail\\])'
}

run_hdc_checked() {
  local output
  local status

  set +e
  output="$(run_hdc "$@" 2>&1)"
  status=$?
  set -e

  printf '%s\n' "$output"

  if [[ "$status" -ne 0 ]] || has_hdc_error "$output"; then
    return 1
  fi

  return 0
}

echo "Using hvigorw: $HVIGORW"
echo "Using hdc: $HDC"
echo "Connected HDC targets:"
TARGETS="$("$HDC" list targets | sed '/^[[:space:]]*$/d')"
printf '%s\n' "$TARGETS"

if [[ -z "$TARGETS" || "$TARGETS" == *"[Empty]"* || "$TARGETS" == *"Empty"* ]]; then
  echo "No HDC target found. Start the HarmonyOS emulator in DevEco Studio first." >&2
  exit 1
fi

if [[ "${SKIP_BUILD:-0}" != "1" ]]; then
  echo "Building debug HAP for emulator..."
  "$HVIGORW" --mode module -p product=default -p module=entry@default assembleHap --no-daemon --no-incremental --no-parallel --stacktrace
else
  echo "Skipping build and reusing HAP: $HAP_PATH"
fi

if [[ ! -f "$HAP_PATH" ]]; then
  echo "HAP not found: $HAP_PATH" >&2
  exit 1
fi

echo "Installing HAP on emulator..."
set +e
INSTALL_OUTPUT="$(run_hdc install -r "$HAP_PATH" 2>&1)"
INSTALL_STATUS=$?
set -e
printf '%s\n' "$INSTALL_OUTPUT"

if printf '%s\n' "$INSTALL_OUTPUT" | grep -qi 'sign info inconsistent'; then
  if [[ "${RESET_APP_ON_SIGN_MISMATCH:-0}" == "1" ]]; then
    echo "Signature mismatch detected. Uninstalling the existing emulator app with keep-data and reinstalling because RESET_APP_ON_SIGN_MISMATCH=1."
    run_hdc uninstall -n "$BUNDLE_NAME" -k || true
    run_hdc_checked install -r "$HAP_PATH"
  else
    echo "Install failed because an existing emulator app uses different signing info." >&2
    echo "Re-run with RESET_APP_ON_SIGN_MISMATCH=1 to uninstall the old package with keep-data before reinstalling." >&2
    exit 1
  fi
elif [[ "$INSTALL_STATUS" -ne 0 ]] || has_hdc_error "$INSTALL_OUTPUT"; then
  echo "Install failed on the emulator." >&2
  exit 1
fi

echo "Starting $BUNDLE_NAME/$ABILITY_NAME..."
run_hdc shell hilog -r || true
run_hdc shell aa force-stop "$BUNDLE_NAME" || true
run_hdc_checked shell aa start -a "$ABILITY_NAME" -b "$BUNDLE_NAME"

sleep "${LAUNCH_WAIT_SECONDS:-4}"

if [[ "${SKIP_SCREENSHOT:-0}" != "1" ]]; then
  echo "Capturing emulator screenshot..."
  run_hdc shell snapshot_display -f "$DEVICE_SCREENSHOT_PATH"
  run_hdc file recv "$DEVICE_SCREENSHOT_PATH" "$SCREENSHOT_PATH"
  echo "Screenshot saved to $SCREENSHOT_PATH"
fi

echo "Emulator debug run complete."
