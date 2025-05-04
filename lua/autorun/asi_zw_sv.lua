-- Script is meant to be running on SERVER only!
if CLIENT then return end

--- Adding CS Lua files and initializing network strings.

AddCSLuaFile('autorun/asi_zw_cl_target.lua')
AddCSLuaFile('autorun/asi_zw_cl_player.lua')
AddCSLuaFile('zw_asi/render_funcs1.lua')
AddCSLuaFile('zw_asi/render_funcs2.lua')
AddCSLuaFile('zw_asi/render_funcs3.lua')

util.AddNetworkString('zachwattz_asi_armor_hit')
util.AddNetworkString('zachwattz_asi_armor_broken')
util.AddNetworkString('zachwattz_asi_armor_broken_live')
util.AddNetworkString('zachwattz_asi_armor_broken_death')


--- Local functions and variables
---------------------------------------------

local targetHasArmor = false

---------------------------------------------

function notifyTargetArmorBrokenLive(target)
    net.Start('zachwattz_asi_armor_broken_live')
    net.Send(target)
end

---------------------------------------------

function notifyTargetArmorBrokenDeath(target)
    net.Start('zachwattz_asi_armor_broken_death')
    net.Send(target)
end

---------------------------------------------

function notifyAttackerArmorBroken(attacker)
    net.Start('zachwattz_asi_armor_broken')
    net.Send(attacker)
end

---------------------------------------------

function notifyAttackerArmorHit(attacker)
    net.Start('zachwattz_asi_armor_hit')
    net.Send(attacker)
end

---------------------------------------------

function isAttackerPlayer(attacker)
    return attacker:IsPlayer()
end

---------------------------------------------

function isTargetPlayer(target)
    return target:IsPlayer()
end

---------------------------------------------

function attackerIsNotTarget(attacker, target)
    return attacker ~= target
end

---------------------------------------------
---------------------------------------------
---------------------------------------------
---------------------------------------------
---------------------------------------------

function OnPlayerDamage(target, damageInfo)
    if not isTargetPlayer(target) then return end
    targetHasArmor = target:Armor() > 0
end

function OnPostPlayerDamage(target, damageInfo)
    local attacker = damageInfo:GetAttacker()
    if not isAttackerPlayer(attacker) or not isTargetPlayer(target) or not targetHasArmor then return end

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
end

function OnPostNPCDamage(target, damageInfo)
    local attacker = damageInfo:GetAttacker()
    if isAttackerPlayer(attacker) or not isTargetPlayer(target) or not targetHasArmor then return end

    local targetIsAlive = target:Alive()
    if targetIsAlive then
        local targetArmorAfter = target:Armor()
        if targetArmorAfter == 0 then
            notifyTargetArmorBrokenLive(target)
        return end
        
    else
        notifyTargetArmorBrokenDeath(target)
    end
end


-- Registering everything to the hook lib.
hook.Add('EntityTakeDamage', 'ZWASI_PlayerDamageListener', OnPlayerDamage)
hook.Add('PostEntityTakeDamage', 'ZWASI_PostPlayerDamageListener', OnPostPlayerDamage)
hook.Add('PostEntityTakeDamage', 'ZWASI_PostNPCDamageListener', OnPostNPCDamage)
