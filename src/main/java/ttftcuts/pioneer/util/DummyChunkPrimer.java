package ttftcuts.pioneer.util;

import net.minecraft.block.state.IBlockState;
import net.minecraft.init.Blocks;
import net.minecraft.world.chunk.ChunkPrimer;

public class DummyChunkPrimer extends ChunkPrimer {
    @Override public IBlockState getBlockState(int x, int y, int z) {
        return Blocks.STONE.getDefaultState();
    }

    @Override public void setBlockState(int x, int y, int z, IBlockState state) {
        // noop
    }

    @Override public int findGroundBlockIdx(int x, int z) {
        return 64;
    }
}
