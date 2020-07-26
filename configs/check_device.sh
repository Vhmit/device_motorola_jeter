#!/sbin/sh

sku=`getprop ro.boot.hardware.sku`

if [ "$sku" = "XT1922-2" ] || [ "$sku" = "XT1922-3" ] || [ "$sku" = "XT1922-4" ] || [ "$sku" = "XT1922-5" ] || [ "$sku" = "XT1922-10" ]; then
    mv /vendor/etc/audio_platform_info_aljeter.xml /vendor/etc/audio_platform_info.xml
    mv /vendor/etc/mixer_paths_aljeter.xml /vendor/etc/mixer_paths.xml
    mv /vendor/etc/thermal-engine-aljeter.conf /vendor/etc/thermal-engine.conf
    mv /vendor/etc/sensors/sensor_def_qcomdev_aljeter.conf /vendor/etc/sensors/sensor_def_qcomdev.conf
else
    rm /vendor/etc/audio_platform_info_aljeter.xml
    rm /vendor/etc/mixer_paths_aljeter.xml
    rm /vendor/etc/thermal-engine-aljeter.conf
    rm /vendor/etc/sensors/sensor_def_qcomdev_aljeter.conf
    rm /vendor/etc/permissions/android.hardware.vulkan.compute.xml
    rm /vendor/etc/permissions/android.hardware.vulkan.level.xml
    rm /vendor/etc/permissions/android.hardware.vulkan.version.xml
fi
