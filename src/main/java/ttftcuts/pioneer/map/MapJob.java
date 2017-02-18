package ttftcuts.pioneer.map;

import net.minecraft.client.Minecraft;
import net.minecraft.world.World;
import net.minecraft.world.biome.BiomeProvider;
import net.minecraftforge.common.DimensionManager;
import ttftcuts.pioneer.Pioneer;
import ttftcuts.pioneer.util.CoordPair;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.zip.ZipOutputStream;

public class MapJob {
    public static final DateTimeFormatter DATE_FORMAT = DateTimeFormatter.ofPattern("yyyy-MM-dd_HH:mm:ss");

    protected Queue<MapTile> tileQueue;

    public final World world;
    public final BiomeProvider provider;

    protected File file;
    protected ZipOutputStream zip;

    public int jobsize = 0;

    public MapJob(World world, int x, int z, int radius, int skip) {
        this.world = world;
        this.provider = world.getBiomeProvider();

        this.tileQueue = new LinkedList<MapTile>();

        int tilerange = (int)Math.ceil(((radius*2) / skip) / Pioneer.TILE_SIZE);

        int tileworldsize = Pioneer.TILE_SIZE * skip;
        int offset = (int)Math.floor(tileworldsize * (tilerange / 2.0));
        this.jobsize = tilerange * tilerange;

        for (int ix = 0; ix<tilerange; ix++) {
            for (int iz = 0; iz<tilerange; iz++) {

                MapTile t = new MapTile(ix+"_"+iz, tileworldsize * ix - offset, tileworldsize * iz - offset, skip);
                this.tileQueue.add(t);
            }
        }

        try {
            if (!Pioneer.SAVE_PATH.exists()) {
                Pioneer.SAVE_PATH.mkdir();
            }

            String filename = this.world.getWorldInfo().getWorldName() +"_"+ LocalDateTime.now().format(DATE_FORMAT) + ".zip"; //.pioneer

            this.file = new File(Pioneer.SAVE_PATH, filename);
            this.zip = new ZipOutputStream(new FileOutputStream(this.file));

        } catch (Exception e) {
            e.printStackTrace();
            this.endJob(true);
        }
    }

    public void process() {
        Pioneer.logger.info("processing: "+this.getCompletionPercent()+"%");
        try {
            if (!this.tileQueue.isEmpty()) {
                MapTile t = this.tileQueue.poll();

                t.generate(this.provider);

                t.save(this.zip);
            } else {
                if (zip != null) {
                    zip.close();
                }
                this.endJob(false);
            }
        } catch (Exception e) {
            e.printStackTrace();
            this.endJob(true);
        }
    }


    public void endJob(boolean cancel) {
        if (Pioneer.currentJob == this) {
            Pioneer.currentJob = null;
        }
        if(cancel) {
            this.file.delete();
        }
    }

    public double getCompletion() {
        return (this.jobsize - this.tileQueue.size()) / (double)this.jobsize;
    }

    public int getCompletionPercent() {
        return (int)Math.round(this.getCompletion() * 100);
    }
}
