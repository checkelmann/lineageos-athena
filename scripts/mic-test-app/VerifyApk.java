import com.android.apksig.ApkVerifier;
import java.io.File;

/** Avoid this SDK's CLI null-SourceStamp printing bug; retain real verification. */
public final class VerifyApk {
    public static void main(String[] args) throws Exception {
        ApkVerifier.Result result = new ApkVerifier.Builder(new File(args[0]))
                .setMinCheckedPlatformVersion(30).setMaxCheckedPlatformVersion(30)
                .build().verify();
        if (!result.isVerified()) throw new IllegalStateException("APK signature invalid: " + result.getErrors());
        System.out.println("Android30 APK signature verification passed");
    }
}
