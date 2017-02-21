package ttftcuts.pioneer;

import net.minecraft.client.Minecraft;
import net.minecraft.command.CommandBase;
import net.minecraft.command.CommandException;
import net.minecraft.command.ICommandSender;
import net.minecraft.command.WrongUsageException;
import net.minecraft.init.Biomes;
import net.minecraft.init.Blocks;
import net.minecraft.server.MinecraftServer;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.math.MathHelper;
import ttftcuts.pioneer.map.MapJob;

public class CommandPioneer extends CommandBase {
    @Override
    public String getCommandName() {
        return "pioneer";
    }

    @Override
    public String getCommandUsage(ICommandSender sender) {
        return "commands.pioneer.usage";
    }

    @Override
    public void execute(MinecraftServer server, ICommandSender sender, String[] args) throws CommandException {
        if (Pioneer.currentJob == null) {
            if (!server.isSinglePlayer()) {
                throw new CommandException("commands.pioneer.singleplayeronly");
            }

            BlockPos pos;

            if (args.length == 1) {
                if (args[0].equals("stop")) {
                    throw new CommandException("commands.pioneer.nojob");
                } else {
                    // radius only
                    pos = sender.getPosition();
                    this.doCommand(sender, args[0], "1", pos.getX() + "", pos.getZ() + "");
                }
            } else if (args.length == 2) {
                // radius and scale
                pos = sender.getPosition();
                this.doCommand(sender, args[0], args[1], pos.getX()+"", pos.getZ()+"");
            } else if (args.length == 3) {
                // radius and coordinates
                pos = sender.getPosition();
                this.doCommand(sender, args[0], "1", args[1], args[2]);
            } else if (args.length == 4) {
                // radius, scale and coordinates
                pos = sender.getPosition();
                this.doCommand(sender, args[0], args[1], args[2], args[3]);
            } else {
                throw new WrongUsageException("commands.pioneer.usage");
            }

        } else {
            if (args.length == 1 && args[0].equals("stop")) {
                // cancel
                Pioneer.currentJob.endJob(true);
                notifyCommandListener(sender, this, "commands.pioneer.stop");
            } else {
                // say no
                notifyCommandListener(sender, this, "commands.pioneer.busy");
            }
        }
    }

    protected void doCommand(ICommandSender sender, String radius, String scale, String x, String z) throws CommandException {
        int iradius;
        int ix;
        int iz;
        int iscale;

        try {
            iradius = Integer.parseInt(radius);
            ix = Integer.parseInt(x);
            iz = Integer.parseInt(z);
            iscale = Integer.parseInt(scale);
        } catch (NumberFormatException e) {
            throw new CommandException("commands.pioneer.numbers");
        }

        if (iradius < 1 || iscale < 1) {
            throw new CommandException("commands.pioneer.positive");
        }

        Pioneer.currentJob = new MapJob(sender.getEntityWorld(), ix,iz,iradius,iscale);
    }
}
