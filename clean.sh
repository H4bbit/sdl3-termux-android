#!/data/data/com.termux/files/usr/bin/bash

set -e

echo "[1/4] Cleaning native build"
rm -rf build-android

echo "[2/4] Cleaning Java build"
rm -rf build-java

echo "[3/4] Cleaning APK intermediates"
rm -rf \
    build-apk/base \
    build-apk/final \
    build-apk/inject \
    build-apk/reszip

echo "[4/4] Cleaning temporary artifacts"

find . -name "*.idsig" -delete
find . -name "*.apk" -delete

echo
echo "Clean complete."
