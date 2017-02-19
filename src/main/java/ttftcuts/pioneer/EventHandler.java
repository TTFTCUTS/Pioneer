package ttftcuts.pioneer;

import net.minecraft.client.Minecraft;
import net.minecraft.client.gui.FontRenderer;
import net.minecraft.client.gui.ScaledResolution;
import net.minecraft.client.renderer.GlStateManager;
import net.minecraft.client.resources.I18n;
import net.minecraft.util.ResourceLocation;
import net.minecraftforge.client.event.RenderGameOverlayEvent;
import net.minecraftforge.fml.client.config.GuiUtils;
import net.minecraftforge.fml.common.eventhandler.SubscribeEvent;
import net.minecraftforge.fml.common.gameevent.TickEvent;
import ttftcuts.pioneer.map.MapJob;

public class EventHandler {

    public static final ResourceLocation workingTexture = new ResourceLocation(Pioneer.MODID, "textures/gui/working.png");

    @SubscribeEvent
    public void onServerTick(TickEvent.ServerTickEvent event) {
        if (Pioneer.currentJob != null) {
            Pioneer.currentJob.process();
        }
    }

    @SubscribeEvent
    public void onGameOverlay(RenderGameOverlayEvent event) {
        if (event.getType() != RenderGameOverlayEvent.ElementType.TEXT) {
            return;
        }

        if (Pioneer.currentJob == null) {
            return;
        }

        MapJob job = Pioneer.currentJob;

        Minecraft mc = Minecraft.getMinecraft();

        mc.getTextureManager().bindTexture(workingTexture);
        GlStateManager.resetColor();

        int frame = (int)(Minecraft.getSystemTime() / 500) % 4;
        int offset = 32 * frame;

        GuiUtils.drawTexturedModalRect(5,5,offset,0,32,32,1.0f);

        FontRenderer font = mc.fontRendererObj;
        String text = job.getCompletionPercent(true) + "%";

        font.drawString(text, 5 + 16 - font.getStringWidth(text)/2, 39, 0xFFFFFF, true);

        if (mc.isGamePaused()) {
            text = I18n.format("commands.pioneer.paused");
            font.drawString(text, 5 + 16 - font.getStringWidth(text)/2, 49, 0xFF3333, true);
        }
    }
}
