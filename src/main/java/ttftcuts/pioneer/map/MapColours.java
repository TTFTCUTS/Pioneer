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
import net.minecraft.world.biome.Biome;
import net.minecraftforge.common.BiomeDictionary;
import org.lwjgl.opengl.GL11;
import ttftcuts.pioneer.Pioneer;

import java.nio.ByteBuffer;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class MapColours {
    public static MapColours instance;
    public static void init() {
        instance = new MapColours();
    }

    public Map<IBlockState, Integer> blockColours = new HashMap<IBlockState, Integer>();
    public Map<Biome, Integer> biomeColours = new HashMap<Biome, Integer>();
    public Framebuffer framebuffer;

    public MapColours() {
        //this.framebuffer = new Framebuffer(16,16,false);
        //this.framebuffer.unbindFramebuffer();
    }

    public int getBiomeMapColour(Biome biome) {
        /*if (biomeColours.containsKey(biome)) {
            return biomeColours.get(biome);
        }*/

        int colour = getBiomeMapColourRaw(biome);
        biomeColours.put(biome, colour);
        return colour;
    }

    public int getBiomeMapColourRaw(Biome biome) {

        int colour = this.getBlockColourRaw(biome.topBlock);

        if (biome.topBlock == Blocks.GRASS.getDefaultState()) { // uuuugh
            int tint = biome.getGrassColorAtPos(BlockPos.ORIGIN) | 0xFF000000;
            colour = blend(colour,tint, 0.75);
        }

        if (BiomeDictionary.isBiomeOfType(biome, BiomeDictionary.Type.FOREST)) {
            colour = blend(biome.getFoliageColorAtPos(BlockPos.ORIGIN), 0xff0b7000, 0.35);
        }

        if (biome.theBiomeDecorator.treesPerChunk > 5) {
            colour = blend(colour, 0xff0b7000, 0.25);
            colour = brightness(colour, 0.9);
        }

        if (BiomeDictionary.isBiomeOfType(biome, BiomeDictionary.Type.RIVER)
                || BiomeDictionary.isBiomeOfType(biome, BiomeDictionary.Type.OCEAN)) {
            colour = blend(colour, 0xff4582ff, 0.7); // sea blue
        }

        if (biome.isSnowyBiome()) {
            colour = intAverage(colour, 0xffeffdff); // icy pale cyan
            colour = intAverage(colour, 0xffc9e4ff);
        }

        if (biome.getBaseHeight() > 0.0) {
            double mod = Math.min(biome.getBaseHeight() * 0.2 + 1.0, 1.35);
            colour = brightness(colour, mod);
        }

        return colour | 0xFF000000;
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
}
