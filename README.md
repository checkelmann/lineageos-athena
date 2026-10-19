# LineageOS 18.1 for Amazon Echo Show 8 (2nd Gen)

Experimental Android 11 port for **athena**, using the stock **32-bit ARM Linux
4.4.146** kernel on MediaTek MT8183. This is not an official LineageOS release.
Do not use images for Echo Show 8 first-generation, third-generation, or other devices.

## Status

The development device has reached `sys.boot_completed=1` on two boots without
wiping userdata. Display, landscape/touch mapping, Wi-Fi internet access and speaker
playback were confirmed on that device. Bluetooth reaches ON; pairing is not yet
validated. The freshly packaged installer must still be tested independently.

**Privacy warning:** the microphone/privacy button currently acts as a screen
power button. Microphone isolation has NOT been verified. Screen off is not proof
that microphones are disabled. Do not rely on this port for microphone privacy.

Other limitations: SELinux permissive, old stock kernel/vendor security level,
unencrypted `/data` configuration, userdebug/test-key build, camera and thermal
HAL failures. This is a bring-up build, not a secure daily-use release.

## Documentation

- [2026-10-19 candidate and packaging audit](docs/CANDIDATE.md)
- [Hardware status and known issues](docs/STATUS.md)
- [Installation and recovery safety](docs/INSTALL.md)
- [Build and source requirements](docs/BUILD.md)
- [Architecture and bring-up fixes](docs/BRINGUP.md)
- [Release checklist](docs/RELEASE.md)
- [Source provenance and licensing](docs/PROVENANCE.md)

`athena/` is the current device-source snapshot, installed into an Android tree as
`device/amazon/athena`. Firmware, kernel binary, vendor libraries, and proprietary
audio algorithm files are intentionally excluded from Git. This repository does
not contain device dumps, personal ADB authorization keys, user logs, credentials,
or per-device factory identities. The Bluetooth address is read from each device.

Build artifacts belong in Releases, not Git history. A candidate build is not
considered installer-tested simply because equivalent live partition edits work.
