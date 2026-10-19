import android.hardware.thermal.V1_0.IThermal;

/** Read-only direct-HAL probe; deliberately does not change any temperatures/trips. */
public final class AthenaThermalTest {
    public static void main(String[] args) throws Exception {
        IThermal thermal = IThermal.getService();
        for (int sample = 0; sample < 5; sample++) {
            thermal.getTemperatures((status, temperatures) -> {
                System.out.println("HAL status=" + status.code + " " + status.debugMessage);
                for (android.hardware.thermal.V1_0.Temperature t : temperatures)
                    System.out.printf(java.util.Locale.ROOT, "%s type=%d current=%.3fC critical=%.3fC%n",
                            t.name, t.type, t.currentValue, t.shutdownThreshold);
            });
            Thread.sleep(1000);
        }
    }
}
