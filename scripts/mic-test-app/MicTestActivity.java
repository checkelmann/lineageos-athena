package org.lineageos.athena.mictest;

import android.Manifest;
import android.app.Activity;
import android.content.pm.PackageManager;
import android.media.AudioFormat;
import android.media.AudioRecord;
import android.os.Bundle;
import android.os.Handler;
import android.util.Log;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;
import java.util.Locale;

/** Foreground, bounded test using ordinary app permissions; never saves audio. */
public final class MicTestActivity extends Activity {
    private TextView output;
    private volatile boolean running;
    private final Handler handler = new Handler();
    private final StringBuilder lines = new StringBuilder();

    private void report(String line) {
        Log.i("AthenaMicApp", line);
        runOnUiThread(() -> {
            lines.append(line).append('\n');
            output.setText(lines.toString());
        });
    }

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        LinearLayout layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.VERTICAL);
        layout.setPadding(24, 12, 24, 12);
        Button start = new Button(this);
        start.setText("Start 10-second MIC test (no audio saved)");
        start.setOnClickListener(view -> startTest());
        layout.addView(start);
        output = new TextView(this);
        output.setTextSize(17);
        layout.addView(output);
        setContentView(layout);
        report("Idle. Tests print levels only. No network permission or audio files.");
        if (getIntent().getBooleanExtra("run_test", false)) {
            report("Announced test starts in five seconds; say a short test phrase.");
            handler.postDelayed(this::startTest, 5000);
        }
    }

    private void startTest() {
        if (running) return;
        if (checkSelfPermission(Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            requestPermissions(new String[]{Manifest.permission.RECORD_AUDIO}, 1);
            report("Grant microphone permission, then tap Start.");
            return;
        }
        int source = getIntent().getIntExtra("source", 1);
        int seconds = getIntent().getIntExtra("seconds", 10);
        int rate = getIntent().getIntExtra("rate", 16000);
        int channels = getIntent().getIntExtra("channels", 1);
        if (seconds < 1 || seconds > 120 || rate < 8000 || rate > 48000 ||
                (channels != 1 && channels != 2)) {
            report("Invalid capture limits.");
            return;
        }
        running = true;
        new Thread(() -> capture(source, seconds, rate, channels), "AthenaMicTest").start();
    }

    private void capture(int source, int seconds, int rate, int channels) {
        AudioRecord input = null;
        try {
            int mask = channels == 1 ? AudioFormat.CHANNEL_IN_MONO : AudioFormat.CHANNEL_IN_STEREO;
            int min = AudioRecord.getMinBufferSize(rate, mask, AudioFormat.ENCODING_PCM_16BIT);
            if (min < 1) throw new IllegalStateException("minBufferSize=" + min);
            input = new AudioRecord(source, rate, mask, AudioFormat.ENCODING_PCM_16BIT,
                    Math.max(min, rate * channels * 2));
            if (input.getState() != AudioRecord.STATE_INITIALIZED)
                throw new IllegalStateException("AudioRecord not initialized");
            report("Capture source=" + source + " rate=" + rate + " channels=" + channels);
            input.startRecording();
            short[] buffer = new short[rate * channels];
            for (int second = 1; second <= seconds && running; second++) {
                int count = input.read(buffer, 0, buffer.length, AudioRecord.READ_BLOCKING);
                if (count <= 0) throw new IllegalStateException("read=" + count);
                double sum = 0;
                int peak = 0, nonzero = 0;
                for (int i = 0; i < count; i++) {
                    int value = buffer[i];
                    sum += (double)value * value;
                    peak = Math.max(peak, Math.abs(value));
                    if (value != 0) nonzero++;
                }
                double rms = Math.sqrt(sum / count);
                report(String.format(Locale.ROOT, "second=%d samples=%d rms=%.2f peak=%d nonzero=%d",
                        second, count, rms, peak, nonzero));
            }
            input.stop();
        } catch (Exception error) {
            report("ERROR: " + error);
        } finally {
            if (input != null) input.release();
            running = false;
            report("Capture released. No audio retained.");
        }
    }

    @Override public void onStop() {
        handler.removeCallbacksAndMessages(null);
        running = false;
        super.onStop();
    }
}
