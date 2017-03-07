package ttftcuts.pioneer.map;

import net.minecraft.block.state.IBlockState;
import net.minecraft.client.Minecraft;
import net.minecraft.client.renderer.*;
import net.minecraft.client.renderer.block.model.BakedQuad;
import net.minecraft.client.renderer.block.model.IBakedModel;
import net.minecraft.client.renderer.color.BlockColors;
import net.minecraft.client.renderer.texture.TextureAtlasSprite;
import net.minecraft.client.renderer.texture.TextureMap;
import net.minecraft.client.renderer.vertex.DefaultVertexFormats;
import net.minecraft.client.shader.Framebuffer;
import net.minecraft.init.Blocks;
import net.minecraft.util.EnumFacing;
import net.minecraft.util.math.BlockPos;
import net.minecraft.world.World;
import net.minecraft.world.biome.Biome;
import net.minecraft.world.chunk.ChunkPrimer;
import net.minecraft.world.gen.NoiseGeneratorPerlin;
import net.minecraftforge.common.BiomeDictionary;
import net.minecraftforge.fml.relauncher.ReflectionHelper;
import org.lwjgl.opengl.GL11;
import ttftcuts.pioneer.Pioneer;
import ttftcuts.pioneer.util.DummyChunkPrimer;
import ttftcuts.pioneer.util.ReflectionUtil;

import java.lang.reflect.Method;
import java.nio.ByteBuffer;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Random;

public class MapColours {
    public static MapColours instance;
    public static final int SAMPLE_RADIUS = 40;

    public Map<IBlockState, Integer> blockColours = new HashMap<IBlockState, Integer>();
    public Map<Biome, Integer> biomeColours = new HashMap<Biome, Integer>();

    public Random rand = new Random(50);
    public NoiseGeneratorPerlin groundNoise = new NoiseGeneratorPerlin(this.rand, 4);
    public ChunkPrimer dummyPrimer = new DummyChunkPrimer();

    public static final String[] topBlockMethod = new String[] {"a", "func_180622_a", "genTerrainBlocks"};
    public static final Class[] topBlockArgs = new Class[] {World.class, Random.class, ChunkPrimer.class, int.class, int.class, double.class};
    public static final String[] grassColourMethod = new String[] {"b", "func_180627_b", "getGrassColorAtPos"};
    public static final Class[] grassColourArgs = new Class[] {BlockPos.class};

    public MapColours() {}

    public int getBiomeMapColour(Biome biome) {
        if (biomeColours.containsKey(biome)) {
            return biomeColours.get(biome);
        }

        int colour = getBiomeMapColourRaw(biome);
        biomeColours.put(biome, colour);
        return colour;
    }

    public int getBiomeMapColourRaw(Biome biome) {

        boolean treebased = false;
        int colour = this.getTopColour(biome);

        if (BiomeDictionary.isBiomeOfType(biome, BiomeDictionary.Type.FOREST)) {
            colour = blend(biome.getFoliageColorAtPos(BlockPos.ORIGIN), 0xff0b7000, 0.35);
            treebased = true;
        }

        /*if (biome.theBiomeDecorator.treesPerChunk > 5) {
            colour = blend(colour, 0xff0b7000, 0.25);
            colour = brightness(colour, 0.9);
            treebased = true;
        }*/

        int trees = biome.theBiomeDecorator.treesPerChunk;
        if (trees > 0) {
            colour = blend(colour, 0xff0b7000, Math.min(0.25, trees * 0.025));
            colour = brightness(colour, 1.0 - Math.min(0.1, trees * 0.015));
            if (trees >= 4) {
                treebased = true;
            }
        }

        if (BiomeDictionary.isBiomeOfType(biome, BiomeDictionary.Type.RIVER)
                || BiomeDictionary.isBiomeOfType(biome, BiomeDictionary.Type.OCEAN)) {
            colour = blend(colour, 0xff4582ff, 0.7); // sea blue
        }

        if (biome.getBaseHeight() > 0.0) {
            double mod = Math.min(biome.getBaseHeight() * 0.2 + 1.0, 1.35);
            colour = brightness(colour, mod);
        } else if (biome.getBaseHeight() <= -1.2) {
            colour = brightness(colour, 0.9);
        }

        if (treebased) {
            colour = temptint(colour, biome.getTemperature());
        }

        if (biome.isSnowyBiome()) {
            colour = blend(colour, 0xffffffff, 0.5); // icy pale cyan
            //colour = blend(colour, 0xffc9e4ff, 0.25);
            colour = brightness(colour, 1.2);
        }

        return colour | 0xFF000000;
    }

    public int getTopColour(Biome biome) {

        BlockPos.MutableBlockPos pos = new BlockPos.MutableBlockPos(0,64,0);

        boolean topOverridden = false;
        boolean grassOverridden = false;

        try {
            Method top = ReflectionUtil.<Biome>findMethod(biome, topBlockMethod, topBlockArgs);
            topOverridden = top.getDeclaringClass() != Biome.class;

            Method grass = ReflectionUtil.<Biome>findMethod(biome, grassColourMethod, grassColourArgs);
            grassOverridden = grass.getDeclaringClass() != Biome.class;

            //Pioneer.logger.info(biome.getClass()+" declaring class of block method: "+ top.getDeclaringClass() +", grass method: "+grass.getDeclaringClass());
        } catch (Exception e) {
            e.printStackTrace();
        }

        if (topOverridden || grassOverridden) {
            //Pioneer.logger.info(biome.getBiomeName() +" overrides:  top block: "+topOverridden+", grass colour: "+grassOverridden);

            int rad = SAMPLE_RADIUS;
            int size = (rad*2+1);
            int divisor = size*size;

            int r = 0;
            int g = 0;
            int b = 0;

            double[] noise = new double[divisor];
            if (topOverridden) {
                this.rand.setSeed(100);
                noise = this.groundNoise.getRegion(noise, (double)-rad, (double)-rad, size, size, 0.0625D, 0.0625D, 1.0D);
            }

            for (int x = -rad; x<= rad; x++) {
                for (int z = -rad; z<= rad; z++) {
                    pos.setPos(x,64,z);
                    if (topOverridden) {
                        int noiseindex = (z+rad) * size + (x+rad);

                        biome.genTerrainBlocks(Minecraft.getMinecraft().theWorld, this.rand, dummyPrimer, x, z, noise[noiseindex]);
                    }

                    int col = this.getBiomeBlockColourForCoords(biome, pos);

                    r += (col & 0x00FF0000) >> 16;
                    g += (col & 0x0000FF00) >> 8;
                    b += (col & 0x000000FF);
                }
            }

            r /= divisor;
            g /= divisor;
            b /= divisor;

            return (r << 16) | (g << 8) | (b) | 0xFF000000;
        } else {
            return this.getBiomeBlockColourForCoords(biome, pos);
        }
    }

    public int getBiomeBlockColourForCoords(Biome biome, BlockPos pos) {
        int colour;

        if (biome.topBlock == Blocks.GRASS.getDefaultState()) { // uuuugh
            colour = biome.topBlock.getMapColor().colorValue | 0xFF000000;
            int tint = biome.getGrassColorAtPos(pos) | 0xFF000000;
            colour = blend(colour,tint, 0.75);
        } else {
            colour = this.getBlockColourRaw(biome.topBlock);
        }

        return colour;
    }

    /*public int getBlockColour(IBlockState block) {
        if (blockColours.containsKey(block)) {
            return blockColours.get(block);
        }

        int colour = this.getBlockColourRaw(block);
        blockColours.put(block, colour);
        return colour;
    }*/

    public int getBlockColourRaw(IBlockState block) {
        Minecraft mc = Minecraft.getMinecraft();
        BlockRendererDispatcher brd = mc.getBlockRendererDispatcher();
        BlockModelShapes shapes = brd.getBlockModelShapes();
        BlockColors colours = mc.getBlockColors();

        int colour = block.getMapColor().colorValue | 0xFF000000;
        int fallback = colour;

        if (block == Blocks.GRASS.getDefaultState()) {
            // ugh
        } else {

            try {
                IBakedModel topmodel = shapes.getModelForState(block);
                List<BakedQuad> topquads = topmodel.getQuads(block, EnumFacing.UP, 0);

                for (BakedQuad quad : topquads) {
                    colour = block.getMapColor().colorValue | 0xFF000000;
                    if (quad.hasTintIndex()) {
                        int tint = colours.colorMultiplier(block, null, null, quad.getTintIndex()) | 0xFF000000;
                        //colour = intAverage(colour, tint);
                        //colour = intAverage(colour, tint);
                        //colour = intAverage(colour, tint);

                        colour = blend(colour, tint, 0.75);
                    }
                }

            } catch (Exception e) {
                e.printStackTrace();
                colour = fallback;
            }
        }

        return colour;
    }

    public static void drawTexturedRect(int x, int y, float u1, float v1, float u2, float v2, int width, int height, float zLevel)
    {
        Tessellator tessellator = Tessellator.getInstance();
        VertexBuffer wr = tessellator.getBuffer();
        wr.begin(7, DefaultVertexFormats.POSITION_TEX);
        wr.pos(x        , y + height, zLevel).tex( u1, v2 ).endVertex();
        wr.pos(x + width, y + height, zLevel).tex( u2, v2 ).endVertex();
        wr.pos(x + width, y         , zLevel).tex( u2, v1 ).endVertex();
        wr.pos(x        , y         , zLevel).tex( u1, v1 ).endVertex();
        tessellator.draw();
    }

    public static int intAverage(int a, int b) {
        return (int)( ((((a) ^ (b)) & 0xfffefefeL) >> 1) + ((a) & (b)) );
    }

    public static int blend(int a, int b, double mix) {
        if (mix == 0) {
            return a;
        } else if (mix == 1) {
            return b;
        } else if (mix == 0.5) {
            return intAverage(a,b);
        }

        int ar = (a & 0x00FF0000) >> 16;
        int ag = (a & 0x0000FF00) >> 8;
        int ab = (a & 0x000000FF);

        int br = (b & 0x00FF0000) >> 16;
        int bg = (b & 0x0000FF00) >> 8;
        int bb = (b & 0x000000FF);

        int mr = (int)Math.min(255,Math.max(0,Math.floor(ar * (1.0-mix) + br * mix)));
        int mg = (int)Math.min(255,Math.max(0,Math.floor(ag * (1.0-mix) + bg * mix)));
        int mb = (int)Math.min(255,Math.max(0,Math.floor(ab * (1.0-mix) + bb * mix)));

        return (mr << 16) | (mg << 8) | (mb) | 0xFF000000;
    }

    public static int brightness(int col, double light) {
        int r = (col & 0x00FF0000) >> 16;
        int g = (col & 0x0000FF00) >> 8;
        int b = (col & 0x000000FF);

        r = (int)Math.min(255,Math.floor(r * light));
        g = (int)Math.min(255,Math.floor(g * light));
        b = (int)Math.min(255,Math.floor(b * light));

        return (r << 16) | (g << 8) | (b) | 0xFF000000;
    }

    public static int temptint(int col, double temp) {
        int r = (col & 0x00FF0000) >> 16;
        int g = (col & 0x0000FF00) >> 8;
        int b = (col & 0x000000FF);

        double limit = 0.25;
        double factor = Math.max(-limit, Math.min(limit, (temp - 0.4) * 0.75));

        r = (int)Math.min(255,Math.floor(r * (1+factor)));
        g = (int)Math.min(255,Math.floor(g * (1+factor * 0.5)));
        b = (int)Math.min(255,Math.floor(b * (1-factor * 2.5)));

        return (r << 16) | (g << 8) | (b) | 0xFF000000;
    }
}
