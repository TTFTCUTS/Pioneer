package ttftcuts.pioneer;

import net.minecraft.client.Minecraft;
import net.minecraft.init.Blocks;
import net.minecraftforge.common.MinecraftForge;
import net.minecraftforge.fml.common.Mod;
import net.minecraftforge.fml.common.event.FMLInitializationEvent;
import net.minecraftforge.fml.common.event.FMLPostInitializationEvent;
import net.minecraftforge.fml.common.event.FMLPreInitializationEvent;
import net.minecraftforge.fml.common.event.FMLServerStartingEvent;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import ttftcuts.pioneer.map.MapColours;
import ttftcuts.pioneer.map.MapJob;

import java.io.File;

@Mod(modid = Pioneer.MODID, version = Pioneer.VERSION, clientSideOnly = true)
public class Pioneer
{
    public static final String MODID = "pioneer";
    public static final String VERSION = "2.0.0";

    public static final int TILE_SIZE = 128;
    public static File SAVE_PATH;

    public static final Logger logger = LogManager.getLogger(MODID);

    public static MapJob currentJob = null;
    public static MapColours mapColours;

    @Mod.Instance(MODID)
    public static Pioneer instance;

    @Mod.EventHandler
    public void preInit(FMLPreInitializationEvent event)
    {
        SAVE_PATH = new File(Minecraft.getMinecraft().mcDataDir, "pioneer");
    }

    @Mod.EventHandler
    public void init(FMLInitializationEvent event)
    {

    }

    @Mod.EventHandler
    public void postInit(FMLPostInitializationEvent event) {
        MinecraftForge.EVENT_BUS.register(new EventHandler());
        mapColours = new MapColours();
    }

    @Mod.EventHandler
    public void serverStarting(FMLServerStartingEvent event) {
        event.registerServerCommand(new CommandPioneer());
    }
}
