# Installation — experimental candidate

The new ZIP has not yet passed an on-device installation test. These are candidate
instructions, not a verified first-time unlock or stock-to-Lineage migration guide.
Back up your data and existing boot/system/vendor partitions in a known-working
TWRP. Keep an independently verified recovery path before proceeding.

## Preconditions

- Exact device: Echo Show 8 **2nd Gen**, codename **athena**.
- Device already prepared to boot custom Android images, with working TWRP.
- Working USB ADB/fastboot and stable power.
- Verify the release SHA-256 checksum before copying the ZIP.
- Review known issues, especially privacy, thermal and encryption limitations.

This repository does not currently document a tested first-time unlock procedure.
Do not use random bootloader/preloader images or assume an exploit for another
Echo model applies.

## TWRP install command

For an already-prepared device, substitute the actual candidate filename/date:

```sh
adb push lineage-18.1-20261018-UNOFFICIAL-athena.zip /sdcard/Download/
adb reboot bootloader
fastboot reboot recovery
adb wait-for-recovery
adb shell twrp install /sdcard/Download/lineage-18.1-20261018-UNOFFICIAL-athena.zip
```

Do not wipe or format userdata as part of these instructions. Preserving data is a
port goal, not a guarantee; encrypted or different stock installations may differ.
Stop if TWRP reports an install error. Do not disable device assertions to force it.

`fastboot boot` is **unsupported** on athena and must not be used. On the development
device, entering the bootloader and using `fastboot continue` reliably started the
installed system. A direct normal reboot sometimes returned to fastboot instead.

Never flash LK, LK2, preloader, TEE or recovery as part of this ROM installation.
The ROM's generated recovery-update service is overridden to a no-op to retain
existing TWRP. Inspect the candidate updater script before first installation.

## Verification

```sh
adb shell getprop sys.boot_completed
```

Expected: `1`. The conditional bring-up watchdog reboots to the bootloader if boot
completion is absent at 60 seconds. First-boot timing and key-free ADB authorization
must still be tested. Authorize your own computer on the device; there is no
preauthorized maintainer key or automatic root-adbd configuration.

Check orientation/touch, Wi-Fi, Bluetooth pairing and audio at low volume. Test
volume adjustment before increasing loudness. Do not assume the privacy button
mutes microphones merely because the screen switches off.

## Failed boot

Use `fastboot reboot recovery`, not a cold power cycle, and capture pstore promptly:

```sh
adb shell 'cat /sys/fs/pstore/console-ramoops-0'
adb shell 'cat /sys/fs/pstore/pmsg-ramoops-0'
```

Some boots use `console-ramoops` without the `-0` suffix. Amazon's bootloader can
clear these logs after cold boot. Redact network names, addresses and identities
before sharing logs. Restore your own known-good partition backups if necessary.
