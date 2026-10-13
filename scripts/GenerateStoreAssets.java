import java.awt.Color;
import java.awt.RenderingHints;
import java.awt.geom.Path2D;
import java.awt.image.BufferedImage;
import java.nio.file.Files;
import java.nio.file.Path;
import javax.imageio.ImageIO;

/** Deterministic original icon artwork, consistent with the watch launcher SVG. */
class GenerateStoreAssets {
    public static void main(String[] args) throws Exception {
        Path directory = Path.of(args.length == 0 ? "release/assets" : args[0]);
        Files.createDirectories(directory);
        for (int size : new int[]{128, 500, 512}) {
            BufferedImage image = new BufferedImage(size, size, BufferedImage.TYPE_INT_ARGB);
            var g = image.createGraphics();
            g.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
            g.setColor(Color.BLACK);
            g.fillRoundRect(0, 0, size, size, size / 3, size / 3);
            g.scale(size / 40.0, size / 40.0);
            Path2D bolt = new Path2D.Double();
            bolt.moveTo(23, 5); bolt.lineTo(10, 23); bolt.lineTo(19, 23);
            bolt.lineTo(17, 35); bolt.lineTo(31, 15); bolt.lineTo(22, 15); bolt.closePath();
            g.setColor(new Color(0x00ff55));
            g.fill(bolt);
            g.dispose();
            Path output = directory.resolve("store-icon-" + size + ".png");
            ImageIO.write(image, "png", output.toFile());
            System.out.println("Created " + output);
        }
    }
}
