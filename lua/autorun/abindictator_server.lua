if CLIENT then return end

AddCSLuaFile('autorun/asbi_client.lua')
resource.AddFile('sound/break_cod.ogg')
resource.AddFile('sound/break_mc.ogg')
resource.AddFile('sound/break_apex.ogg')
resource.AddFile('materials/icon_cod.png')
resource.AddFile('materials/icon_mc.png')
resource.AddFile('materials/icon_apex.png')

local targetArmorPost = 0
local targetArmorPre = 0
local targetArmorBroken = false
local targetIsAlive = true
local attacker = nil

util.AddNetworkString('asbi_act')

hook.Add('EntityTakeDamage', 'asbi', function(target, dmginfo)

    attacker = dmginfo:GetAttacker()
    
    if not target:IsPlayer() then return end
    if not attacker:IsPlayer() then return end
    if attacker:GetInfo('asbindicator_enable') != "1" then return end

    targetArmorPre = target:Armor()

end)

hook.Add('PostEntityTakeDamage', 'asbi', function(target, dmginfo, dmgTaken)

    attacker = dmginfo:GetAttacker()
    
    if not target:IsPlayer() then return end
    if not attacker:IsPlayer() then return end
    if attacker:GetInfo('asbindicator_enable') != "1" then return end

    targetArmorPost = target:Armor()
    targetIsAlive = target:Alive()

    if not targetIsAlive then
        if targetArmorPre != 0 then
            net.Start('asbi_act')
            net.Send(attacker)
            targetArmorBroken = false
        return end
        targetArmorBroken = false
    end

    if targetArmorPost > 0 then
        targetArmorBroken = false
    end

    if targetIsAlive and targetArmorPost == 0 and targetArmorPre != 0 and not targetArmorBroken then
        net.Start('asbi_act')
        net.Send(attacker)
        targetArmorBroken = true
        return end
end )