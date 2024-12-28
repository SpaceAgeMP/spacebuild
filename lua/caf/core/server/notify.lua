-- These are no longer defined on the server, so define them ourselves...
NOTIFY_GENERIC = 0
NOTIFY_ERROR = 1
NOTIFY_UNDO = 2
NOTIFY_HINT = 3
NOTIFY_CLEANUP = 4

local PLY = FindMetaTable("Player")
util.AddNetworkString("Player_AddHint")
function PLY:AddHint(txt, typ, len)
    if not txt then
        error("No text specified for hint")
        return
    end

    net.Start("Player_AddHint")
        net.WriteString(txt)
        net.WriteInt(typ or NOTIFY_GENERIC, 8)
        net.WriteInt(len or 5, 8)
    net.Send(self)
end

function CAF.NotifyOwner(ent, msg)
    ent:GetOwner():AddHint(msg, NOTIFY_GENERIC, 7)
end
