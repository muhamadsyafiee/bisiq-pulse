#!/bin/sh
# Builds the Google Play AAB signed with the PULSE upload key.
# The keystore lives outside the repository; its password is read from the
# macOS Keychain (service "pulse-upload-keystore").
set -eu
cd "$(dirname "$0")/.."
FLUTTER="${FLUTTER:-flutter}"
PULSE_UPLOAD_KEYSTORE="${PULSE_UPLOAD_KEYSTORE:-$HOME/.config/pulse/upload-keystore.jks}"
PULSE_UPLOAD_PASSWORD="$(security find-generic-password -a pulse-upload -s pulse-upload-keystore -w)"
export PULSE_UPLOAD_KEYSTORE PULSE_UPLOAD_PASSWORD
"$FLUTTER" build appbundle --release --dart-define-from-file=config/pulse_billing.json
