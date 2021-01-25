local PLY = FindMetaTable("Player")

function PLY:AddHint(txt, typ, len)
    notification.AddLegacy(txt, typ, len)
end

net.Receive("Player_AddHint", function()
    local txt = net.ReadString()
    local typ = net.ReadInt(32)
    local len = net.ReadInt(32)
    LocalPlayer():AddHint(txt, typ, len)
end)
