#!/usr/bin/env python3
"""Read-only sanity checks; not a replacement for an installation/boot test."""
import argparse
import hashlib
import json
import io
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
    parser.add_argument("--require-hardware-fixes", action="store_true",
                        help="Require the camera, thermal, processed-mic and privacy follow-up")
    parser.add_argument("--prebuilt-hashes", help="Verify excluded asset inventory against target files")
    args = parser.parse_args()
    with zipfile.ZipFile(args.ota) as ota, zipfile.ZipFile(args.target_files) as target:
        check(ota.testzip() is None, "OTA ZIP CRC")
        check(target.testzip() is None, "target-files ZIP CRC")
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
        check(hashlib.sha256(ota.read("boot.img")).digest() ==
              hashlib.sha256(target.read("IMAGES/boot.img")).digest(),
              "OTA boot image differs from audited target files")
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
        hardware_hashes = {}
        if args.require_hardware_fixes:
            check("ro.hardware.audio.primary=athena" in vendor_props, "capture wrapper selector")
            check("ro.hardware.thermal=athena" in vendor_props, "native thermal selector")
            required += [
                "lib/hw/audio.primary.athena.so", "lib/hw/thermal.athena.so",
                "lib/modules/thermal_module.ko", "lib/fireos.hardware.amazonthermal@1.1.so",
                "etc/init/init.thermal_mod.rc", "lib/libLab126CameraMetrics.so",
                "lib/fireos.hardware.camportal@1.0.so",
                "lib/vendor.mediatek.hardware.camera.ccap@1.0.so",
                "lib/ov13855_mipi_raw_IdxMgr.so", "lib/ov13855main2_mipi_raw_IdxMgr.so",
                "lib/ov13855_mipi_raw_tuning.so", "lib/ov13855main2_mipi_raw_tuning.so",
                "lib/libcamportal_wrap.so", "lib/libm4u.so", "lib/libmtkcam.dewarp.mapping.so",
                "lib/libmtkcam.dewarp.roi.so", "lib/libdnn_fd.so",
            ]
            helper_paths = [p for p in ("SYSTEM/system_ext/framework/athena-thermal-policy.jar",
                                       "SYSTEM_EXT/framework/athena-thermal-policy.jar") if p in names]
            check(len(helper_paths) == 1, "exactly one packaged OEM thermal policy helper")
            with zipfile.ZipFile(io.BytesIO(target.read(helper_paths[0]))) as helper:
                check("classes.dex" in helper.namelist(), "thermal helper missing executable dex")
            thermal_init = target.read("VENDOR/etc/init/init.thermal_mod.rc").decode()
            check("insmod /vendor/lib/modules/thermal_module.ko" in thermal_init,
                  "stock thermal module boot load")
            check("on property:init.svc.amazonthermal-1.0=running" in thermal_init and
                  "--apply-stock-policy" in thermal_init and
                  "/system_ext/framework/athena-thermal-policy.jar" in thermal_init,
                  "OEM policy boot restoration")
            check(not any("AthenaMicTest" in p or "athena_capture_compat_test" in p for p in names),
                  "diagnostic app/native test must not ship in ROM")
            for p in ["VENDOR/lib/hw/audio.primary.athena.so", "VENDOR/lib/hw/thermal.athena.so",
                      helper_paths[0], "BOOT/kernel"]:
                hardware_hashes[p] = hashlib.sha256(target.read(p)).hexdigest()
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
        prebuilt_count = 0
        if args.prebuilt_hashes:
            mismatches = []
            with open(args.prebuilt_hashes) as inventory:
                for line in inventory:
                    if not line.strip() or line.startswith("#"):
                        continue
                    expected, source = line.split()
                    if source.startswith("prebuilt/vendor/"):
                        destination = "VENDOR/" + source.removeprefix("prebuilt/vendor/")
                    elif source.startswith("prebuilt/camera/"):
                        destination = "VENDOR/lib/" + source.removeprefix("prebuilt/camera/")
                    elif source == "prebuilt/zImage-dtb":
                        destination = "BOOT/kernel"
                    else:
                        raise SystemExit("FAIL: unrecognized inventory source " + source)
                    check(destination in names, "missing inventoried asset " + destination)
                    if hashlib.sha256(target.read(destination)).hexdigest() != expected:
                        mismatches.append(destination)
                    prebuilt_count += 1
            check(not mismatches, "inventoried asset hash mismatch: " + ", ".join(mismatches))
    print(json.dumps({"result": "PASS", "ota_sha256": digest(args.ota),
                      "partition_targets": blocks, "required_vendor_files": len(required),
                      "hardware_followup_required": args.require_hardware_fixes,
                      "verified_prebuilt_hashes": prebuilt_count,
                      "hardware_sha256": hardware_hashes,
                      "on_device_install_tested": False}, indent=2))


if __name__ == "__main__":
    main()
