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

### Processed microphone compatibility (source ahead of candidate)

The stock primary HAL selects unimplemented ASP pipeline2 for standard MIC, while
VOICE_RECOGNITION selects the working ASR pipeline0. `audio.primary.athena` loads the
unchanged stock primary and translates processed built-in sources at open, stream
parameter updates, and input-routing patch creation. The last path is essential:
stock createAudioPatch writes source directly to its internal stream manager and
bypasses the stream setter. Framework permissions and caller source remain intact;
stock playback/mute operations are not replaced. External, telephony, private Amazon
and UNPROCESSED sources are not translated. This is processed array audio, not a
promise of independent raw microphone channels or low-latency performance.

Use `ro.hardware.audio.primary=athena` to select the wrapper. Preserve the original
`/vendor/lib/hw/audio.primary.mt8183.so` and its existing ABI dependency fixes. The
wrapper must compile with HAL port layouts, not framework-only flags. Static checks
enforce ARM32 audio_port_config size212/ext offset172 and create_audio_patch offset140.
Muted format tests verify successful capture and actual pipeline0 selection, not
privacy or speech quality. In particular, the shell MIC client can be silenced by
the framework even with a real HAL signal and privacy off. The foreground test app
successfully captured a changing MIC signal using normal RECORD_AUDIO permission;
do not patch out framework privacy checks to make a shell diagnostic pass.
Four native mock-based regression tests passed on the device: source mapping,
stream parameter/close forwarding, untouched external capture and non-mutating
routing translation. See STATUS.md for remaining acceptance gates.

### Physical switch observations

`gpio-privacy-button` advertises Linux KEY_POWER (scan code116). Generic.kl maps
that to Android POWER, and PowerManager records sleep reason power_button.
There is also a separate gpio-privacy-state switch. Key remapping alone would not
prove hardware microphone isolation. Ordinary MIC source returns zeros even
unmuted: vendor ASP reports unsupported pipeline2. VOICE_RECOGNITION source does
receive a varying nonzero signal unmuted. Its10s muted comparison returned100 small
nonzero samples during startup (peak15), then9 seconds of exact zeros, with framework
mute=true throughout. The startup transient remains unexplained; this is not proof
of hardware isolation or intelligible recording. Tests save no audio. Amazon's
[microphone control documentation](https://digprjsurvey.amazon.com/csad/help/node/GKA25FVYEV5PY8C9)
explains that this button disables both microphones AND camera. Do not diagnose a
no-frames camera failure with the red privacy light on as proof of a broken pipeline.

## Camera follow-up (source ahead of packaged candidate)

Restored matching OV13855 sensor tuning/scene libraries, camera metrics and portal
interfaces, plus plugin dependencies libcamportal_wrap, libm4u, dewarp mapping/ROI
and libdnn_fd. Missing tuning originally caused a null GetCameraDefaultPara callback;
missing device3 dependencies then caused zero camera enumeration. Two front camera
IDs now enumerate and preview is user-confirmed with privacy off. Photo/video
capture and reboot persistence remain untested. Do not remove privacy checks.

## Thermal follow-up (source ahead of packaged candidate)

The stock thermal_module.ko was missing. Loading it restored the virtual sensor
readings and registered OEM cooling devices. The generic stock legacy HAL read
cached `/proc/mtktz/mtktscpu=-274000` even while sysfs returned real temperatures.
`thermal.athena` reads CPU, skin and display virtual zones by name. It does not
fabricate GPU/battery readings, change trips, or equate CPU cooling states with fan RPM.

Merely starting Amazon's thermal HAL does NOT activate its policies: virtual-zone
governors were null. Calling its existing1.1 setLocalePolicy method with the configured
locale restored the OEM thermal.policy.conf profiles. Verified step_wise/enabled,
display10trips starting43C, skin7trips starting47C, CPU6trips starting100C. No custom
thresholds or fake-temperature testing were used. CPU legacy zone remains disabled;
OEM control uses the virtual zones. Heat/throttling/shutdown behavior is NOT qualified.

The athena-thermal-policy helper restores these original profiles via the stock
HAL when its init service starts. Reboot persistence remains untested. The legacy
Android1.0 thermal interface cannot provide modern throttling severity callbacks.

Restarting a faulty thermal HAL while dumpsys runs exposed an A11 lock inversion:
ThermalManagerService.dump holds mLock waiting for mHalLock; DeathRecipient holds
mHalLock calling onTemperatureChanged waiting for mLock. A framework-only restart
cleared the development-session deadlock. The new HAL then returned normal readings
through dumpsys; the framework bug itself is not patched.

## Partition safety

Known by-name targets: system mmcblk1p21, vendor p12, data p23, metadata p9, persist p5.
Persist is only about3.8MiB; keep diagnostic logs bounded and opt-in. Never wipe
userdata or flash LK/LK2/preloader/recovery during routine ROM fixes.
