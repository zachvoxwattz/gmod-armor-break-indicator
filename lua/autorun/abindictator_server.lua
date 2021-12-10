if CLIENT then return end

AddCSLuaFile('autorun/abindictator_client_target.lua')
AddCSLuaFile('autorun/abindictator_client_player.lua')
resource.AddSingleFile('sound/target/break_cod.ogg')
resource.AddSingleFile('sound/target/break_mc.ogg')
resource.AddSingleFile('sound/target/break_apex.ogg')
resource.AddSingleFile('sound/target/break_fortnite.ogg')
resource.AddSingleFile('sound/target/break_bdrls.ogg')

resource.AddSingleFile('sound/player/break_apex.ogg')
resource.AddSingleFile('sound/player/break_bdrls.ogg')
resource.AddSingleFile('sound/player/break_cod.ogg')
resource.AddSingleFile('sound/player/break_dv2.ogg')
resource.AddSingleFile('sound/player/break_fortnite.ogg')
resource.AddSingleFile('sound/player/break_mc.ogg')

resource.AddSingleFile('materials/icon_cod.png')
resource.AddSingleFile('materials/icon_mc.png')
resource.AddSingleFile('materials/icon_apex.png')
resource.AddSingleFile('materials/icon_bdrls.png')
resource.AddSingleFile('materials/icon_fortnite.png')

local targetArmorAfter = 0
local targetArmorBefore = 0
local targetIsAlive = true
local attacker = nil

util.AddNetworkString('ab_broken')
util.AddNetworkString('ab_cracked')

local function crack(victim)
    net.Start('ab_cracked')
    net.Send(victim)
end

local function inform(killer)
    net.Start('ab_broken')
    net.Send(killer)
end

hook.Add('EntityTakeDamage', 'abi', function(target, dmginfo)

    attacker = dmginfo:GetAttacker()

    if not attacker:IsPlayer() and target:IsPlayer() and target:GetInfo('abindicator_player_enable') == '1' then
        targetArmorBefore = target:Armor()
    end

    if attacker:IsPlayer() and target:IsPlayer() and attacker:GetInfo('abindicator_target_enable') == '1' then
        targetArmorBefore = target:Armor()
        targetIsAlive = target:Alive()
    else return end
end)

hook.Add('PostEntityTakeDamage', 'abi', function(target, dmginfo, dmgTaken)

    attacker = dmginfo:GetAttacker()

    if not attacker:IsPlayer() and target:IsPlayer() and target:GetInfo('abindicator_player_enable') == '1' then
        targetArmorAfter = target:Armor()

        if targetArmorAfter == 0 and targetArmorBefore != 0 then crack(target) end
    end

    if attacker:IsPlayer() and target:IsPlayer() and attacker:GetInfo('abindicator_target_enable') == '1' then
        targetArmorAfter = target:Armor()
        targetIsAlive = target:Alive()

        if not targetIsAlive then
            if targetArmorBefore != 0 then 
                crack(target)
                inform(attacker)
            end
        return end

        if targetIsAlive and targetArmorAfter == 0 and targetArmorBefore != 0 then
            crack(target)
            inform(attacker)
            return end
    else return end
end )