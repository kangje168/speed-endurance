import java.awt.*;
import java.awt.image.BufferedImage;
import java.nio.file.*;
import javax.imageio.ImageIO;

/** Illustrations based on PaceView; these are not device screenshots. */
class GenerateUiPreviews {
    static void line(Graphics2D g, int y, String s, int size, Color c) {
        g.setFont(new Font("SansSerif", Font.BOLD, size));
        g.setColor(c);
        g.drawString(s, 250-g.getFontMetrics().stringWidth(s)/2, y);
    }
    public static void main(String[] args) throws Exception {
        Path dir=Path.of("release/assets/ui-previews"); Files.createDirectories(dir);
        String[][] screens={
            {"select","SELECT PACE","Target 5:30/km","5:30","GPS: waiting","Best --:--","START: run"},
            {"running","RUNNING","Target 5:30/km","8:42","Slow 23/60s","Best 12:15","START: stop"},
            {"rest","REST","Target 5:30/km","1:25","Last 9:19","Best 12:15","START: run"},
            {"history","HISTORY","5:30 /km","Run 9:19","Rest 1:25","1/3",""}
        };
        for (String[] s:screens) {
            BufferedImage im=new BufferedImage(500,560,BufferedImage.TYPE_INT_RGB);
            Graphics2D g=im.createGraphics();
            g.setRenderingHint(RenderingHints.KEY_ANTIALIASING,RenderingHints.VALUE_ANTIALIAS_ON);
            g.setColor(new Color(24,29,27)); g.fillRect(0,0,500,560);
            g.setColor(Color.BLACK); g.fillOval(20,20,460,460);
            Color green=new Color(0x00ff55), gray=new Color(0xbbbbbb);
            if (s[0].equals("history")) {
                line(g,98,s[1],27,green); line(g,169,s[2],35,Color.WHITE);
                line(g,247,s[3],29,Color.WHITE); line(g,312,s[4],29,Color.WHITE);
                line(g,381,s[5],23,gray);
            } else {
                line(g,89,s[1],27,green); line(g,151,s[2],27,Color.WHITE);
                line(g,235,s[3],58,Color.WHITE); line(g,310,s[4],27,Color.YELLOW);
                line(g,369,s[5],23,gray); line(g,419,s[6],23,Color.WHITE);
            }
            line(g,524,"UI preview - illustrative data",20,gray);
            g.dispose();
            Path out=dir.resolve(s[0]+"-preview.png"); ImageIO.write(im,"png",out.toFile());
            long bytes=Files.size(out); if(bytes>=150000) throw new Exception("Image too large");
            System.out.println(out+" (500 x 560, "+bytes+" bytes)");
        }
    }
}
