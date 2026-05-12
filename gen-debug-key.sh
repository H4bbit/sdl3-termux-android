#!/data/data/com.termux/files/usr/bin/bash

set -e

KEYSTORE_DIR="build/build-apk"
KEYSTORE_PATH="${KEYSTORE_DIR}/debug.keystore"

mkdir -p "$KEYSTORE_DIR"

if [ -f "$KEYSTORE_PATH" ]; then
    echo "debug.keystore already exists:"
    echo "$KEYSTORE_PATH"
    exit 0
fi

echo "Generating Android debug keystore..."

keytool -genkeypair \
    -v \
    -keystore "$KEYSTORE_PATH" \
    -storepass android \
    -alias androiddebugkey \
    -keypass android \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -dname "CN=Android Debug,O=Android,C=US"

echo
echo "Debug keystore created:"
echo "$KEYSTORE_PATH"
