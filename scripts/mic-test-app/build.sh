#!/bin/bash
set -euo pipefail
# Run on the prepared Android build machine. No proprietary input or signing secret
# is copied to the repository; this diagnostic uses the public AOSP test certificate.
android_root="${1:?Usage: build.sh ANDROID_SOURCE_ROOT}"
test_source="$(cd "$(dirname "$0")" && pwd)"
test_output="$(mktemp -d /tmp/athena-mic-app.XXXXXX)"
java_bin="$android_root/prebuilts/jdk/jdk11/linux-x86/bin"
sdk_jar="$android_root/prebuilts/sdk/30/public/android.jar"
mkdir -p "$test_output/classes" "$test_output/dex"
"$java_bin/javac" -source 8 -target 8 -cp "$sdk_jar" \
    -d "$test_output/classes" "$test_source/MicTestActivity.java"
"$java_bin/java" -cp "$android_root/prebuilts/r8/r8.jar" com.android.tools.r8.D8 \
    --lib "$sdk_jar" --min-api 30 --output "$test_output/dex" \
    "$test_output/classes/org/lineageos/athena/mictest/MicTestActivity.class"
"$android_root/out/host/linux-x86/bin/aapt2" link -I "$sdk_jar" \
    --manifest "$test_source/AndroidManifest.xml" -o "$test_output/unsigned.apk"
(cd "$test_output/dex" && "$java_bin/jar" uf "$test_output/unsigned.apk" classes.dex)
"$android_root/prebuilts/sdk/tools/linux/bin/zipalign" -f 4 \
    "$test_output/unsigned.apk" "$test_output/aligned.apk"
"$java_bin/java" -jar "$android_root/prebuilts/sdk/tools/linux/lib/apksigner.jar" sign \
    --v1-signing-enabled true --v2-signing-enabled true --v3-signing-enabled false \
    --key "$android_root/build/target/product/security/testkey.pk8" \
    --cert "$android_root/build/target/product/security/testkey.x509.pem" \
    --out "$test_output/AthenaMicTest.apk" "$test_output/aligned.apk"
"$java_bin/javac" -cp "$android_root/prebuilts/sdk/tools/linux/lib/apksigner.jar" \
    -d "$test_output" "$test_source/VerifyApk.java"
"$java_bin/java" -cp "$test_output:$android_root/prebuilts/sdk/tools/linux/lib/apksigner.jar" \
    VerifyApk "$test_output/AthenaMicTest.apk"
printf '%s\n' "$test_output/AthenaMicTest.apk"
