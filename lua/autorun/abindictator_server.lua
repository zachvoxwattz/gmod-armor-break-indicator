if CLIENT then return end

AddCSLuaFile('autorun/abindictator_client_target.lua')
AddCSLuaFile('autorun/abindictator_client_player.lua')

local targetArmorAfter = 0
local targetArmorBefore = 0
local targetIsAlive = nil
local attacker = nil

util.AddNetworkString('ab_hit')
util.AddNetworkString('ab_broken')
util.AddNetworkString('ab_cracked')
util.AddNetworkString('ab_cracked_death')

local function crack(victim)
    net.Start('ab_cracked')
    net.Send(victim)
end

local function crackDeath(victim)
    net.Start('ab_cracked_death')
    net.Send(victim)
end

local function inform(killer)
    net.Start('ab_broken')
    net.Send(killer)
end

local function informHit(killer)
    net.Start('ab_hit')
    net.Send(killer)
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
            if targetArmorBefore != 0 and targetArmorAfter == 0 then
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
                return end
            return end
        return end

        if targetIsAlive and targetArmorBefore != 0 then
            if targetArmorAfter != 0 and attacker != target then
                informHit(attacker)
            else
                crack(target)

                if attacker != target then
                    inform(attacker)
                end
            return end
        return end
    return end
end )