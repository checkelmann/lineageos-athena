# LineageOS 18.1 for Amazon Echo Show 8 (2nd Gen)

Experimental Android 11 port for **athena**, using the stock **32-bit ARM Linux
4.4.146** kernel on MediaTek MT8183. This is not an official LineageOS release.
Do not use images for Echo Show 8 first-generation, third-generation, or other devices.

## Status

The development device has reached `sys.boot_completed=1` on two boots without
wiping userdata. Display, landscape/touch mapping, Wi-Fi internet access and speaker
playback were confirmed on that device. Bluetooth reaches ON; pairing is not yet
validated. The **e2e1 experimental installer** includes the later hardware fixes,
but still needs an independent TWRP installation and boot test. See [e2e1](docs/E2E1.md).

**Privacy warning:** the microphone/privacy button also acts as a screen power
button. A new software guard makes privacy-on built-in MIC capture entirely silent
in the tested10s interval, but hardware isolation has NOT been verified.
Screen off is not proof of microphone privacy. Ordinary processed MIC capture now
receives a signal in a foreground app;
voice-satellite speech quality, echo cancellation and long-term listening still need
validation. These fixes are included in e2e1, not the older October 19 candidate.

Other limitations: SELinux permissive, old stock kernel/vendor security level,
unencrypted `/data` configuration and userdebug/test-key build. Camera preview and
thermal readings/OEM policies are restored in current source/live development and
packaged in e2e1. Reboot persistence and heat behavior
remain untested. This is a bring-up build, not a secure daily-use release.

## Documentation

- [e2e1 experimental installation-test build](docs/E2E1.md)
- [Older 2026-10-19 candidate and packaging audit](docs/CANDIDATE.md)
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
