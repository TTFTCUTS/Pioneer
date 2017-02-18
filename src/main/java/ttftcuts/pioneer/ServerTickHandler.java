package ttftcuts.pioneer;

import net.minecraftforge.fml.common.eventhandler.SubscribeEvent;
import net.minecraftforge.fml.common.gameevent.TickEvent;

public class ServerTickHandler {

    @SubscribeEvent
    public void onServerTick(TickEvent.ServerTickEvent event) {
        if (Pioneer.currentJob != null) {
            Pioneer.currentJob.process();
        }
    }
}
