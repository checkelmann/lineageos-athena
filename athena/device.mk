#
# Copyright (C) 2026 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# AAPT -- Echo Show 8 is landscape mdpi (800x1280, ~160dpi)
PRODUCT_AAPT_CONFIG := normal
PRODUCT_AAPT_PREF_CONFIG := mdpi

# Audio
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/prebuilt/vendor/lib/libhardware_legacy-athena.so:$(TARGET_COPY_OUT_VENDOR)/lib/libhardware_legacy-athena.so

PRODUCT_PACKAGES += \
    audio.bluetooth.default \
    audio.usb.default \
    audio.r_submix.default

PRODUCT_PACKAGES += \
    fireos.hardware.audio.service

PRODUCT_PACKAGES += \
    android.hardware.audio.common@4.0-util-v28

PRODUCT_PACKAGES += \
    android.hardware.bluetooth.audio@2.0-impl \
    android.hardware.soundtrigger@2.1-impl

PRODUCT_PACKAGES += \
    android.hardware.audio@2.0.vendor \
    android.hardware.audio@4.0.vendor \
    android.hardware.audio.effect@2.0.vendor \
    android.hardware.audio.effect@4.0.vendor \
    android.hardware.soundtrigger@2.0.vendor

PRODUCT_PACKAGES += \
    libaudiopreprocessing \
    libtinycompress \
    libalsautils \
    libnbaio_mono \
    libtinyxml \
    libmedia_helper-v28 \
    libxml2-v28

PRODUCT_COPY_FILES += \
    $(call find-copy-subdir-files,*,$(LOCAL_PATH)/configs/audio/,$(TARGET_COPY_OUT_VENDOR)/etc)

PRODUCT_COPY_FILES += \
    frameworks/av/services/audiopolicy/config/a2dp_in_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/a2dp_in_audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/bluetooth_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/bluetooth_audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/r_submix_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/r_submix_audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/usb_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/usb_audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/default_volume_tables.xml:$(TARGET_COPY_OUT_VENDOR)/etc/default_volume_tables.xml

# Bluetooth
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/prebuilt/vendor/bin/athena-bt-address:$(TARGET_COPY_OUT_VENDOR)/bin/athena-bt-address \
    $(LOCAL_PATH)/prebuilt/vendor/lib/modules/btmtksdio.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/btmtksdio.ko \
    $(LOCAL_PATH)/prebuilt/vendor/firmware/bt.cfg:$(TARGET_COPY_OUT_VENDOR)/firmware/bt.cfg

PRODUCT_PACKAGES += \
    android.hardware.bluetooth@1.0.vendor \
    android.hardware.bluetooth.a2dp@1.0.vendor

# Binder
PRODUCT_PACKAGES += \
    android.hidl.allocator@1.0.vendor \
    android.hidl.memory@1.0.vendor \
    libhidltransport \
    libhidltransport.vendor \
    libhwbinder.vendor \
    libhwbinder

# Camera
PRODUCT_PACKAGES += \
    android.hardware.camera.common@1.0.vendor \
    android.hardware.camera.device@1.0.vendor \
    android.hardware.camera.device@3.2.vendor \
    android.hardware.camera.device@3.3.vendor \
    android.hardware.camera.device@3.4.vendor \
    android.hardware.camera.provider@2.4.vendor

PRODUCT_PACKAGES += \
    libshim_mtkcam \
    libshim_utils

# Characteristics -- Echo Show is a tablet-like device
PRODUCT_CHARACTERISTICS := tablet

# Dalvik -- smaller heap for 800x1280 display
$(call inherit-product, frameworks/native/build/tablet-7in-hdpi-1024-dalvik-heap.mk)

# DRM
PRODUCT_PACKAGES += \
    android.hardware.drm@1.0-impl \
    android.hardware.drm@1.0-service \
    android.hardware.drm@1.4-service.clearkey \
    libdrmclearkeyplugin \
    libmockdrmcryptoplugin \
    libprotobuf-cpp-lite-v28 

PRODUCT_PACKAGES += \
    android.hardware.drm@1.1.vendor

# Graphics
PRODUCT_PACKAGES += \
    android.hardware.graphics.allocator@2.0-service \
    android.hardware.graphics.allocator@2.0-impl \
    android.hardware.graphics.composer@2.1-service \
    android.hardware.graphics.mapper@2.0-impl \
    android.hardware.memtrack@1.0-service \
    android.hardware.memtrack@1.0-impl \
    disable_configstore

# Gatekeeper
PRODUCT_PACKAGES += \
    android.hardware.gatekeeper@1.0-service \
    android.hardware.gatekeeper@1.0-impl

# Health
PRODUCT_PACKAGES += \
    android.hardware.health@2.1-service \
    android.hardware.health@2.1-impl

# Keymaster
PRODUCT_PACKAGES += \
    android.hardware.keymaster@3.0-service \
    android.hardware.keymaster@3.0-impl \
    libkeymaster3device.vendor \
    libkeystore-engine-wifi-hidl \
    libkeystore-wifi-hidl

# Lights
PRODUCT_PACKAGES += \
    android.hardware.light@2.0-service \
    android.hardware.light@2.0-impl

# Media
PRODUCT_COPY_FILES += \
    $(call find-copy-subdir-files,*,$(LOCAL_PATH)/configs/media,$(TARGET_COPY_OUT_VENDOR)/etc)

PRODUCT_COPY_FILES += \
    frameworks/av/media/libstagefright/data/media_codecs_google_audio.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_google_audio.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_video_le.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_google_video_le.xml

PRODUCT_PACKAGES += \
    libui-v28

# Overlay
DEVICE_PACKAGE_OVERLAYS += \
    $(LOCAL_PATH)/overlay

PRODUCT_PACKAGES += \
    TetheringConfigOverlay

PRODUCT_ENFORCE_RRO_TARGETS := *

# Permissions
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.bluetooth.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.bluetooth.xml \
    frameworks/native/data/etc/android.hardware.bluetooth_le.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.bluetooth_le.xml \
    frameworks/native/data/etc/android.hardware.camera.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.xml \
    frameworks/native/data/etc/android.hardware.ethernet.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.ethernet.xml \
    frameworks/native/data/etc/android.hardware.faketouch.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.faketouch.xml \
    frameworks/native/data/etc/android.hardware.location.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.location.xml \
    frameworks/native/data/etc/android.hardware.opengles.aep.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.opengles.aep.xml \
    frameworks/native/data/etc/android.hardware.sensor.accelerometer.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.accelerometer.xml \
    frameworks/native/data/etc/android.hardware.sensor.light.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.light.xml \
    frameworks/native/data/etc/android.hardware.touchscreen.multitouch.distinct.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.touchscreen.multitouch.distinct.xml \
    frameworks/native/data/etc/android.hardware.touchscreen.multitouch.jazzhand.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.touchscreen.multitouch.jazzhand.xml \
    frameworks/native/data/etc/android.hardware.touchscreen.multitouch.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.touchscreen.multitouch.xml \
    frameworks/native/data/etc/android.hardware.touchscreen.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.touchscreen.xml \
    frameworks/native/data/etc/android.hardware.usb.accessory.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.usb.accessory.xml \
    frameworks/native/data/etc/android.hardware.usb.host.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.usb.host.xml \
    frameworks/native/data/etc/android.hardware.vulkan.compute-0.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.compute.xml \
    frameworks/native/data/etc/android.hardware.vulkan.level-1.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.level.xml \
    frameworks/native/data/etc/android.hardware.vulkan.version-1_0_3.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.version.xml \
    frameworks/native/data/etc/android.hardware.wifi.direct.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.direct.xml \
    frameworks/native/data/etc/android.hardware.wifi.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.xml \
    frameworks/native/data/etc/android.software.midi.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.midi.xml \
    frameworks/native/data/etc/android.software.verified_boot.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.verified_boot.xml \
    frameworks/native/data/etc/tablet_core_hardware.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/tablet_core_hardware.xml

# Power
PRODUCT_PACKAGES += \
    android.hardware.power@1.0.vendor \
    android.hardware.power@1.1.vendor \
    android.hardware.power@1.2.vendor

# USB
PRODUCT_PACKAGES += \
    android.hardware.usb@1.0-service.basic

# Seccomp
PRODUCT_COPY_FILES += \
    $(call find-copy-subdir-files,*,$(LOCAL_PATH)/seccomp,$(TARGET_COPY_OUT_VENDOR)/etc/seccomp_policy)

# Sensors
PRODUCT_PACKAGES += \
    android.hardware.sensors@1.0.vendor \
    libsensorndkbridge

# Shims
PRODUCT_PACKAGES += \
    libshim_nvram \
    libshim_keymaster

# Thermal
PRODUCT_PACKAGES += \
    android.hardware.thermal@1.0-service \
    android.hardware.thermal@1.0-impl

# Rootdir
# Missing stock audio dependencies and the policy XML's A2DP include.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/prebuilt/vendor/lib/libpcm_merge.so:$(TARGET_COPY_OUT_VENDOR)/lib/libpcm_merge.so \
    $(LOCAL_PATH)/prebuilt/vendor/lib/libtensorflowlite_c.so:$(TARGET_COPY_OUT_VENDOR)/lib/libtensorflowlite_c.so \
    $(LOCAL_PATH)/prebuilt/vendor/lib/libmsb.so:$(TARGET_COPY_OUT_VENDOR)/lib/libmsb.so \
    $(LOCAL_PATH)/prebuilt/vendor/lib/libmsrc.so:$(TARGET_COPY_OUT_VENDOR)/lib/libmsrc.so \
    $(LOCAL_PATH)/prebuilt/vendor/lib/libedgeflow_core_neon.so:$(TARGET_COPY_OUT_VENDOR)/lib/libedgeflow_core_neon.so \
    $(LOCAL_PATH)/prebuilt/vendor/etc/a2dp_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/a2dp_audio_policy_configuration.xml

# Sensor HAL advertised in VINTF must have a service and the stock legacy module.
PRODUCT_PACKAGES += \
    android.hardware.sensors@1.0-service \
    android.hardware.sensors@1.0-impl
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/prebuilt/vendor/lib/hw/sensors.athena.so:$(TARGET_COPY_OUT_VENDOR)/lib/hw/sensors.athena.so

# Stock display composer is required; the gralloc framebuffer fallback is unsupported.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/prebuilt/vendor/lib/hw/hwcomposer.mt8183.so:$(TARGET_COPY_OUT_VENDOR)/lib/hw/hwcomposer.mt8183.so

# No bundled host authorization keys. Users must authorize their own ADB host.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/etc/zz-athena-recovery-guard.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/zz-athena-recovery-guard.rc

# Compatibility libraries required by the stock Amazon HALs.
PRODUCT_PACKAGES += \
    libutils-v32 \
    libcrypto-v32
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/prebuilt/vendor/lib/libunwindstack_shim.so:$(TARGET_COPY_OUT_VENDOR)/lib/libunwindstack_shim.so

# Android 11 ueventd loads the vendor-root path, unlike newer Android releases.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/etc/ueventd.mt8183.rc:$(TARGET_COPY_OUT_VENDOR)/ueventd.rc

PRODUCT_PACKAGES += \
    init.mt8183.rc \
    init.mt8183.usb.rc \
    init.connectivity.rc \
    init.project.rc \
    init.sensor_1_0.rc \
    init.target.rc \
    fstab.mt8183 \
    fstab.mt8183_ramdisk \
    ueventd.mt8183.rc

PRODUCT_PACKAGES += \
    init.recovery.mt8183.rc

# Screen Resolution
TARGET_SCREEN_WIDTH := 800
TARGET_SCREEN_HEIGHT := 1280

# Shipping API level
PRODUCT_SHIPPING_API_LEVEL := 28

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += \
    $(LOCAL_PATH)


# Wi-Fi
# Stock MediaTek stack and firmware match the forced stock ARM32 kernel.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/prebuilt/vendor/bin/hw/android.hardware.wifi@1.0-service:$(TARGET_COPY_OUT_VENDOR)/bin/hw/android.hardware.wifi@1.0-service \
    $(LOCAL_PATH)/prebuilt/vendor/etc/init/android.hardware.wifi@1.0-service.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/android.hardware.wifi@1.0-service.rc \
    $(LOCAL_PATH)/prebuilt/vendor/lib/libwifi-hal.so:$(TARGET_COPY_OUT_VENDOR)/lib/libwifi-hal.so \
    $(LOCAL_PATH)/prebuilt/vendor/lib/WifiMetrics.so:$(TARGET_COPY_OUT_VENDOR)/lib/WifiMetrics.so \
    $(LOCAL_PATH)/prebuilt/vendor/lib/fireos.hardware.connectivity@1.0.so:$(TARGET_COPY_OUT_VENDOR)/lib/fireos.hardware.connectivity@1.0.so \
    $(LOCAL_PATH)/prebuilt/vendor/lib/modules/wlan_mt76x3_sdio_prealloc.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/wlan_mt76x3_sdio_prealloc.ko \
    $(LOCAL_PATH)/prebuilt/vendor/lib/modules/wlan_mt76x3_sdio.ko:$(TARGET_COPY_OUT_VENDOR)/lib/modules/wlan_mt76x3_sdio.ko \
    $(LOCAL_PATH)/prebuilt/vendor/firmware/EEPROM_MT7663.bin:$(TARGET_COPY_OUT_VENDOR)/firmware/EEPROM_MT7663.bin \
    $(LOCAL_PATH)/prebuilt/vendor/firmware/WIFI_RAM_CODE_MT7663.bin:$(TARGET_COPY_OUT_VENDOR)/firmware/WIFI_RAM_CODE_MT7663.bin \
    $(LOCAL_PATH)/prebuilt/vendor/firmware/mt7663_patch_e2_hdr.bin:$(TARGET_COPY_OUT_VENDOR)/firmware/mt7663_patch_e2_hdr.bin \
    $(LOCAL_PATH)/prebuilt/vendor/firmware/wifi.cfg:$(TARGET_COPY_OUT_VENDOR)/firmware/wifi.cfg \
    $(LOCAL_PATH)/prebuilt/vendor/firmware/TxPwrLimit_MT76x3.dat:$(TARGET_COPY_OUT_VENDOR)/firmware/TxPwrLimit_MT76x3.dat

PRODUCT_COPY_FILES += \
    $(call find-copy-subdir-files,*,$(LOCAL_PATH)/wifi,$(TARGET_COPY_OUT_VENDOR)/etc/wifi)

PRODUCT_PACKAGES += \

PRODUCT_PACKAGES += \
    android.hardware.wifi@1.0.vendor \
    android.hardware.wifi@1.1.vendor \
    android.hardware.wifi@1.2.vendor \
    android.hardware.wifi@1.3.vendor \
    android.hardware.wifi.supplicant@1.0.vendor \
    android.hardware.wifi.supplicant@1.1.vendor \
    android.hardware.wifi.supplicant@1.2.vendor \
    android.hardware.wifi.hostapd@1.0.vendor \
    android.hardware.wifi.hostapd@1.1.vendor

# Inherit the proprietary files
$(call inherit-product, vendor/amazon/athena/athena-vendor.mk)
