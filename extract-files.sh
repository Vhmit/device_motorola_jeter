#!/bin/bash
#
# Copyright (C) 2019 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

DEVICE=jeter
VENDOR=motorola

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

ANDROID_ROOT="${MY_DIR}/../../.."

HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

KANG=
SECTION=

while [ "${#}" -gt 0 ]; do
    case "${1}" in
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
    product/etc/permissions/vendor.qti.hardware.data.connection-V1.0-java.xml | product/etc/permissions/vendor.qti.hardware.data.connection-V1.1-java.xml)
        sed -i 's/xml version="2.0"/xml version="1.0"/' "${2}"
        ;;

    # memset shim
    vendor/bin/charge_only_mode)
        for LIBMEMSET_SHIM in $(grep -L "libmemset_shim.so" "${2}"); do
            "${PATCHELF}" --add-needed "libmemset_shim.so" "${LIBMEMSET_SHIM}"
        done
        ;;

    vendor/lib/hw/activity_recognition.msm8937.so | vendor/lib64/hw/activity_recognition.msm8937.so)
        "${PATCHELF}" --set-soname activity_recognition.msm8937.so "${2}"
        ;;

    vendor/lib64/hw/gatekeeper.msm8937.so)
        "${PATCHELF}" --set-soname gatekeeper.msm8937.so "${2}"
        ;;

    vendor/lib64/hw/keystore.msm8937.so)
        "${PATCHELF}" --set-soname keystore.msm8937.so "${2}"
        ;;

    vendor/lib/libjscore.so | vendor/lib/libmmcamera_vstab_module.so)
        sed -i "s/libgui/libwui/" "${2}"
        ;;

    # Fix camera recording
    vendor/lib/libmmcamera2_pproc_modules.so)
        sed -i "s/ro.product.manufacturer/ro.product.nopefacturer/" "${2}"
        ;;

    vendor/lib64/libmdmcutback.so)
        sed -i "s|libqsap_sdk.so|libqsapshim.so|g" "${2}"
        ;;
    esac
}

# Initialize the helper
setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" false "${CLEAN_VENDOR}"

extract "${MY_DIR}/proprietary-files.txt" "${SRC}" "${KANG}" --section "${SECTION}"
extract "${MY_DIR}/proprietary-files-qc.txt" "${SRC}" "${KANG}" --section "${SECTION}"

"${MY_DIR}/setup-makefiles.sh"
