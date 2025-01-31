-- Script is meant to run on server only!
if CLIENT then return end

AddCSLuaFile('autorun/zw_asi_cl_target.lua')
AddCSLuaFile('autorun/zw_asi_cl_player.lua')

local targetHasArmor = false
local npcDead = 0
util.AddNetworkString('zachwattz_asi_armor_hit')
util.AddNetworkString('zachwattz_asi_armor_broken')
util.AddNetworkString('zachwattz_asi_armor_broken_live')
util.AddNetworkString('zachwattz_asi_armor_broken_death')

---------------------------------------------

local function notifyTargetArmorBrokenLive(target)
    net.Start('zachwattz_asi_armor_broken_live')
    net.Send(target)
end

---------------------------------------------

local function notifyTargetArmorBrokenDeath(target)
    net.Start('zachwattz_asi_armor_broken_death')
    net.Send(target)
end

---------------------------------------------

local function notifyAttackerArmorBroken(attacker)
    net.Start('zachwattz_asi_armor_broken')
    net.Send(attacker)
end

---------------------------------------------

local function notifyAttackerArmorHit(attacker)
    net.Start('zachwattz_asi_armor_hit')
    net.Send(attacker)
end

---------------------------------------------

local function isHumanPlayer(target)
    return target:IsPlayer()
end

---------------------------------------------

local function attackerIsNotTarget(attacker, target)
    return attacker ~= target
end

---------------------------------------------

local function targetHasInvalidActivationCondition(target)
    return not isHumanPlayer(target) or not targetHasArmor
end

---------------------------------------------
---------------------------------------------
---------------------------------------------
---------------------------------------------
---------------------------------------------


hook.Add('EntityTakeDamage', 'ZWASI_PlayerDamageListener', function(target, damageInfo)
    if not isHumanPlayer(target) then return end
    targetHasArmor = target:Armor() > 0
end)


---------------------------------------------


hook.Add('PostEntityTakeDamage', 'PlayerDamageExecutor', function(target, damageInfo)
    local attacker = damageInfo:GetAttacker()
    if targetHasInvalidActivationCondition(target) or not isHumanPlayer(attacker) then return end

    local targetIsAlive = target:Alive()
    if targetIsAlive then
        local targetArmorAfter = target:Armor()
        if targetArmorAfter > 0 and attackerIsNotTarget(attacker, target) then
            notifyAttackerArmorHit(attacker)
        return end

        if targetArmorAfter == 0 then
            notifyTargetArmorBrokenLive(target)

            if attackerIsNotTarget(attacker, target) then
                notifyAttackerArmorBroken(attacker)
            return end
        return end
    
    else
        notifyTargetArmorBrokenDeath(target)
        notifyAttackerArmorBroken(attacker)
    end
end)

hook.Add('PostEntityTakeDamage', 'AltNPCDamageExecutor', function(target, damageInfo)
    local attacker = damageInfo:GetAttacker()
    if not isHumanPlayer(attacker) then return end

    local targetHP = target:Health()
    if targetHP > 0 then
        notifyAttackerArmorHit(attacker)
    
    else
        notifyAttackerArmorBroken(attacker)
    end
end)


---------------------------------------------


hook.Add('PostEntityTakeDamage', 'NPCDamageExecutor', function(target, damageInfo)
    local attacker = damageInfo:GetAttacker()
    if targetHasInvalidActivationCondition(target) or isHumanPlayer(attacker) then return end

    local targetIsAlive = target:Alive()
    if targetIsAlive then
        local targetArmorAfter = target:Armor()
        if targetArmorAfter == 0 then
            notifyTargetArmorBrokenLive(target)
        return end
        
    else
        notifyTargetArmorBrokenDeath(target)
    end
end)
