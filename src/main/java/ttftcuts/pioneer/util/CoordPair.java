package ttftcuts.pioneer.util;

public class CoordPair {
    public final int x;
    public final int z;

    public CoordPair(int x, int z) {
        this.x = x;
        this.z = z;
    }

    @Override
    public int hashCode() {
        int hash = 31;
        hash = ((hash + x) << 13) - (hash + x);
        hash = ((hash + z) << 13) - (hash + z);
        return hash;
    }

    @Override
    public boolean equals(Object other) {
        if (other instanceof CoordPair) {
            CoordPair o = (CoordPair) other;
            if (this.x == o.x && this.z == o.z) {
                return true;
            }
        }
        return false;
    }
}