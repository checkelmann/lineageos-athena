#!/usr/bin/env python3
"""Read-only sanity checks; not a replacement for an installation/boot test."""
import argparse
import hashlib
import json
import re
import zipfile


def check(condition, message):
    if not condition:
        raise SystemExit("FAIL: " + message)


def digest(path):
    h = hashlib.sha256()
    with open(path, "rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("ota")
    parser.add_argument("target_files")
    args = parser.parse_args()
    with zipfile.ZipFile(args.ota) as ota, zipfile.ZipFile(args.target_files) as target:
        check(ota.testzip() is None, "OTA ZIP CRC")
        names = set(target.namelist())
        check(not any(n.rsplit("/", 1)[-1] == "adb_keys" for n in names),
              "bundled adb_keys in target files")
        script = ota.read("META-INF/com/google/android/updater-script").decode()
        check("athena" in script, "device assertion missing")
        # Only boot, system and vendor block writes are expected for this device.
        blocks = sorted(set(re.findall(r'"(/dev/block/[^"\n]+)"', script)))
        check(blocks, "no partition targets found")
        check(all(p.rsplit("/", 1)[-1] in {"boot", "system", "vendor"} for p in blocks),
              "unexpected partition target: " + repr(blocks))
        check(not re.search(r'\bformat\s*\(', script), "format instruction in installer")
        check(not re.search(r'package_extract_file\("recovery\.img"', script),
              "recovery image extraction in installer")
        init = target.read("VENDOR/etc/init/hw/init.mt8183.rc").decode()
        check(not re.search(r'^\s*setprop\s+service.adb.root\s+1\b', init, re.M),
              "automatic root adbd")
        check("on property:persist.vendor.athena.diagnostics=1" in init,
              "persistent logcat must be opt-in")
        guard = target.read("VENDOR/etc/init/zz-athena-recovery-guard.rc").decode()
        check("service vendor_flash_recovery /system/bin/true" in guard and
              re.search(r'^\s+override\s*$', guard, re.M), "TWRP preservation guard")
        props = target.read("SYSTEM/etc/prop.default").decode()
        check("ro.adb.secure=1" in props and "ro.secure=1" in props,
              "ADB authentication disabled")
        vendor_props = target.read("VENDOR/build.prop").decode()
        check("ro.surface_flinger.primary_display_orientation=ORIENTATION_90" in vendor_props,
              "landscape property")
        required = [
            "lib/libladder.so", "lib/libunwindstack_shim.so", "lib/libutils-v32.so",
            "lib/libcrypto-v32.so", "lib/libhardware_legacy-athena.so",
            "lib/hw/audio.primary.mt8183.so", "lib/hw/hwcomposer.mt8183.so",
            "lib/hw/sensors.athena.so", "lib/hw/android.hardware.bluetooth.audio@2.0-impl.so",
            "lib/modules/btmtksdio.ko", "lib/modules/wlan_mt76x3_sdio.ko",
            "lib/modules/wlan_mt76x3_sdio_prealloc.ko", "bin/athena-bt-address",
            "bin/hw/android.hardware.wifi@1.0-service", "etc/audio_device_tas5805m.xml",
            "etc/audio-algorithms/asp.cfg", "etc/init/btmac.rc", "ueventd.rc",
            "firmware/mt7663_patch_e2_hdr.bin", "firmware/bt.cfg",
        ]
        for path in required:
            check("VENDOR/" + path in names, "missing VENDOR/" + path)
        volumes = target.read("VENDOR/etc/audio_policy_volumes.xml").decode()
        defaults = target.read("VENDOR/etc/default_volume_tables.xml").decode()
        check('deviceCategory="DEVICE_CATEGORY_SPEAKER"' in volumes,
              "A11 volume categories missing")
        check('name="DEFAULT_DEVICE_CATEGORY_SPEAKER_VOLUME_CURVE"' in defaults,
              "A11 speaker volume reference missing")
        lmkd = target.read("SYSTEM/etc/init/lmkd.rc").decode()
        check(not re.search(r'^\s+critical\s*$', lmkd, re.M), "lmkd critical restart")
    print(json.dumps({"result": "PASS", "ota_sha256": digest(args.ota),
                      "partition_targets": blocks, "required_vendor_files": len(required),
                      "on_device_install_tested": False}, indent=2))


if __name__ == "__main__":
    main()
