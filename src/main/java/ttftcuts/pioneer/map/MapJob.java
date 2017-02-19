package ttftcuts.pioneer.map;

import net.minecraft.client.Minecraft;
import net.minecraft.util.text.TextComponentTranslation;
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
    public static final DateTimeFormatter DATE_FORMAT = DateTimeFormatter.ofPattern("yyyy-MM-dd_HHmmss");

    protected Queue<MapTile> tileQueue;

    public final World world;
    public final BiomeProvider provider;
    public final String filename;

    protected File file;
    protected ZipOutputStream zip;

    public int jobsize = 0;
    protected long startTime;

    public MapJob(World world, int x, int z, int radius, int skip) {
        this.world = world;
        this.provider = world.getBiomeProvider();

        this.tileQueue = new LinkedList<MapTile>();

        int tilerange = (int)Math.ceil(((radius*2) / (double)skip) / (double)Pioneer.TILE_SIZE);

        int tileworldsize = Pioneer.TILE_SIZE * skip;
        int offset = (int)Math.floor(tileworldsize * (tilerange / 2.0));
        this.jobsize = tilerange * tilerange;

        this.filename = this.world.getWorldInfo().getWorldName() +"_"+ LocalDateTime.now().format(DATE_FORMAT) + ".zip"; //.pioneer

        Pioneer.logger.info("Pioneer: new mapping job: "+radius+" radius, "+x+","+z+" at scale "+skip+". "+this.jobsize+" tiles");

        for (int ix = 0; ix<tilerange; ix++) {
            for (int iz = 0; iz<tilerange; iz++) {

                MapTile t = new MapTile(ix+"_"+iz, x + tileworldsize * ix - offset, z + tileworldsize * iz - offset, skip);
                this.tileQueue.add(t);
            }
        }

        try {
            if (!Pioneer.SAVE_PATH.exists()) {
                Pioneer.SAVE_PATH.mkdir();
            }

            this.file = new File(Pioneer.SAVE_PATH, this.filename);
            this.zip = new ZipOutputStream(new FileOutputStream(this.file));

        } catch (Exception e) {
            e.printStackTrace();
            this.endJob(true);
        }

        this.startTime = new Date().getTime();
        Minecraft.getMinecraft().thePlayer.addChatMessage(new TextComponentTranslation("commands.pioneer.start", this.jobsize));
    }

    public void process() {
        Pioneer.logger.info("Pioneer: "+ this.filename +": "+ this.getCompletionPercent(false) +"%");
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
        } else {
            long time = (new Date().getTime() - this.startTime) / 1000;

            Minecraft.getMinecraft().thePlayer.addChatMessage(new TextComponentTranslation("commands.pioneer.finish", this.jobsize, time));
        }
    }

    public double getCompletion(boolean offset) {
        return ((this.jobsize - this.tileQueue.size()) - (offset? 1 : 0)) / (double)this.jobsize;
    }

    public int getCompletionPercent(boolean offset) {
        return (int)Math.round(this.getCompletion(offset) * 100);
    }
}
