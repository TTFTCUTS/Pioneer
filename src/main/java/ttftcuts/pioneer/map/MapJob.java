package ttftcuts.pioneer.map;

import com.google.gson.JsonObject;
import net.minecraft.client.Minecraft;
import net.minecraft.client.renderer.block.model.BakedQuad;
import net.minecraft.client.renderer.block.model.IBakedModel;
import net.minecraft.util.EnumFacing;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.text.TextComponentTranslation;
import net.minecraft.world.World;
import net.minecraft.world.biome.Biome;
import net.minecraft.world.biome.BiomeProvider;
import net.minecraftforge.common.DimensionManager;
import ttftcuts.pioneer.Pioneer;
import ttftcuts.pioneer.util.CoordPair;

import java.io.File;
import java.io.FileOutputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.zip.ZipEntry;
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

        this.filename = this.world.getWorldInfo().getWorldName() +"_"+ LocalDateTime.now().format(DATE_FORMAT) + ".pioneer"; //.zip

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

            this.buildJsons(x,z,radius,skip,tilerange);

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

    public void buildJsons(int x, int z, int radius, int skip, int tilerange) throws IOException {

        JsonObject mapinfo = new JsonObject();
        mapinfo.addProperty("worldname", this.world.getWorldInfo().getWorldName());
        mapinfo.addProperty("dimension", this.world.provider.getDimension()+"");
        mapinfo.addProperty("dimensiontype", this.world.provider.getDimensionType().getName());
        mapinfo.addProperty("seed", this.world.getWorldInfo().getSeed()+"");

        JsonObject generator = new JsonObject();
        generator.addProperty("name", this.world.getWorldType().getWorldTypeName());
        generator.addProperty("version", this.world.getWorldType().getGeneratorVersion());
        generator.addProperty("options", this.world.getWorldInfo().getGeneratorOptions());
        mapinfo.add("generator", generator);

        mapinfo.addProperty("x", x);
        mapinfo.addProperty("z", z);
        mapinfo.addProperty("radius", radius);
        mapinfo.addProperty("skip", skip);
        mapinfo.addProperty("jobsize", jobsize);
        mapinfo.addProperty("tilerange", tilerange);

        this.zip.putNextEntry(new ZipEntry("map.json"));
        byte[] bytes = mapinfo.toString().getBytes();
        this.zip.write(bytes, 0, bytes.length);
        this.zip.closeEntry();

        JsonObject biomes = new JsonObject();

        for (int i=0; i<256; i++) {
            Biome biome = Biome.getBiome(i);
            if (biome == null) { continue; }

            JsonObject bson = new JsonObject();

            bson.addProperty("name", biome.getBiomeName());
            bson.addProperty("temperature", biome.getTemperature());
            bson.addProperty("moisture", biome.getRainfall());
            bson.addProperty("snow", biome.isSnowyBiome());
            bson.addProperty("rain", biome.canRain());
            bson.addProperty("height", biome.getBaseHeight());
            bson.addProperty("heightvariation", biome.getHeightVariation());
            bson.addProperty("ismutation", biome.isMutation());

            if (biome.isMutation()) {
                bson.addProperty("mutationof", Biome.MUTATION_TO_BASE_ID_MAP.get(biome));
            }

            bson.addProperty("colour", "#" + Integer.toHexString(Pioneer.mapColours.getBiomeMapColour(biome)).substring(2));

            biomes.add(i+"", bson);
        }

        this.zip.putNextEntry(new ZipEntry("biomes.json"));
        bytes = biomes.toString().getBytes();
        this.zip.write(bytes, 0, bytes.length);
        this.zip.closeEntry();
    }


}
