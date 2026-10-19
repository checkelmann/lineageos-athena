# Candidate release checklist

## Packaging

- [x] Build succeeds; ZIP integrity passes.
- [x] SHA-256 recorded and checked after download.
- [x] No bundled adb_keys, no forced root-adbd, ADB authentication retained.
- [x] Patched ladder, shim and compatibility libraries are in target files.
- [x] Correct landscape properties, Wi-Fi/Bluetooth modules and configs included.
- [x] Both A11 volume XMLs included; FireOS tables not reintroduced by duplicate rules.
- [x] Recovery updater guard is a no-op; updater-script has no recovery/bootloader writes.
- [x] Updater-script does not format userdata (review existing addon.d hooks separately).

## On-device acceptance — not yet performed on candidate ZIP

- [ ] TWRP install completes, existing userdata preserved.
- [ ] Rootless ADB requires the user's own approval and works after approval.
- [ ] Boot completion before watchdog; no manual HAL starts required.
- [ ] Landscape display and accurate touch after reboot.
- [ ] Wi-Fi scan, connect and internet validation after reboot.
- [ ] Bluetooth scan/pair/reconnect and audio profile tests.
- [ ] Speaker playback; volume steps and zero-volume mute actually work.
- [ ] Microphone recording and hardware privacy-state investigation.
- [ ] Thermal behavior and sustained playback monitored.
- [ ] Restore/rollback tested with the owner's backups.

Publish as an experimental prerelease only after updating these results honestly.
Do not imply that successful compilation validates an installation or all hardware.
Kernel-source correspondence and proprietary-file redistribution require review
before any public binary release. Never attach raw userdata or unredacted logs.
