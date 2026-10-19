import android.media.AudioFormat;
import android.media.AudioRecord;
import android.media.AudioSystem;
import android.media.MediaRecorder;

/** Opt-in bounded capture; prints signal levels only, saves no audio. */
public final class AthenaMicTest {
    public static void main(String[] args) throws Exception {
        if (args.length < 1 || args.length > 5 || !args[0].equals("--record-test")) {
            System.out.println("No recording started. Use --record-test only with consent.");
            System.out.println("frameworkMicrophoneMuted=" + AudioSystem.isMicrophoneMuted());
            return;
        }
        int seconds = args.length > 2 ? Integer.parseInt(args[2]) : 10;
        int rate = args.length > 3 ? Integer.parseInt(args[3]) : 16000;
        int channels = args.length > 4 ? Integer.parseInt(args[4]) : 1;
        if (seconds < 1 || seconds > 120 || rate < 8000 || rate > 48000 ||
                (channels != 1 && channels != 2)) throw new IllegalArgumentException("Invalid capture limits");
        int mask = channels == 1 ? AudioFormat.CHANNEL_IN_MONO : AudioFormat.CHANNEL_IN_STEREO;
        int min = AudioRecord.getMinBufferSize(rate, mask,
                AudioFormat.ENCODING_PCM_16BIT);
        if (min <= 0) throw new IllegalStateException("minBufferSize=" + min);
        int source = MediaRecorder.AudioSource.MIC;
        if (args.length >= 2) {
            if (args[1].equals("mic")) source = MediaRecorder.AudioSource.MIC;
            else if (args[1].equals("default")) source = MediaRecorder.AudioSource.DEFAULT;
            else if (args[1].equals("camcorder")) source = MediaRecorder.AudioSource.CAMCORDER;
            else if (args[1].equals("voice-communication")) source = MediaRecorder.AudioSource.VOICE_COMMUNICATION;
            else if (args[1].equals("voice-performance")) source = MediaRecorder.AudioSource.VOICE_PERFORMANCE;
            else if (args[1].equals("voice-recognition")) source = MediaRecorder.AudioSource.VOICE_RECOGNITION;
            else if (args[1].equals("unprocessed")) source = MediaRecorder.AudioSource.UNPROCESSED;
            else throw new IllegalArgumentException("Unsupported test source: " + args[1]);
        }
        System.out.println("Testing AudioSource=" + source + " rate=" + rate + " channels=" + channels);
        AudioRecord input = new AudioRecord(source, rate,
                mask, AudioFormat.ENCODING_PCM_16BIT,
                Math.max(min, rate * channels * 2));
        try {
            System.out.println("AudioRecord state=" + input.getState());
            if (input.getState() != AudioRecord.STATE_INITIALIZED)
                throw new IllegalStateException("AudioRecord initialization failed");
            input.startRecording();
            System.out.println("Recording deliberate test for " + seconds + "s; no audio file is saved.");
            short[] samples = new short[rate * channels];
            for (int second = 1; second <= seconds; second++) {
                int count = input.read(samples, 0, samples.length, AudioRecord.READ_BLOCKING);
                if (count <= 0) throw new IllegalStateException("read=" + count);
                double sum = 0;
                int peak = 0, nonzero = 0;
                for (int i = 0; i < count; i++) {
                    int value = samples[i];
                    sum += (double)value * value;
                    peak = Math.max(peak, Math.abs(value));
                    if (value != 0) nonzero++;
                }
                double rms = Math.sqrt(sum / count);
                double db = rms == 0 ? Double.NEGATIVE_INFINITY : 20 * Math.log10(rms / 32768);
                System.out.printf(java.util.Locale.ROOT, "second=%d samples=%d rms=%.2f dBFS=%.1f peak=%d nonzero=%d muted=%s%n",
                        second, count, rms, db, peak, nonzero, AudioSystem.isMicrophoneMuted());
            }
            input.stop();
        } finally {
            input.release();
            System.out.println("Capture released; no audio retained.");
        }
    }
}
