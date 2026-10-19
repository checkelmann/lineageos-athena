# Hardware status

Recorded 2026-10-18. These results describe the development device, not a completed
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
| Microphones | Recording and hardware privacy isolation untested |
| Privacy button | Incorrectly treated as POWER; screen sleep/wake |
| Camera | Not working; missing vendor dependencies |
| Thermal | Amazon thermal service fails to load a vendor dependency; behavior unvalidated |
| USB ADB | Development access works; key-free release authorization untested |
| SELinux | Permissive |
| Userdata encryption | Disabled in port fstab; no wipe performed on development device |

Wi-Fi, Bluetooth, orientation and final audio fixes were applied live after the
last complete boot. Their automatic startup after a full reboot remains a release
gate. Existing userdata may conceal first-install problems.

Do not claim microphone privacy, camera, Bluetooth audio, automatic thermal
management, clean install, or safe OTA updates until individually tested.
