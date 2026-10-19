# Bring-up notes

## Boot and linker namespaces

The stock boot chain uses a 32-bit ARM kernel even though MT8183 has ARM64 CPUs.
Keep the stock kernel and forced prebuilt configuration. A full kernel replacement
is outside this port's validated state.

The system partition is system-as-root. Under TWRP, a system partition mounted at
`/mnt/sys` has Android's `/system` at `/mnt/sys/system`. Vendor is a separate partition.

Flattened APEXes require explicit early-init mounts. The canonical ART path
`/apex/com.android.art` must be a real bind mount, with release alias pointing to
it; otherwise Zygote's file-descriptor whitelist aborts. Create VNDK aliases before
regenerating linkerconfig. Bind the generated bootstrap config to `/linkerconfig`.
Do not simplify this sequence without testing a complete boot.

The stock lmkd lacks compatible PSI/MEMCG support. Remove its `critical` restart
classification; retain ro.lmk.use_psi=false and use_minfree_levels=true.

## Permissions / graphics / sensors

A11 ueventd needs a regular `/vendor/ueventd.rc`, not just an etc version or symlink.
Stock hwcomposer.mt8183.so and sensors.athena.so were missing. The sensor selector
must be `ro.hardware.sensors=athena`, with a matching sensors1.0 service/impl.

`ro.sf.hwrotation=90` and
`ro.surface_flinger.primary_display_orientation=ORIENTATION_90` align landscape
rendering with the panel's raw 1280×800 touch coordinates.

## Networking

Load stock preallocator, Wi-Fi SDIO driver, then Bluetooth SDIO driver on post-fs-data.
Wi-Fi uses stock HAL1.0–1.2; do not advertise generic HAL1.4. Bluetooth's address
script formats each unit's own `/proc/idme/bt_mac_addr`; no address is hardcoded.
The stock btmac program otherwise blocks on an absent FireOS IDME service.
Bluetooth audio uses the source tree's provider2.0, not nonexistent2.1.

## Audio

Stock primary audio needs the libladder unwindstack shim, additional DSP libraries,
the stock hardware_legacy timeout function, TAS5805M routing XML and audio-algorithms
configuration. HAL registration alone does not prove it can open a speaker output.
Check that audio policy has a valid manager and a Primary Output, not `0x0`.

FireOS volume XML is incompatible with A11's device-category curves. Restore BOTH
audio_policy_volumes.xml and default_volume_tables.xml from the same A11 source.
Before this fix the slider changed but AudioFlinger gain remained full scale.
Read-only policy queries verified MUSIC/SPEAKER index1=-55.16dB, index3=-47.58dB,
index10=-28.5dB and index25=0dB. Do not use high-volume tests for bring-up.

## Privacy button

`gpio-privacy-button` advertises Linux KEY_POWER (scan code116). Generic.kl maps
that to Android POWER, and PowerManager records sleep reason power_button.
There is also a separate gpio-privacy-state switch. Key remapping alone would not
prove hardware microphone isolation; recording and switch behavior need testing.

## Partition safety

Known by-name targets: system mmcblk1p21, vendor p12, data p23, metadata p9, persist p5.
Persist is only about3.8MiB; keep diagnostic logs bounded and opt-in. Never wipe
userdata or flash LK/LK2/preloader/recovery during routine ROM fixes.
