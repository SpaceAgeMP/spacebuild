function CAF.NotifyOwner(ent, msg)
    -- TODO: Replace with net msg, this is unsafe!
    msg = msg:Replace("'", "\\'")
    ent:GetOwner():SendLua("GAMEMODE:AddNotify('" .. msg .. "', NOTIFY_GENERIC, 7);")
end