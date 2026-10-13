import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.nio.file.Path;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import javax.xml.XMLConstants;
import javax.xml.parsers.DocumentBuilderFactory;
import org.apache.commons.compress.archivers.sevenz.SevenZFile;

/** Inspect Garmin's 7z-format IQ archive without extracting it. */
@SuppressWarnings("deprecation")
class InspectPackage {
    public static void main(String[] args) throws Exception {
        if (args.length != 1) throw new IllegalArgumentException("Supply the .iq package path.");
        Set<String> expected = Set.of("fr255", "fr255m", "fr255s", "fr255sm");
        // Part numbers verified against Garmin's official device compiler.json files.
        Map<String, String> deviceByPart = Map.of(
            "006-B3992-00", "fr255", "006-B3990-00", "fr255m",
            "006-B3993-00", "fr255s", "006-B3991-00", "fr255sm");
        Set<String> devices = new HashSet<>();
        Set<String> names = new HashSet<>();
        byte[] manifestBytes = null;
        try (var archive = new SevenZFile(Path.of(args[0]).toFile())) {
            for (var entry = archive.getNextEntry(); entry != null; entry = archive.getNextEntry()) {
                String name = entry.getName();
                String lower = name.toLowerCase();
                if (lower.endsWith(".der") || lower.endsWith(".pem") || lower.contains(".private/") || lower.contains(".tools/")) {
                    throw new IllegalStateException("Private/tool file included in package: " + name);
                }
                names.add(name);
                if (name.equals("manifest.xml")) {
                    var output = new ByteArrayOutputStream();
                    byte[] buffer = new byte[8192];
                    int count;
                    while ((count = archive.read(buffer)) > 0) output.write(buffer, 0, count);
                    manifestBytes = output.toByteArray();
                }
            }
        }
        if (manifestBytes == null) throw new IllegalStateException("Package manifest is missing.");
        var factory = DocumentBuilderFactory.newInstance();
        factory.setNamespaceAware(true);
        factory.setFeature(XMLConstants.FEATURE_SECURE_PROCESSING, true);
        factory.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
        var manifest = factory.newDocumentBuilder().parse(new ByteArrayInputStream(manifestBytes));
        var applications = manifest.getElementsByTagNameNS("http://www.garmin.com/xml/connectiq", "application");
        if (applications.getLength() != 1) throw new IllegalStateException("Expected one app in the package.");
        var app = (org.w3c.dom.Element) applications.item(0);
        if (!app.getAttribute("id").equalsIgnoreCase("a5b8657e9da44c87b9b0177f94c368a1")) {
            throw new IllegalStateException("Application ID changed unexpectedly.");
        }
        var products = manifest.getElementsByTagNameNS("http://www.garmin.com/xml/connectiq", "product");
        if (products.getLength() != 4) throw new IllegalStateException("Expected exactly four product binaries.");
        for (int i = 0; i < products.getLength(); i++) {
            var product = (org.w3c.dom.Element) products.item(i);
            String device = deviceByPart.get(product.getAttribute("partNumber"));
            if (device == null) throw new IllegalStateException("Unknown product part number.");
            devices.add(device);
            if (!product.getAttribute("sigFormat").equals("rsa-4096") || product.getAttribute("sig").isEmpty()) {
                throw new IllegalStateException("Missing RSA 4096 signature metadata: " + device);
            }
            if (!names.contains(product.getAttribute("filename"))) throw new IllegalStateException("Product binary missing: " + device);
            System.out.println("Verified " + device + " / " + product.getAttribute("partNumber")
                + " / minimum firmware " + product.getAttribute("minFirmwareVersion"));
        }
        if (!devices.equals(expected)) throw new IllegalStateException("Unexpected device matrix: " + devices);
        System.out.println("App ID, manifest, four binaries, and RSA 4096 signature metadata verified; no private keys or tool files included.");
    }
}
