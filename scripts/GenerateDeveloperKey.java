import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.security.KeyPairGenerator;
import java.security.MessageDigest;
import java.util.HexFormat;

/** One-time RSA 4096 PKCS#8 DER signing key generation. Never overwrites a key. */
class GenerateDeveloperKey {
    public static void main(String[] args) throws Exception {
        if (args.length != 1) throw new IllegalArgumentException("Supply the output .der path.");
        Path output = Path.of(args[0]).toAbsolutePath();
        if (Files.exists(output)) throw new IllegalStateException("Key already exists; refusing to replace it.");
        Files.createDirectories(output.getParent());
        var generator = KeyPairGenerator.getInstance("RSA");
        generator.initialize(4096);
        var pair = generator.generateKeyPair();
        Files.write(output, pair.getPrivate().getEncoded(), StandardOpenOption.CREATE_NEW);
        String fingerprint = HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256")
            .digest(pair.getPublic().getEncoded()));
        Files.writeString(output.resolveSibling("public-key-sha256.txt"), fingerprint + "\n",
            StandardOpenOption.CREATE_NEW);
        System.out.println("Created RSA 4096 signing key: " + output);
        System.out.println("Public-key SHA-256 fingerprint: " + fingerprint);
        System.out.println("Back up the private key securely. Future store updates require this same key.");
    }
}
