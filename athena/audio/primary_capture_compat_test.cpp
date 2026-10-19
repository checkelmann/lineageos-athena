/* SPDX-License-Identifier: Apache-2.0 */
#include "primary_capture_compat.cpp"
#include <gtest/gtest.h>

namespace {
audio_stream_in input;
audio_source_t observed_source;
std::string observed_parameters;
audio_port_config observed_sink;
bool closed;
bool mute_sequence[2];
unsigned mute_call;

bool fake_muted() {
    return mute_sequence[(mute_call++) % 2];
}

ssize_t fake_read(audio_stream_in*, void* buffer, size_t bytes) {
    memset(buffer, 0x55, bytes);
    return bytes;
}

int fake_parameters(audio_stream*, const char* text) {
    observed_parameters = text;
    return 17;
}

int fake_open(audio_hw_device*, audio_io_handle_t, audio_devices_t, audio_config*,
              audio_stream_in** stream, audio_input_flags_t, const char*, audio_source_t source) {
    observed_source = source;
    input = {};
    input.common.set_parameters = fake_parameters;
    input.read = fake_read;
    *stream = &input;
    return 0;
}

void fake_close(audio_hw_device*, audio_stream_in* stream) {
    closed = stream->common.set_parameters == fake_parameters && stream->read == fake_read;
}

int fake_patch(audio_hw_device*, unsigned int, const audio_port_config*, unsigned int count,
               const audio_port_config* sinks, audio_patch_handle_t*) {
    if (count) observed_sink = sinks[0];
    return 23;
}

class CaptureCompat : public testing::Test {
    void SetUp() override {
        stock_open_input = fake_open;
        stock_close_input = fake_close;
        stock_create_patch = fake_patch;
        setters.clear();
        closed = false;
        mute_sequence[0] = mute_sequence[1] = false;
        mute_call = 0;
        hardware_muted = fake_muted;
    }
};

TEST_F(CaptureCompat, OnlyProcessedSourcesAreMapped) {
    for (auto source : {AUDIO_SOURCE_DEFAULT, AUDIO_SOURCE_MIC, AUDIO_SOURCE_CAMCORDER,
                        AUDIO_SOURCE_VOICE_COMMUNICATION, AUDIO_SOURCE_VOICE_PERFORMANCE})
        EXPECT_EQ(AUDIO_SOURCE_VOICE_RECOGNITION, capture_source(source));
    for (int value : {2, 3, 4, 6, 8, 9, 1999, 2999}) {
        const auto source = static_cast<audio_source_t>(value);
        EXPECT_EQ(source, capture_source(source));
    }
}

TEST_F(CaptureCompat, BuiltinOpenParameterUpdateAndCloseAreForwarded) {
    audio_config config = {};
    config.sample_rate = 16000;
    audio_stream_in* stream = nullptr;
    ASSERT_EQ(0, open_input(nullptr, 1, AUDIO_DEVICE_IN_BUILTIN_MIC, &config, &stream,
                            AUDIO_INPUT_FLAG_NONE, "", AUDIO_SOURCE_MIC));
    EXPECT_EQ(AUDIO_SOURCE_VOICE_RECOGNITION, observed_source);
    EXPECT_EQ(17, stream->common.set_parameters(&stream->common, "input_source=1;routing=123"));
    auto* parsed = str_parms_create_str(observed_parameters.c_str());
    int value = 0;
    ASSERT_GE(str_parms_get_int(parsed, "input_source", &value), 0);
    EXPECT_EQ(6, value);
    ASSERT_GE(str_parms_get_int(parsed, "routing", &value), 0);
    EXPECT_EQ(123, value);
    str_parms_destroy(parsed);
    EXPECT_EQ(17, stream->common.set_parameters(&stream->common, "routing=456"));
    EXPECT_EQ("routing=456", observed_parameters);
    close_input(nullptr, stream);
    EXPECT_TRUE(closed);
    EXPECT_TRUE(setters.empty());
}

TEST_F(CaptureCompat, ExternalMicrophoneIsUntouched) {
    audio_config config = {};
    audio_stream_in* stream = nullptr;
    ASSERT_EQ(0, open_input(nullptr, 1, AUDIO_DEVICE_IN_USB_DEVICE, &config, &stream,
                            AUDIO_INPUT_FLAG_NONE, "", AUDIO_SOURCE_MIC));
    EXPECT_EQ(AUDIO_SOURCE_MIC, observed_source);
    EXPECT_EQ(&fake_parameters, stream->common.set_parameters);
    EXPECT_EQ(&fake_read, stream->read);
    EXPECT_TRUE(setters.empty());
}

TEST_F(CaptureCompat, RoutingTranslatesCopyWithoutChangingCallerOrOtherFields) {
    audio_port_config source = {};
    source.type = AUDIO_PORT_TYPE_DEVICE;
    source.role = AUDIO_PORT_ROLE_SOURCE;
    source.ext.device.type = AUDIO_DEVICE_IN_BUILTIN_MIC;
    audio_port_config sink = {};
    sink.type = AUDIO_PORT_TYPE_MIX;
    sink.role = AUDIO_PORT_ROLE_SINK;
    sink.sample_rate = 48000;
    sink.channel_mask = AUDIO_CHANNEL_IN_STEREO;
    sink.ext.mix.handle = 42;
    sink.ext.mix.usecase.source = AUDIO_SOURCE_CAMCORDER;
    const auto original = sink;
    EXPECT_EQ(23, create_patch(nullptr, 1, &source, 1, &sink, nullptr));
    EXPECT_EQ(AUDIO_SOURCE_VOICE_RECOGNITION, observed_sink.ext.mix.usecase.source);
    observed_sink.ext.mix.usecase.source = AUDIO_SOURCE_CAMCORDER;
    EXPECT_EQ(0, memcmp(&sink, &original, sizeof(sink)));
    EXPECT_EQ(0, memcmp(&observed_sink, &original, sizeof(sink)));
    source.ext.device.type = AUDIO_DEVICE_IN_USB_DEVICE;
    EXPECT_EQ(23, create_patch(nullptr, 1, &source, 1, &sink, nullptr));
    EXPECT_EQ(AUDIO_SOURCE_CAMCORDER, observed_sink.ext.mix.usecase.source);
}

TEST_F(CaptureCompat, PrivacyGuardZerosMutedAndTransitionBuffersButPreservesUnmuted) {
    audio_config config = {};
    audio_stream_in* stream = nullptr;
    ASSERT_EQ(0, open_input(nullptr, 1, AUDIO_DEVICE_IN_BUILTIN_MIC, &config, &stream,
                            AUDIO_INPUT_FLAG_NONE, "", AUDIO_SOURCE_MIC));
    for (auto pair : {std::pair<bool, bool>{false, false}, {true, true},
                     {false, true}, {true, false}}) {
        mute_sequence[0] = pair.first;
        mute_sequence[1] = pair.second;
        mute_call = 0;
        unsigned char buffer[16];
        memset(buffer, 0xee, sizeof(buffer));
        ASSERT_EQ(16, stream->read(stream, buffer, sizeof(buffer)));
        EXPECT_EQ(2u, mute_call);
        for (auto value : buffer) EXPECT_EQ(pair.first || pair.second ? 0 : 0x55, value);
    }
    close_input(nullptr, stream);
    EXPECT_TRUE(closed);
}

TEST_F(CaptureCompat, PrivacyStateFailureIsMuted) {
    EXPECT_TRUE(read_privacy_mute_path("/dev/null"));
    EXPECT_TRUE(read_privacy_mute_path("/athena-nonexistent-privacy-test-path"));
}
}  // namespace
