package ttftcuts.pioneer;

import net.minecraft.command.CommandBase;
import net.minecraft.command.CommandException;
import net.minecraft.command.ICommandSender;
import net.minecraft.server.MinecraftServer;
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
            Pioneer.currentJob = new MapJob(sender.getEntityWorld(), 0,0,200,1);
        } else {
            // say no
        }
    }
}
