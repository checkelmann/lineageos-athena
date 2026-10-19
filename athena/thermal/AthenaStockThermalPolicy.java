import android.os.HwBinder;
import android.os.HwParcel;
import android.os.IHwBinder;

/** Restore the OEM locale thermal policy through its existing HAL method.
 * Stock BpHwAmazonThermal confirms transaction3 with one hidl_string argument.
 * This does not invent limits, fake temperatures, or trigger a heat test.
 */
public final class AthenaStockThermalPolicy {
    public static void main(String[] args) throws Exception {
        if ((args.length != 1 && args.length != 2) || !args[0].equals("--apply-stock-policy")) {
            System.out.println("No changes. Usage: --apply-stock-policy [configured-locale]");
            return;
        }
        String locale = args.length == 2 ? args[1]
                : android.os.SystemProperties.get("persist.sys.locale", "en-US");
        IHwBinder service = null;
        for (int attempt = 0; attempt < 30; attempt++) {
            try {
                service = HwBinder.getService(
                        "fireos.hardware.amazonthermal@1.0::IAmazonThermal", "default");
                break;
            } catch (java.util.NoSuchElementException | android.os.RemoteException unavailable) {
                if (attempt == 29) throw unavailable;
                Thread.sleep(1000);
            }
        }
        if (service == null) throw new IllegalStateException("OEM thermal HAL unavailable");
        HwParcel request = new HwParcel();
        HwParcel reply = new HwParcel();
        try {
            request.writeInterfaceToken("fireos.hardware.amazonthermal@1.1::IAmazonThermal");
            request.writeString(locale);
            service.transact(3, request, reply, 0);
            reply.verifySuccess();
            System.out.println("OEM setLocalePolicy transport succeeded: " + locale);
            System.out.println("Verify HAL logs and kernel governors/trips; transport alone is not proof.");
        } finally {
            request.releaseTemporaryStorage();
            reply.release();
        }
    }
}
