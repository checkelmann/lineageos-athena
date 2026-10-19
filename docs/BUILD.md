# Building

## Source layout

Start with the pinned Android project revisions in [source-manifest.xml](source-manifest.xml).
The source base is LineageOS `lineage-18.1`. Local MediaTek project override:

```xml
<manifest>
  <project name="LineageOS/android_hardware_mediatek"
           path="hardware/mediatek" remote="github" revision="lineage-17.1" />
</manifest>
```

The manifest pins upstream Git revisions, not local device/vendor trees or local
patches. Put this repository's `athena/` at `device/amazon/athena`; do not overwrite
an existing modified device tree without a backup. Apply `patches/lmkd-noncritical.patch`
inside `system/memory/lmkd` after checking `git apply --check`.

The vendor tree belongs at `vendor/amazon/athena`. Existing extraction tooling is
included in `athena/`, but it is not by itself a complete one-command reproduction
recipe: the additional firmware/prebuilts below must be restored and patched.
Do not point extraction at personal userdata or upload your stock dump to Git.

## Required excluded assets

- Stock athena ARM32 `zImage-dtb` at `device/amazon/athena/prebuilt/zImage-dtb`.
- Stock vendor tree generated from compatible athena firmware. Some inherited
  entries reference older athena/trona firmware; provenance is in proprietary-files.txt.
- `prebuilt/vendor/lib`: libwifi-hal.so, WifiMetrics.so,
  fireos.hardware.connectivity@1.0.so, libpcm_merge.so, libtensorflowlite_c.so,
  libmsb.so, libmsrc.so, libedgeflow_core_neon.so, patched libladder.so,
  libunwindstack_shim.so, libhardware_legacy-athena.so.
- `prebuilt/vendor/lib/hw`: stock hwcomposer.mt8183.so and sensors.athena.so.
- `prebuilt/vendor/lib/modules`: matching wlan_mt76x3_sdio_prealloc.ko,
  wlan_mt76x3_sdio.ko and btmtksdio.ko. Expected vermagic: 4.4.146+ ARMv7.
- `prebuilt/vendor/firmware`: EEPROM_MT7663.bin, WIFI_RAM_CODE_MT7663.bin,
  mt7663_patch_e2_hdr.bin, wifi.cfg, TxPwrLimit_MT76x3.dat and bt.cfg.
- Stock `prebuilt/vendor/bin/hw/android.hardware.wifi@1.0-service`.
- Stock `configs/audio/audio-algorithms/` (37 config/model files).
- VNDK v28 ARM32 prebuilts referenced by `vndk/Android.mk`, plus the validated
  libutils-v32.so and libcrypto-v32.so copies in `prebuilt/vendor/lib/`.

Use `docs/prebuilt-sha256.txt` to check the build machine's exact additional assets.
The compiled shim hash may differ if toolchain/linker versions differ. Preserve
copyright notices; binary redistribution permissions have not been established here.

## Required blob adjustments

1. Keep wpa_supplicant original: no libcompiler_rt-v29 dependency.
2. Export `unwindstack::Maps::~Maps()` through libunwindstack_shim.so; patched
   libladder.so must DT_NEEDED it. `scripts/unwindstack-shim.c` provides the source.
3. Copy stock `vendor/lib/vndk/libhardware_legacy.so` under the SONAME
   libhardware_legacy-athena.so.
4. Patch a FRESH stock audio.primary.mt8183.so in ONE patchelf invocation:

```sh
patchelf --replace-needed libmedia_helper.so libmedia_helper-v28.so \
  --replace-needed libhardware_legacy.so libhardware_legacy-athena.so \
  audio.primary.mt8183.so
```

Do not repeatedly run patchelf on an already rewritten primary audio blob; this
produced an invalid PHDR mapping during bring-up. Install the patched primary and
ladder in the corresponding vendor proprietary paths. Check other blob fixups in
extract-files.sh, and put `patches/btmac.rc` into the vendor proprietary etc/init path
AFTER extraction so the missing FireOS IDME service is not required.

The shim was compiled using clang-r383902b1:

```sh
clang --target=armv7a-linux-androideabi30 -shared -fPIC -fuse-ld=lld -nostdlib \
  -Wl,-soname,libunwindstack_shim.so -o libunwindstack_shim.so unwindstack-shim.c
```

## Compile

From the prepared Android source tree on Linux:

```sh
source build/envsetup.sh
lunch lineage_athena-userdebug
m -j8 bacon
```

Result: `out/target/product/athena/lineage-18.1-<date>-UNOFFICIAL-athena.zip`.
This is userdebug/test-key, not production-signed. SELinux remains permissive.
No PRODUCT_ADB_KEYS is set; no service.adb.root=1 is forced. Persistent logcat is
opt-in (`persist.vendor.athena.diagnostics=1`) rather than always recording.

Audit the generated images and updater-script before publishing. Building is not
the same as boot-testing the resulting ZIP.
