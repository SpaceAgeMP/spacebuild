local ENT = FindMetaTable("Entity")

if not ENT.RealSetParent then
    ENT.RealSetParent = ENT.SetParent
end

function ENT:SetParent(other)
    if self:IsVehicle() then
        return
    end
    self:RealSetParent(other)
end
