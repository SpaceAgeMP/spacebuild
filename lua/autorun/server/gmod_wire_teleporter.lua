hook.Add("InitPostEntity", "WireTeleporterPatch", function()
    list.Set("LSEntOverlayText", "gmod_wire_teleporter", {
        HasOOO = true,
        resnames = {"energy"}
    })

    local ENT = scripted_ents.GetStored("gmod_wire_teleporter").t
    local RD = CAF.GetAddon("Resource Distribution")
    
    ENT.RealJump = ENT.Jump
    ENT.RealJump_Part2 = ENT.Jump_Part2
    ENT.RealTriggerInput = ENT.TriggerInput

    function ENT:Jump(withangles)
        if (self.Jumping) then
            return
        end
        
        self:CalculateEnergy()

        if RD.GetResourceAmount(self, "energy") < self.EnergyRequired then
            self:EmitSound("buttons/button8.wav")
            return
        end

        self:RealJump(withangles)
    end

    function ENT:Jump_Part2(withangles)
        if RD.GetResourceAmount(self, "energy") < self.EnergyRequired then
            self:EmitSound("buttons/button8.wav")
            return
        else
            RD.ConsumeResource(self, "energy", self.EnergyRequired)
        end

        self:RealJump_Part2(withangles)
    end

    function ENT:CalculateEnergy()
        local distance = self:GetPos():Distance(self.TargetPos)

        local ents = constraint.GetAllConstrainedEntities( self )

        if next(ents,val) == nil and IsValid(self:GetParent()) then
            ents = constraint.GetAllConstrainedEntities( self:GetParent() )
        end

        self.EnergyRequired = math.ceil((distance * 4) * table.Count(ents))
    end
end)

hook.Add("OnEntityCreated", "WireTeleporterPatchRD", function(entity)
    if entity:GetClass() == "gmod_wire_teleporter" then
        CAF.GetAddon("Resource Distribution").RegisterNonStorageDevice(entity)
    end
end)