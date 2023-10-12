AddCSLuaFile('autorun/client/abindicator_cl_target.lua')
AddCSLuaFile('autorun/client/abindicator_cl_player.lua')

local targetHasArmor = false
util.AddNetworkString('ab_armor_hit')
util.AddNetworkString('ab_armor_broken')
util.AddNetworkString('ab_armor_broken_live')
util.AddNetworkString('ab_armor_broken_death')

---------------------------------------------

local function informTargetArmorBrokenLive(target)
    net.Start('ab_armor_broken_live')
    net.Send(target)
end

---------------------------------------------

local function informTargetArmorBrokenDeath(target)
    net.Start('ab_armor_broken_death')
    net.Send(target)
end

---------------------------------------------

local function informAttackerArmorBroken(attacker)
    net.Start('ab_armor_broken')
    net.Send(attacker)
end

---------------------------------------------

local function informAttackerArmorHit(attacker)
    net.Start('ab_armor_hit')
    net.Send(attacker)
end

---------------------------------------------

local function isHumanPlayer(target)
    return target:IsPlayer()
end

---------------------------------------------

local function attackerIsNotTarget(attacker, target)
    return attacker != target
end

---------------------------------------------

local function invalidActivationConditions(target)
    return not isHumanPlayer(target) or not targetHasArmor
end

---------------------------------------------
---------------------------------------------
---------------------------------------------
---------------------------------------------
---------------------------------------------


hook.Add('EntityTakeDamage', 'PlayerDamageListener', function(target, damageInfo)
    if not isHumanPlayer(target) then return end
    targetHasArmor = target:Armor() > 0
end)


---------------------------------------------


hook.Add('PostEntityTakeDamage', 'PlayerDamageExecutor', function(target, damageInfo)
    local attacker = damageInfo:GetAttacker()
    if invalidActivationConditions(target) or not isHumanPlayer(attacker) then return end

    local targetIsAlive = target:Alive()
    if targetIsAlive then
        local targetArmorAfter = target:Armor()
        if targetArmorAfter > 0 and attackerIsNotTarget(attacker, target) then
            informAttackerArmorHit(attacker)
        return end

        if targetArmorAfter == 0 then
            informTargetArmorBrokenLive(target)

            if attackerIsNotTarget(attacker, target) then
                informAttackerArmorBroken(attacker)
            return end
        return end
    
    else
        informTargetArmorBrokenDeath(target)
        informAttackerArmorBroken(attacker)
    end
end)


---------------------------------------------


hook.Add('PostEntityTakeDamage', 'NPCDamageExecutor', function(target, damageInfo)
    local attacker = damageInfo:GetAttacker()
    if invalidActivationConditions(target) or isHumanPlayer(attacker) then return end

    local targetIsAlive = target:Alive()
    if targetIsAlive then
        local targetArmorAfter = target:Armor()
        if targetArmorAfter == 0 then
            informTargetArmorBrokenLive(target)
        return end
        
    else
        informTargetArmorBrokenDeath(target)
    end
end)
