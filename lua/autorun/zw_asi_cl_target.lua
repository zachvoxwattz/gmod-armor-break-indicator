-- Script is meant to run on client only!
if SERVER then return end

-- Set this variable to true during development and false during release.
local DEV_MODE = false


-- Some description for UI elements.
local enable_desc = 'Activate target Armor Break Status Indicator.'
local hit_enable_desc = 'Activate target Armor Hit Status Indicator.'
local type_desc = 'Set indicator style. Applicable values are:\n\tnone\n\tapex\n\tbdrls\n\tmw1\n\tmw2\n\tmw3\n\tfortnite\n\tmc.'
local break_sfx_desc = 'Enable break status indicator sound.'
local break_icon_desc = 'Enable break status indicator icon.'
local hit_sfx_desc = 'Enable hit status indicator sound.'
local hit_icon_desc = 'Enable hit status indicator icon.'
local random_desc = "Automatically pick a random style if 'None' value is selected.\n\nWhen enabled, this functionality takes effect as soon as the next map is loaded."


-- Net codes
local netcodeArmorStatusBroken = 'zachwattz_asi_armor_broken'
local netcodeArmorStatusHit = 'zachwattz_asi_armor_hit'


-- Declares all of the tables for use.
local breakStatusSounds = {}
local hitStatusSounds = {}
local breakStatusIcons = {}
local hitStatusIcons = {}
local choiceList = { {'None', 'none'} } -- Initial None value for none selection.


-- Reads the registry and initializes all of the entries
local combinedContent = nil
if not DEV_MODE then combinedContent = file.Read('data_static/zw_asi/target/combined.json', 'WORKSHOP')
else combinedContent = file.Read('data_static/zw_asi/target/combined.json', 'DATA') end


-- If 'combinedContent' is nil, displays warning message to console and performs no futher action to the addon.
if combinedContent == nil then
    error('Combined registry file for target cannot be found. Please report to mod creator for this message', 1)
return end


-- Initializes the tables.
local JSONContentTable = util.JSONToTable(combinedContent)
for key, value in pairs(JSONContentTable) do
    local contempBreakMaterial = Material(value.breakIconUri)
    local contempHitMaterial = Material(value.hitIconUri)

    table.insert(breakStatusSounds, Sound(value.breakSoundUri))
    table.insert(breakStatusIcons, contempBreakMaterial)
    table.insert(hitStatusSounds, Sound(value.hitSoundUri))
    table.insert(hitStatusIcons, contempHitMaterial)
    table.insert(choiceList, tonumber(key) + 1, { value.label, value.key })
end


-- Declares working variables.
local selectedBreakStatusIcon = nil
local selectedBreakStatusSound = nil
local selectedHitStatusIcon = nil
local selectedHitStatusSound = nil


-- Console Variables initialization
local asi_break_cvar = CreateConVar('armor_status_indicator_target_break_enable','1', {FCVAR_ARCHIVE, FCVAR_USERINFO}, enable_desc)
local asi_hit_cvar = CreateConVar('armor_status_indicator_target_hit_enable', '1', {FCVAR_ARCHIVE, FCVAR_USERINFO}, hit_enable_desc)
local asi_type = CreateConVar('armor_status_indicator_target_type', 'none', {FCVAR_ARCHIVE}, type_desc)
local asi_break_vol = CreateConVar('armor_status_indicator_target_break_sound', '1', {FCVAR_ARCHIVE}, break_sfx_desc)
local asi_hit_vol = CreateConVar('armor_status_indicator_target_hit_sound', '1', {FCVAR_ARCHIVE}, hit_sfx_desc)
local asi_break_icon = CreateConVar('armor_status_indicator_target_break_icon', '1', {FCVAR_ARCHIVE}, break_icon_desc)
local asi_hit_icon = CreateConVar('armor_status_indicator_target_hit_icon', '1', {FCVAR_ARCHIVE}, hit_icon_desc)
local asi_random_on = CreateConVar('armor_status_indicator_target_type_random', '1', {FCVAR_ARCHIVE}, random_desc)


-- Working variables
local breakStatusRenderTime = 0
local hitStatusRenderTime = 0
local breakIconOpacity = 0
local hitIconOpacity = 0
local iconFXScale = 25 -- In Percentage
local iconFXRes = 0
local iconFXResponsiveResolution = ScrW() * 0.03125
local noStyle = false


-- Some useful local functions
local function isNil(s) return s == nil or s == '' end
local function loadSavedSettings()
    local tarkey = GetConVar('armor_status_indicator_target_type')
    local err404 = true

    if not isNil(tarkey) then
        local key = tarkey:GetString()

        for i = 2, #choiceList do
            if key == choiceList[i][2] then
                selectedBreakStatusIcon = breakStatusIcons[i - 1]
                selectedBreakStatusSound = breakStatusSounds[i - 1]
                selectedHitStatusIcon = hitStatusIcons[i - 1]
                selectedHitStatusSound = hitStatusSounds[i - 1]
                err404 = false
                break
            end
        end
    end

    -- If there is no style found, a random style is picked for user.
    if err404 and asi_random_on:GetBool() then
        math.randomseed(os.time())
        for iter = 1, #choiceList do math.random() end

        local randomlyChosenIndex = math.random(2, #choiceList)
        RunConsoleCommand('armor_status_indicator_target_type', choiceList[randomlyChosenIndex][2])
        selectedBreakStatusIcon = breakStatusIcons[randomlyChosenIndex - 1]
        selectedBreakStatusSound = breakStatusSounds[randomlyChosenIndex - 1]
        selectedHitStatusIcon = hitStatusIcons[randomlyChosenIndex - 1]
        selectedHitStatusSound = hitStatusSounds[randomlyChosenIndex - 1]

        err404 = false
    end
end


local function getIconRes()
    local returnedValue

    if math.floor(iconFXRes) > iconFXResponsiveResolution then
        iconFXRes = iconFXRes - 2.5
        returnedValue = iconFXRes
    else
        returnedValue = iconFXResponsiveResolution
    end
    
    return returnedValue
end

-- Loads specific settings
loadSavedSettings()


-- Constructs Options panel in Tool Menu.
hook.Add('PopulateToolMenu', 'ZWASI_TargetArmorStatusIndicatorOptions', function()

    spawnmenu.AddToolMenuOption('Options', "ZachWattz's HUD", 'TargetArmorStatusIndicatorOptionsMenu', 'Target Armor Status Indicator', '', '', function(optionPanel)
        optionPanel:Clear()
        optionPanel:CheckBox('Break Status Indicator', 'armor_status_indicator_target_break_enable')
        optionPanel:ControlHelp(enable_desc)
        optionPanel:CheckBox('Sounds', 'armor_status_indicator_target_break_sound')
        optionPanel:ControlHelp(break_sfx_desc)
        optionPanel:CheckBox('Indicator Icon', 'armor_status_indicator_target_break_icon')
        optionPanel:ControlHelp(break_icon_desc)

        optionPanel:Help('========================')
        optionPanel:CheckBox('Hit Status Indicator', 'armor_status_indicator_target_hit_enable')
        optionPanel:ControlHelp(hit_enable_desc)
        optionPanel:CheckBox('Sounds', 'armor_status_indicator_target_hit_sound')
        optionPanel:ControlHelp(hit_sfx_desc)
        optionPanel:CheckBox('Indicator Icon', 'armor_status_indicator_target_hit_icon')
        optionPanel:ControlHelp(hit_icon_desc)

        optionPanel:Help('========================')
        local indicator_styles = optionPanel:ComboBox('Styles', 'armor_status_indicator_target_type')
            indicator_styles:SetSortItems(false)

            for i = 1, #choiceList do
                indicator_styles:AddChoice(choiceList[i][1], choiceList[i][2])
            end

            indicator_styles:AddSpacer()

            indicator_styles.OnSelect = function(self, index, value)
                RunConsoleCommand('armor_status_indicator_target_type', choiceList[index][2])
                if index != 1 then
                    selectedBreakStatusSound = breakStatusSounds[index - 1]
                    selectedHitStatusSound = hitStatusSounds[index - 1]
                    selectedBreakStatusIcon = breakStatusIcons[index - 1]
                    selectedHitStatusIcon = hitStatusIcons[index - 1]
                    noStyle = false
                else 
                    noStyle = true
                end
            end
        optionPanel:CheckBox('Random Style Picker', 'armor_status_indicator_target_type_random')
        optionPanel:ControlHelp(random_desc)
    end )
end )


--- Event handling section.
-- onBroken event
local function OnTargetArmorStatusBroken()
    if asi_break_cvar:GetBool() and not noStyle then
        -- Checks to see if displaying break icon is enabled.
        if asi_break_icon:GetBool() then
            breakStatusRenderTime = CurTime() + 0.75
            breakIconOpacity = 255
            hitStatusRenderTime = -1
            iconFXRes = iconFXResponsiveResolution * (1 + (iconFXScale / 100))
        end
        
        -- Checks to see if playing break sound is enabled.
        if asi_break_vol:GetBool() then
            surface.PlaySound(selectedBreakStatusSound)
        end
    end
end

-- onHit event
local function OnTargetArmorStatusHit()
    if asi_hit_cvar:GetBool() and not noStyle then
        -- Checks to see if displaying hit icon is enabled.
        if asi_hit_icon:GetBool() then
            hitStatusRenderTime = CurTime() + 0.75
            hitIconOpacity = 255
            breakStatusRenderTime = -1
            iconFXRes = iconFXResponsiveResolution * (1 + (iconFXScale / 100))
        end
        
        -- Checks to see if playing hit sound is enabled.
        if asi_hit_vol:GetBool() then
            surface.PlaySound(selectedHitStatusSound)
        end
    end
end

-- Adding them to net library.
net.Receive(netcodeArmorStatusBroken, OnTargetArmorStatusBroken)
net.Receive(netcodeArmorStatusHit, OnTargetArmorStatusHit)


--- Rendering section.
local function HandleRenderCLTargetHit()
    if hitStatusRenderTime < CurTime() then return end

    if asi_hit_icon:GetBool() and not noStyle and not isNil(selectedHitStatusIcon) then
        local icon_size = getIconRes()

        -- Main draw section
        surface.SetDrawColor(255, 255, 255, hitIconOpacity)
        surface.SetMaterial(selectedHitStatusIcon)
        surface.DrawTexturedRect(ScrW() / 2 - ((icon_size - ScrW() * 0.1) / 2), ScrH() / 2 - ((icon_size - ScrH() * 0.15) / 2), icon_size, icon_size)

        -- Handling fade out.
        if hitStatusRenderTime - CurTime() <= 0.125 then
            hitIconOpacity = math.floor((hitStatusRenderTime - CurTime()) * 255)
        end
    end
end

local function HandleRenderCLTargetBreak()
    if breakStatusRenderTime < CurTime() then return end

    if asi_break_icon:GetBool() and not noStyle and not isNil(selectedBreakStatusIcon) then
        local icon_size = getIconRes()

        surface.SetDrawColor(255, 255, 255, breakIconOpacity)
        surface.SetMaterial(selectedBreakStatusIcon)
        surface.DrawTexturedRect(ScrW() / 2 - ((icon_size - ScrW() * 0.1) / 2), ScrH() / 2 - ((icon_size - ScrH() * 0.15) / 2), icon_size, icon_size)
        
        if breakStatusRenderTime - CurTime() <= 0.125 then
            breakIconOpacity = math.floor((breakStatusRenderTime - CurTime()) * 255)
        end
    end
end 

-- Adds functions to rendering hook.
hook.Add('HUDPaint', 'ZWASI_TargetArmorHitStatusIndication', HandleRenderCLTargetHit)
hook.Add('HUDPaint', 'ZWASI_TargetArmorBrokenStatusIndication', HandleRenderCLTargetBreak)