/* SPDX-License-Identifier: Apache-2.0 */
#define LOG_TAG "AthenaCaptureCompat"
// This tree's audio-base-utils references a framework enum unconditionally.
// Include enum declarations first; only port-struct layout must use the HAL ABI.
#include <system/audio-base.h>
// HAL port structs omit framework-only fields. The stock FireOS adapter passes
// 212-byte audio_port_config records with ext at172 on ARM32.
#define AUDIO_NO_SYSTEM_DECLARATIONS

#include <hardware/audio.h>
#include <cutils/str_parms.h>
#include <dlfcn.h>
#include <errno.h>
#include <stddef.h>
#include <log/log.h>
#include <stdlib.h>
#include <string.h>

#include <mutex>
#include <unordered_map>
#include <vector>

static_assert(sizeof(audio_port_config) == 212, "Stock ARM32 port ABI mismatch");
static_assert(offsetof(audio_port_config, ext) == 172, "Stock port extension ABI mismatch");
static_assert(offsetof(audio_hw_device, create_audio_patch) == 140, "Stock device ABI mismatch");

// Keep all stock routing, DSP, playback and privacy functions. Only translate
// standard processed microphone use cases to the working stock ASR capture path.
// MIC selects unimplemented ASP pipeline2 in this firmware; ASR selects pipeline0.
// Do not translate telephony, HOTWORD/private Amazon sources, or UNPROCESSED:
// returning processed ASR while advertising raw capture would be misleading.
static audio_source_t capture_source(audio_source_t source) {
    switch (source) {
        case AUDIO_SOURCE_DEFAULT:
        case AUDIO_SOURCE_MIC:
        case AUDIO_SOURCE_CAMCORDER:
        case AUDIO_SOURCE_VOICE_COMMUNICATION:
        case AUDIO_SOURCE_VOICE_PERFORMANCE:
            return AUDIO_SOURCE_VOICE_RECOGNITION;
        default:
            return source;
    }
}

using OpenInput = decltype(audio_hw_device::open_input_stream);
using CloseInput = decltype(audio_hw_device::close_input_stream);
using SetParameters = decltype(audio_stream::set_parameters);
using CreatePatch = decltype(audio_hw_device::create_audio_patch);
static std::mutex lock;
static OpenInput stock_open_input;
static CloseInput stock_close_input;
static CreatePatch stock_create_patch;
static std::unordered_map<audio_stream*, SetParameters> setters;

static int set_parameters(audio_stream* stream, const char* text) {
    SetParameters original;
    {
        std::lock_guard<std::mutex> guard(lock);
        auto it = setters.find(stream);
        if (it == setters.end()) return -EINVAL;
        original = it->second;
    }
    if (!text) return -EINVAL;
    str_parms* params = str_parms_create_str(text);
    if (!params) return -ENOMEM;
    int source;
    char* rewritten = nullptr;
    if (str_parms_get_int(params, AUDIO_PARAMETER_STREAM_INPUT_SOURCE, &source) >= 0) {
        audio_source_t mapped = capture_source(static_cast<audio_source_t>(source));
        if (mapped != source) {
            str_parms_add_int(params, AUDIO_PARAMETER_STREAM_INPUT_SOURCE, mapped);
            rewritten = str_parms_to_str(params);
            if (!rewritten) {
                str_parms_destroy(params);
                return -ENOMEM;
            }
        }
    }
    const int result = original(stream, rewritten ? rewritten : text);
    free(rewritten);
    str_parms_destroy(params);
    return result;
}

static int open_input(audio_hw_device* device, audio_io_handle_t handle,
                      audio_devices_t devices, audio_config* config,
                      audio_stream_in** stream, audio_input_flags_t flags,
                      const char* address, audio_source_t source) {
    // Do not change USB/Bluetooth capture; only the internal microphone needs this.
    const bool builtin = devices == AUDIO_DEVICE_IN_BUILTIN_MIC ||
                         devices == AUDIO_DEVICE_IN_BACK_MIC;
    const audio_source_t mapped = builtin ? capture_source(source) : source;
    const int result = stock_open_input(device, handle, devices, config, stream,
                                        flags, address, mapped);
    if (result == 0 && stream && *stream && builtin) {
        std::lock_guard<std::mutex> guard(lock);
        auto* common = &(*stream)->common;
        if (common->set_parameters && common->set_parameters != set_parameters) {
            setters[common] = common->set_parameters;
            common->set_parameters = set_parameters;
        }
        ALOGI("Built-in capture source %d -> %d, rate=%u channels=0x%x flags=0x%x",
              source, mapped, config->sample_rate, config->channel_mask, flags);
    }
    return result;
}

static void close_input(audio_hw_device* device, audio_stream_in* stream) {
    if (stream) {
        std::lock_guard<std::mutex> guard(lock);
        auto it = setters.find(&stream->common);
        if (it != setters.end()) {
            stream->common.set_parameters = it->second;
            setters.erase(it);
        }
    }
    stock_close_input(device, stream);
}

static int create_patch(audio_hw_device* device, unsigned int num_sources,
                        const audio_port_config* sources, unsigned int num_sinks,
                        const audio_port_config* sinks, audio_patch_handle_t* handle) {
    if (!stock_create_patch) return -ENOSYS;
    if ((num_sources && !sources) || (num_sinks && !sinks)) return -EINVAL;
    bool builtin = false;
    for (unsigned int i = 0; i < num_sources; ++i) {
        if (sources[i].type == AUDIO_PORT_TYPE_DEVICE &&
            (sources[i].ext.device.type == AUDIO_DEVICE_IN_BUILTIN_MIC ||
             sources[i].ext.device.type == AUDIO_DEVICE_IN_BACK_MIC)) builtin = true;
    }
    if (!builtin || !num_sinks)
        return stock_create_patch(device, num_sources, sources, num_sinks, sinks, handle);
    // The stock createAudioPatch bypasses audio_stream.set_parameters and writes
    // input_source directly into its stream manager. Translate this path too.
    std::vector<audio_port_config> translated(sinks, sinks + num_sinks);
    for (auto& sink : translated) {
        if (sink.type == AUDIO_PORT_TYPE_MIX && sink.role == AUDIO_PORT_ROLE_SINK) {
            const auto source = sink.ext.mix.usecase.source;
            sink.ext.mix.usecase.source = capture_source(source);
            ALOGI("Built-in patch capture source %d -> %d", source, sink.ext.mix.usecase.source);
        }
    }
    return stock_create_patch(device, num_sources, sources, num_sinks, translated.data(), handle);
}

static int open_device(const hw_module_t*, const char* name, hw_device_t** output) {
    if (!name || !output || strcmp(name, AUDIO_HARDWARE_INTERFACE)) return -EINVAL;
    // Different module filename/SONAME prevents recursive loading. Never unload:
    // returned device and streams retain callbacks into this stock shared object.
    static void* library = dlopen("/vendor/lib/hw/audio.primary.mt8183.so", RTLD_NOW | RTLD_LOCAL);
    if (!library) {
        ALOGE("Stock primary load failed: %s", dlerror());
        return -ENODEV;
    }
    auto* module = static_cast<hw_module_t*>(dlsym(library, HAL_MODULE_INFO_SYM_AS_STR));
    if (!module || !module->id || strcmp(module->id, AUDIO_HARDWARE_MODULE_ID) ||
        !module->methods || !module->methods->open) return -EINVAL;
    const int result = module->methods->open(module, name, output);
    if (result != 0) return result;
    auto* device = reinterpret_cast<audio_hw_device*>(*output);
    if (!device || device->common.version < AUDIO_DEVICE_API_VERSION_2_0 ||
        !device->open_input_stream || !device->close_input_stream) {
        if (device && device->common.close) device->common.close(&device->common);
        *output = nullptr;
        return -EINVAL;
    }
    std::lock_guard<std::mutex> guard(lock);
    if (device->open_input_stream != open_input) {
        stock_open_input = device->open_input_stream;
        stock_close_input = device->close_input_stream;
        stock_create_patch = device->create_audio_patch;
        device->open_input_stream = open_input;
        device->close_input_stream = close_input;
        if (stock_create_patch) device->create_audio_patch = create_patch;
    }
    ALOGI("Stock primary loaded; processed built-in capture compatibility enabled");
    return 0;
}

static hw_module_methods_t methods = { .open = open_device };
extern "C" {
audio_module HAL_MODULE_INFO_SYM = {
    .common = {
        .tag = HARDWARE_MODULE_TAG,
        .module_api_version = AUDIO_MODULE_API_VERSION_CURRENT,
        .hal_api_version = HARDWARE_HAL_API_VERSION,
        .id = AUDIO_HARDWARE_MODULE_ID,
        .name = "Athena stock audio capture compatibility",
        .author = "Athena port contributors",
        .methods = &methods,
        .dso = nullptr,
        .reserved = {0},
    },
};
}
