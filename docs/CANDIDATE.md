# 2026-10-19 experimental candidate

This candidate packages the previously live-applied boot, display/touch, Wi-Fi,
Bluetooth, audio and volume fixes. A successful packaging audit is not an on-device
TWRP installation or boot test. Use the release checksum to identify the exact ZIP.

Pinned device-source snapshot: `1ac98e4e84c501a6a5bbc54ee039f755a490dd59`.
Later camera/thermal fixes on the main branch and development device are NOT in
this ZIP. Its historical limitations below must not be confused with current source.

Artifact: `lineage-18.1-20261019-UNOFFICIAL-athena.zip` (approximately506MiB).

SHA-256:

```text
de9adc46f13fe6935a889c7aaa3e135d54bbe276ae66901e85c16df3168a0d3f
```

Packaging audit: PASS. ZIP CRC checked; no adb_keys present in target files;
ro.adb.secure=1 and ro.secure=1; automatic root-adbd absent; recovery guard,
required vendor files, landscape and volume settings included. The updater-script
directly writes only boot, system and vendor; no format command. Standard LineageOS
addon backup/restore scripts also run, so audit any existing user-added addon.d hooks.
See [machine-readable audit](candidate-audit.json).

Compared with the original October16 installer:

- Canonical ART/APEX and linkerconfig boot fixes.
- ueventd device-node permissions, stock composer and sensor HAL.
- Stock-compatible Wi-Fi HAL, supplicant, SDIO modules and firmware.
- Bluetooth driver, per-device factory-address provisioning and audio provider2.0.
- Audio ABI compatibility libraries, DSP configs, TAS5805M routing and A11 volume curves.
- Landscape/touch properties, legacy lmkd settings and userdata-preserving fstab.
- No bundled host ADB authorization key; no forced root-adbd; authentication enabled.
- Existing TWRP preservation guard and opt-in persistent diagnostic logcat.

Known limitations: privacy button behaves as POWER; microphone isolation is
unverified; camera and Amazon thermal HAL fail; SELinux is permissive; userdata
encryption is disabled; userdebug/test keys and old kernel/vendor components remain.
Bluetooth pairing and audio profiles, post-reboot hardware startup and key-free ADB
authorization remain untested on this candidate. No Google apps are bundled by this
port's documented build procedure.

Do not publish this draft as a stable release or claim installation success before
completing [the release checklist](RELEASE.md). No device was flashed to create it.
