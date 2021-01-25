local PLY = FindMetaTable("Player")
util.AddNetworkString("Player_AddHint")
function PLY:AddHint(txt, typ, len)
    net.Start("Player_AddHint")
        net.WriteString(txt)
        net.WriteInt(typ, 32)
        net.WriteInt(len, 32)
    net.Send(self)
end

function CAF.NotifyOwner(ent, msg)
    ent:GetOwner():AddHint(msg, NOTIFY_GENERIC, 7)
end
