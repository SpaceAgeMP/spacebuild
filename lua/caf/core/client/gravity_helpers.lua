hook.Add("SetupMove", "SB_SetupMove_Gravity", function(ply)
    local gravity = ply:GetNWFloat("gravity")
    if gravity == 0 then
        gravity = 0.00001
    end
    ply:SetGravity(gravity)
end)
