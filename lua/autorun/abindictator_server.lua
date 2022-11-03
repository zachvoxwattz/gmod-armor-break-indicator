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

local targetIsAlive = nil
local attacker = nil

util.AddNetworkString('ab_broken')
util.AddNetworkString('ab_broken_death')
util.AddNetworkString('ab_cracked')
util.AddNetworkString('ab_cracked_death')

local function crack(victim)
    if victim:GetInfo('abindicator_player_enable') == '1' then
        net.Start('ab_cracked')
        net.Send(victim)
    end
end

local function crackDeath(victim)
    if victim:GetInfo('abindicator_player_enable') == '1' then
        net.Start('ab_cracked_death')
        net.Send(victim)
    end
end

local function inform(killer)
    if killer:GetInfo('abindicator_target_enable') == '1' then
        net.Start('ab_broken')
        net.Send(killer)
    end
end

hook.Add('EntityTakeDamage', 'PlayerDamageListener', function(target, dmginfo)
    if not target:IsPlayer() then return end
    targetArmorBefore = target:Armor()
end)

hook.Add('PostEntityTakeDamage', 'PostPlayerDamageListener', function(target, dmginfo)
    if not target:IsPlayer() then return end

    attacker = dmginfo:GetAttacker()
    targetArmorAfter = target:Armor()
    targetIsAlive = target:Alive()

    if not attacker:IsPlayer() then
        if not targetIsAlive then
            if targetArmorBefore != 0 then
                crackDeath(target)
            return end
        return end

        if targetIsAlive then
            if targetArmorAfter == 0 and targetArmorBefore != 0 then
                crack(target)
            return end
        return end
    return end

    if attacker:IsPlayer() then
        if not targetIsAlive then
            if targetArmorBefore != 0 then 
                crackDeath(target)

                if attacker != target then
                    inform(attacker) 
                end
            return end
        return end

        if targetIsAlive then
            if targetArmorAfter == 0 and targetArmorBefore != 0 then
                crack(target)

                if attacker != target then
                    inform(attacker)
                end
            return end
        return end
    return end
end )