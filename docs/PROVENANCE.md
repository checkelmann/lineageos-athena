# Source provenance / notices

- Android/LineageOS project revisions: source-manifest.xml (resolved build-tree manifest).
- Device snapshot: athena/, including inherited copyright and license headers.
- Existing device-source origin: checkelmann/android_device_amazon_athena, adapted
  from amazon-mt8183-devs/android_device_amazon_maverick.
- Existing kernel-source origin: checkelmann/android_kernel_amazon_mt8183.
- The candidate uses an extracted stock kernel, NOT a kernel rebuilt from that
  source. Exact corresponding source/configuration/module correspondence has not
  been independently verified. Do not represent that repository as a verified
  complete corresponding-source release for the shipped binary.
- MediaTek Android hardware project: LineageOS/android_hardware_mediatek, lineage-17.1.
- Vendor libraries, firmware, audio models and kernel binary: excluded from this
  Git repository. The working build server retains extracted assets locally.
- Local modification to LineageOS lmkd: patches/lmkd-noncritical.patch.

No blanket license is applied to third-party files. Their individual notices remain
in force. The availability of extracted binaries does not itself establish public
redistribution permission. Resolve provenance/permissions and kernel-source
requirements before publicly distributing binary images.

The private handoff, build-server connection details, personal diagnostics and host
ADB key are intentionally not part of this repository.
