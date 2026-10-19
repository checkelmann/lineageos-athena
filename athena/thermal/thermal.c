/* SPDX-License-Identifier: Apache-2.0 */
/* Read-only bridge: stock mtktz reports a stale cached -274C, while sysfs
 * reads the real sensors. Kernel/Amazon policies retain all cooling control.
 * No fabricated GPU/battery temperatures or guessed trip thresholds.
 */
#include <dirent.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <hardware/thermal.h>

static const struct {
    const char *zone;
    enum temperature_type type;
} sensors[] = {
    {"mtktscpu", DEVICE_TEMPERATURE_CPU},
    {"skin_virtual", DEVICE_TEMPERATURE_SKIN},
    {"display_cov_virtual", DEVICE_TEMPERATURE_UNKNOWN},
};

static int read_value(const char *path, long *value) {
    FILE *fp = fopen(path, "re");
    if (!fp) return -errno;
    int result = fscanf(fp, "%ld", value) == 1 ? 0 : -EIO;
    fclose(fp);
    return result;
}

static int find_zone(const char *name, char *path, size_t capacity) {
    DIR *directory = opendir("/sys/class/thermal");
    if (!directory) return -errno;
    struct dirent *entry;
    int found = -ENOENT;
    while ((entry = readdir(directory))) {
        if (strncmp(entry->d_name, "thermal_zone", 12)) continue;
        char type_path[512], type[128] = {0};
        snprintf(type_path, sizeof(type_path), "/sys/class/thermal/%s/type", entry->d_name);
        FILE *fp = fopen(type_path, "re");
        if (!fp) continue;
        int parsed = fscanf(fp, "%127s", type);
        fclose(fp);
        if (parsed == 1 && !strcmp(type, name)) {
            snprintf(path, capacity, "/sys/class/thermal/%s", entry->d_name);
            found = 0;
            break;
        }
    }
    closedir(directory);
    return found;
}

static float critical_trip(const char *zone) {
    float threshold = UNKNOWN_TEMPERATURE;
    for (int i = 0; i < 32; ++i) {
        char path[512], type[64] = {0};
        snprintf(path, sizeof(path), "%s/trip_point_%d_type", zone, i);
        FILE *fp = fopen(path, "re");
        if (!fp) continue;
        int parsed = fscanf(fp, "%63s", type);
        fclose(fp);
        if (parsed != 1 || strcmp(type, "critical")) continue;
        long raw;
        snprintf(path, sizeof(path), "%s/trip_point_%d_temp", zone, i);
        if (!read_value(path, &raw) && raw > 0 && raw < 200000) {
            float value = raw / 1000.0f;
            if (threshold == UNKNOWN_TEMPERATURE || value < threshold) threshold = value;
        }
    }
    return threshold;
}

static ssize_t temperatures(struct thermal_module *module, temperature_t *list, size_t size) {
    (void)module;
    const size_t count = sizeof(sensors) / sizeof(sensors[0]);
    if (!list) return count;
    for (size_t i = 0; i < count && i < size; ++i) {
        list[i] = (temperature_t) {
            .type = sensors[i].type,
            .name = sensors[i].zone,
            .current_value = UNKNOWN_TEMPERATURE,
            .throttling_threshold = UNKNOWN_TEMPERATURE,
            .shutdown_threshold = UNKNOWN_TEMPERATURE,
            .vr_throttling_threshold = UNKNOWN_TEMPERATURE,
        };
        char zone[256], path[512];
        if (find_zone(sensors[i].zone, zone, sizeof(zone))) continue;
        long raw;
        snprintf(path, sizeof(path), "%s/temp", zone);
        if (!read_value(path, &raw) && raw > -40000 && raw < 200000)
            list[i].current_value = raw / 1000.0f;
        list[i].shutdown_threshold = critical_trip(zone);
    }
    return count;
}

static ssize_t cooling(struct thermal_module *module, cooling_device_t *list, size_t size) {
    (void)module; (void)list; (void)size;
    /* Legacy 1.0 only represents FAN_RPM, not the stock CPU cooling states. */
    return 0;
}

/* The A11 adapter dereferences methods even when there is no open callback. */
static struct hw_module_methods_t methods = { .open = NULL };

thermal_module_t HAL_MODULE_INFO_SYM = {
    .common = {
        .tag = HARDWARE_MODULE_TAG,
        .module_api_version = THERMAL_HARDWARE_MODULE_API_VERSION_0_1,
        .hal_api_version = HARDWARE_HAL_API_VERSION,
        .id = THERMAL_HARDWARE_MODULE_ID,
        .name = "Athena stock-kernel sysfs thermal reporting",
        .author = "Athena port contributors",
        .methods = &methods,
    },
    .getTemperatures = temperatures,
    .getCoolingDevices = cooling,
};
