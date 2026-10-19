#
# Copyright (C) 2026 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_minimal.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base.mk)

# Inherit from device makefile.
$(call inherit-product, device/amazon/athena/device.mk)

# Inherit some common LineageOS stuff.
$(call inherit-product, vendor/lineage/config/common_full_tablet_wifionly.mk)

PRODUCT_NAME := lineage_athena
PRODUCT_DEVICE := athena
PRODUCT_MANUFACTURER := Amazon
PRODUCT_BRAND := Amazon
PRODUCT_MODEL := Echo Show 8 (2nd Gen)
