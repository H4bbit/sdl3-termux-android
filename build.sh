#!/data/data/com.termux/files/usr/bin/bash

set -e

APP_NAME="SDL3_Termux_Android"
NATIVE_LIB="sdl-android-app"

ANDROID_API=34
ANDROID_MIN_API=21
ANDROID_ABI=arm64-v8a

ANDROID_JAR="$ANDROID_HOME/platforms/android-${ANDROID_API}/android.jar"

JAVA17="$PREFIX/lib/jvm/java-17-openjdk"

NDK_TOOLCHAIN="$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake"

KEYSTORE="build/build-apk/debug.keystore"

# --------------------------------------------------
# Validation
# --------------------------------------------------

if [ ! -d vendor/SDL ]; then
    echo "Missing SDL dependency."
    echo
    echo "Clone SDL3 into vendor/SDL:"
    echo "git clone https://github.com/libsdl-org/SDL.git vendor/SDL"
    exit 1
fi

if [ ! -f "$KEYSTORE" ]; then
    echo "Missing debug.keystore"
    echo
    echo "Generate one with:"
    echo "./gen-debug-key.sh"
    exit 1
fi

# --------------------------------------------------
# Configure Native Build
# --------------------------------------------------

echo "[1/8] Configure Native Build"

if [ ! -f build-android/CMakeCache.txt ]; then
    cmake -S . -B build-android \
        -G Ninja \
        -DCMAKE_TOOLCHAIN_FILE="$NDK_TOOLCHAIN" \
        -DANDROID_ABI="$ANDROID_ABI" \
        -DANDROID_PLATFORM="$ANDROID_MIN_API"
fi

# --------------------------------------------------
# Native Build
# --------------------------------------------------

echo "[2/8] Native Build"

cmake --build build-android -j$(nproc)

# --------------------------------------------------
# Compile Java
# --------------------------------------------------

echo "[3/8] Compile Java"

rm -rf build-java/classes
mkdir -p build-java/classes

"$JAVA17/bin/javac" \
    --release 8 \
    -classpath "$ANDROID_JAR" \
    -d build-java/classes \
    $(find vendor/SDL/android-project/app/src/main/java -name "*.java") \
    $(find platform/android -name "*.java")

# --------------------------------------------------
# Dex
# --------------------------------------------------

echo "[4/8] Dex"

rm -rf build-java/dex
mkdir -p build-java/dex

d8 \
    --min-api "$ANDROID_MIN_API" \
    --lib "$ANDROID_JAR" \
    --output build-java/dex \
    $(find build-java/classes -name "*.class" | sort)

# --------------------------------------------------
# Compile Resources
# --------------------------------------------------

echo "[5/8] Compile Resources"

rm -rf build-apk/reszip
mkdir -p build-apk/reszip

aapt2 compile \
    --dir platform/android/app/res \
    -o build-apk/reszip/resources.zip

# --------------------------------------------------
# Link APK
# --------------------------------------------------

echo "[6/8] Link APK"

rm -rf build-apk/base
mkdir -p build-apk/base

aapt2 link \
    -I "$ANDROID_JAR" \
    --manifest platform/android/app/AndroidManifest.xml \
    -o build-apk/base/app-unsigned.apk \
    build-apk/reszip/resources.zip

# --------------------------------------------------
# Inject Native Libraries + Dex
# --------------------------------------------------

echo "[7/8] Inject Native + Dex"

rm -rf build-apk/inject
mkdir -p build-apk/inject/lib/${ANDROID_ABI}

cp build-android/lib${NATIVE_LIB}.so \
    build-apk/inject/lib/${ANDROID_ABI}/

cp \
"$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-aarch64/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so" \
build-apk/inject/lib/${ANDROID_ABI}/

cp build-java/dex/classes.dex \
    build-apk/inject/

(
    cd build-apk/inject
    zip -ur ../base/app-unsigned.apk .
)

# --------------------------------------------------
# Align + Sign APK
# --------------------------------------------------

echo "[8/8] Align + Sign APK"

rm -rf build-apk/final
mkdir -p build-apk/final

zipalign -f 4 \
    build-apk/base/app-unsigned.apk \
    build-apk/final/app-aligned.apk

apksigner sign \
    --ks "$KEYSTORE" \
    --ks-pass pass:android \
    --out build-apk/final/app-signed.apk \
    build-apk/final/app-aligned.apk

echo
echo "Build complete:"
echo "build-apk/final/app-signed.apk"
