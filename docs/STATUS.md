# Hardware status

Recorded 2026-10-19. These results describe the development device, not a completed
fresh-installer acceptance test.

| Component | Observed status |
| --- | --- |
| Android boot | Boot completion reproduced, stock kernel retained |
| Display / touch | User-confirmed; logical landscape 1280×800 |
| Wi-Fi | User-confirmed; scans and validated internet connection |
| Bluetooth | Controller and framework ON; pairing/profiles untested |
| Speakers | User-confirmed playback |
| Volume | A11 curves restored; policy attenuation verified, final audible test pending |
| Sensors | Service running; individual sensor accuracy untested |
| Microphones | Processed MIC16k mono works in normal foreground app;60s capture and guarded mute/unmute comparison passed; satellite qualification ongoing |
| Privacy button | Additional software guard:160,000 zero MIC samples with privacy on; still incorrectly sends POWER; hardware isolation not certified |
| Camera | Latest source/live:2 devices; preview user-confirmed with privacy off; photo/video untested |
| Thermal | Latest source/live:real CPU/skin readings and original OEM virtual-zone cooling profiles restored; no heat qualification |
| USB ADB | Development access works; key-free release authorization untested |
| SELinux | Permissive |
| Userdata encryption | Disabled in port fstab; no wipe performed on development device |

Wi-Fi, Bluetooth, orientation and final audio fixes were applied live after the
last complete boot. Their automatic startup after a full reboot remains a release
gate. Existing userdata may conceal first-install problems.

The latest thermal/camera source changes are NOT in the existing20261019 draft ZIP,
which remains pinned to device-source snapshot1ac98e4. No new installer was flashed.

Do not claim hardware microphone isolation, complete voice-satellite qualification, Bluetooth
audio, boot-persistent thermal management, clean install, or safe OTA updates.
Voice-recognition capture was nonzero unmuted. Muted capture had100 low-amplitude
nonzero samples in its first second, then9 seconds of exact zeros. This is not a
hardware-isolation certification; intelligibility and sensitivity remain untested.

The newer `audio.primary.athena` wrapper routes processed built-in MIC, DEFAULT,
CAMCORDER, VOICE_COMMUNICATION and VOICE_PERFORMANCE requests through the stock ASR
path, fixing the unsupported-pipeline selection. MIC16k mono10s and MIC48k mono/
stereo, CAMCORDER44.1k stereo, VOICE_COMMUNICATION16k mono5s each opened successfully,
selected pipeline0, and returned zeros with hardware privacy on. However, the
command-line MIC client also received zeros with privacy OFF while HAL power
history showed a real signal: framework client silencing makes those zero-only
MIC tests insufficient to validate privacy. No recording protections were disabled.

A normal foreground diagnostic app with RECORD_AUDIO granted then captured10s of
varying MIC16k mono signal (peak935, RMS~6–65) using the wrapper. A second60s test
completed all60 reads of16,000 samples with varying nonzero signal, no read errors
or stalls. No audio files or network access.

Foreground privacy-on comparison initially returned97 tiny startup samples (peak14),
then9 seconds of zeros. Added a separate software privacy guard: built-in reads
check physical GPIO state before and after stock capture, zeroing output if either
check is muted or the state cannot be read/validated. Repeating10s foreground MIC
with privacy on then returned160,000 exact zeros, including startup. This verifies
software muting, NOT hardware isolation, and does not erase audio already buffered
by an app. Six native regression tests pass, including mute transitions, fail-closed
state handling and unmuted data preservation. With the guard installed, a further
10s foreground MIC16k mono test with physical privacy off captured varying nonzero
signal throughout (peak1976, RMS~10–168), confirming the guard permits capture when
unmuted. All160,000 samples were read without errors; no audio was retained. The
successful60s test preceded the guard; guarded long-duration testing remains open.
Speech intelligibility, echo cancellation, sustained wake word listening, satellite
app acceptance and reboot persistence remain unqualified. UNPROCESSED/raw capture
is not repaired or claimed. Existing release ZIP still lacks this wrapper.
