package ttftcuts.pioneer.map;

import net.minecraft.world.biome.Biome;
import net.minecraft.world.biome.BiomeProvider;
import ttftcuts.pioneer.Pioneer;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.awt.image.DataBuffer;
import java.awt.image.Raster;
import java.awt.image.WritableRaster;
import java.io.IOException;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

public class MapTile {
    public boolean generated = false;

    public final int worldX;
    public final int worldZ;
    public final int skip;
    public final String filename;

    BufferedImage biomeMap;

    public MapTile(String filename, int x, int z, int skip) {
        this.worldX = x;
        this.worldZ = z;
        this.skip = skip;
        this.filename = filename;
    }

    public void generate(BiomeProvider provider) {
        this.biomeMap = new BufferedImage(Pioneer.TILE_SIZE, Pioneer.TILE_SIZE, BufferedImage.TYPE_BYTE_GRAY);

        WritableRaster r = this.biomeMap.getRaster();
        DataBuffer data = r.getDataBuffer();
        int x, z, index;

        Biome[] biome = new Biome[1];

        for (x = 0; x<Pioneer.TILE_SIZE; x++) {
            for (z = 0; z<Pioneer.TILE_SIZE; z++) {
                index = z * Pioneer.TILE_SIZE + x;

                provider.loadBlockGeneratorData(biome, this.worldX + x * skip, this.worldZ + z * skip, 1,1);
                data.setElem(index, Biome.getIdForBiome(biome[0]));
            }
        }

        this.generated = true;
    }

    public void save(ZipOutputStream zip) throws IOException {
        ZipEntry entry = new ZipEntry("tiles/"+this.filename+".png");
        zip.putNextEntry(entry);

        ImageIO.write(this.biomeMap, "png", zip);

        zip.closeEntry();
    }
}
