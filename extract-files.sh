#!/bin/bash
#
# Copyright (C) 2019 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

DEVICE_COMMON=msm8937-common
VENDOR=motorola

# Load extract_utils and do some sanity checks
COMMON_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$COMMON_DIR" ]]; then COMMON_DIR="$PWD"; fi

if [[ -z "$DEVICE_DIR" ]]; then
    DEVICE_DIR="${COMMON_DIR}/../${DEVICE}"
fi

LINEAGE_ROOT="$COMMON_DIR"/../../..

HELPER="$LINEAGE_ROOT"/vendor/lineage/build/tools/extract_utils.sh
if [ ! -f "$HELPER" ]; then
    echo "Unable to find helper script at $HELPER"
    exit 1
fi
. "$HELPER"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true
ONLY_COMMON=false
ONLY_DEVICE=false

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        -o | --only-common )
                ONLY_COMMON=true
                ;;
        -d | --only-device )
                ONLY_DEVICE=true
                ;;
        -n | --no-cleanup )
                CLEAN_VENDOR=false
                ;;
        -k | --kang )
                KANG="--kang"
                ;;
        -s | --section )
                SECTION="${2}"; shift
                CLEAN_VENDOR=false
                ;;
        * )
                SRC="${1}"
                ;;
    esac
    shift
done

if [ -z "${SRC}" ]; then
    SRC="adb"
fi

# Load wrapped shim
function blob_fixup() {
    case "${1}" in
    lib64/libwfdnative.so)
        patchelf --remove-needed android.hidl.base@1.0.so "${2}"
        ;;

    product/etc/permissions/vendor.qti.hardware.data.connection-V1.0-java.xml | product/etc/permissions/vendor.qti.hardware.data.connection-V1.1-java.xml)
        sed -i 's/xml version="2.0"/xml version="1.0"/' "${2}"
        ;;

    vendor/lib/hw/activity_recognition.msm8937.so | vendor/lib64/hw/activity_recognition.msm8937.so)
        patchelf --set-soname activity_recognition.msm8937.so "${2}"
        ;;

    vendor/lib64/hw/gatekeeper.msm8937.so)
        patchelf --set-soname gatekeeper.msm8937.so "${2}"
        ;;

    vendor/lib64/hw/keystore.msm8937.so)
        patchelf --set-soname keystore.msm8937.so "${2}"
        ;;

    vendor/lib64/libmdmcutback.so)
        sed -i "s|libqsap_sdk.so|libqsapshim.so|g" "${2}"
        ;;
    esac
}

# Initialize the helper
setup_vendor "$DEVICE_COMMON" "$VENDOR" "$LINEAGE_ROOT" true $CLEAN_VENDOR

if [[ "$ONLY_DEVICE" = "false" ]] && [[ -s "${COMMON_DIR}"/proprietary-files.txt ]]; then
    extract "$COMMON_DIR"/proprietary-files.txt "$SRC" "${KANG}" --section "${SECTION}"
fi
if [[ "$ONLY_COMMON" = "false" ]] && [[ -s "${DEVICE_DIR}"/proprietary-files.txt ]]; then
    if [[ ! "$IS_COMMON" = "true" ]]; then
        IS_COMMON=false
    fi
    # Reinitialize the helper for device
    setup_vendor "$DEVICE" "$VENDOR" "$LINEAGE_ROOT" "$IS_COMMON" "$CLEAN_VENDOR"
    extract "${DEVICE_DIR}"/proprietary-files.txt "$SRC" "${KANG}" --section "${SECTION}"
fi

"$COMMON_DIR"/setup-makefiles.sh
