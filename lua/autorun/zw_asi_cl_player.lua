-- Script is meant to run on client only!
if SERVER then return end

local enable_desc = 'Activate player Armor Break Indicator.'
local soundType_desc = 'Set indicator sound type. Applicable values are:\n\tnone\n\tapex\n\tbdrls\n\tmw1\n\tmw2\n\tmw3\n\tdv2\n\tfortnite\n\tmc'
local soundEnable_desc = 'Enable break indicator sounds.'
local soundRandom_desc = "Automatically pick a random sound if 'None' value is selected.\n\nWhen enabled, this functionality takes effect as soon as the next map is loaded."
local HUDGraphicsEnable_desc = 'Enable break indicator HUD graphics.'
local HUDGraphicsType_desc = 'Set indicator HUD graphics type. Applicable values are:\n\tnone\n\tcircle\n\tvignette'
local HUDGraphicsRandom_desc = "Automatically pick a random graphics style if 'None' value is selected.\n\n When enabled, this functionality takes effect as soon as the next map is loaded."
local HUDConcussionFXEnable_desc = 'Enable break indicator HUD concussion FX.\nRecommended OFF for some players as it produces possible irritating visuals.'
local netcodeArmorBrokenLive = 'zachwattz_asi_armor_broken_live'
local netcodeArmorBrokenDeath = 'zachwattz_asi_armor_broken_death'

local breakSounds = 
    {
        Sound('zw_hud/player/break_apex.ogg'),
        Sound('zw_hud/player/break_bdrls.ogg'), 
        Sound('zw_hud/player/break_mw1.ogg'), 
        Sound('zw_hud/player/break_mw2.ogg'),
        Sound('zw_hud/player/break_mw3.ogg'),
        Sound('zw_hud/player/break_dv2.ogg'),
        Sound('zw_hud/player/break_fortnite.ogg'),
        Sound('zw_hud/player/break_mc.ogg')
    }

local breakGraphics =
    {
        Material('zw_hud/player/impulse_circle.png'),
        Material('zw_hud/player/impulse_circle_screen.png'),
        Material('zw_hud/player/vignette_effect.png')
    }

-- Local VARs for 'Impulse Circle' graphics.

local soundsChoiceList = 
    {
        {'None', 'none'},
        {'Apex Legends', 'apex'},
        {'Borderlands', 'bdrls'},
        {'Call of Duty - MW1', 'mw1'},
        {'Call of Duty - MW2', 'mw2'},
        {'Call of Duty - MW3', 'mw3'},
        {'The Division 2', 'dv2'},
        {'Fortnite', 'fortnite'},
        {'Minecraft', 'mc'}
    }

local graphicsChoiceList =
    {
        {'None', 'none'},
        {'Impulse Circle', 'circle'},
        {'Vignette Effect', 'vignette'}
    }


-- Initializes the CVars
local asi_enable = CreateConVar('armor_status_indicator_player_break_enable','1', {FCVAR_ARCHIVE, FCVAR_USERINFO}, enable_desc)
local asi_sound_enable = CreateConVar('armor_status_indicator_player_sound', '1', {FCVAR_ARCHIVE}, soundEnable_desc)
local asi_sound_type = CreateConVar('armor_status_indicator_player_sound_type', 'none', {FCVAR_ARCHIVE}, soundType_desc)
local asi_sound_random_enable = CreateConVar('armor_status_indicator_player_sound_type_random', '1', {FCVAR_ARCHIVE}, soundRandom_desc)
local asi_concussion_enable = CreateConVar('armor_status_indicator_player_hudconcussion', '1', {FCVAR_ARCHIVE}, HUDConcussionFXEnable_desc)
local asi_graphics_enable = CreateConVar('armor_status_indicator_player_hudgraphics', '1', {FCVAR_ARCHIVE}, HUDGraphicsEnable_desc)
local asi_graphics_type = CreateConVar('armor_status_indicator_player_hudgraphics_type', 'none', {FCVAR_ARCHIVE}, HUDGraphicsType_desc)
local asi_graphics_random_enable = CreateConVar('armor_status_indicator_player_hudgraphics_type_random', '1', {FCVAR_ARCHIVE}, HUDGraphicsRandom_desc)


-- Local working variables.
local selectedBreakSound = nil
local selectedBreakGraphics = nil
local noStyle = false
local lastExecTConcussion = 0
local lastExecTGraphics = 0
local vfxSpeed = 0.075

-- Some useful local functions
local function isNil(s) return s == nil or s == '' end
local function loadSavedStyle()
    -- Random picker for sound.
    local soundTargetKey = GetConVar('armor_status_indicator_player_sound_type')
    local soundError404 = true

    -- If there is a chosen sound, loads it for user.
    if not isNil(soundTargetKey) then
        local key = soundTargetKey:GetString()

        for i = 2, #soundsChoiceList do
            if key == soundsChoiceList[i][2] then
                selectedBreakSound = breakSounds[i - 1]
                soundError404 = false
                break
            end
        end
    end
    
    -- If there is no chosen sound found, a random one is picked for user.
    if soundError404 and asi_sound_random_enable:GetBool() then
        math.randomseed(os.time())
        for iter = 1, #soundsChoiceList do math.random() end
        RunConsoleCommand('armor_status_indicator_player_sound_type', soundsChoiceList[math.random(2, #soundsChoiceList)][2])
    end

    -----------------------------
    -- Random picker for graphics.
    local graphicsTargetKey = GetConVar('armor_status_indicator_player_hudgraphics_type')
    local graphicsError404 = true

    -- If there is a chosen graphics setting, loads it for user.
    if not isNil(graphicsTargetKey) then
        local key = graphicsTargetKey:GetString()

        for i = 2, #graphicsChoiceList do
            if key == graphicsChoiceList[i][2] then
                selectedBreakGraphics = breakGraphics[i - 1]
                graphicsError404 = false
                break
            end
        end
    end

    -- If there is no chosen graphics found, a random one is picked for user.
    if graphicsError404 and asi_graphics_random_enable:GetBool() then
        math.randomseed(os.time())
        for iter = 1, #graphicsChoiceList do math.random() end
        RunConsoleCommand('armor_status_indicator_player_hudgraphics_type', graphicsChoiceList[math.random(2, #graphicsChoiceList)][2])
    end
end

--load specific settings--
loadSavedStyle()
--------------------------

hook.Add('PopulateToolMenu', 'PlayerArmorBreakIndicatorOptions', function()
    spawnmenu.AddToolMenuOption('Options', "ZachWattz's HUD", 'PlayerArmorBreakIndicatorOptionsMenu', 'Player Armor Break Indicator', '', '', function(optionPanel)
        optionPanel:Clear()
        optionPanel:CheckBox('Activate', 'armor_status_indicator_player_break_enable')
        optionPanel:ControlHelp(enable_desc)
        
        optionPanel:Help('====================')
        optionPanel:CheckBox('HUD Graphics', 'armor_status_indicator_player_hudgraphics')
        optionPanel:ControlHelp(HUDGraphicsEnable_desc)
        local graphicsComboBox = optionPanel:ComboBox('Graphics Selection', 'armor_status_indicator_player_hudgraphics_type')
            graphicsComboBox:SetSortItems(false)

            for i = 1, #graphicsChoiceList do
                graphicsComboBox:AddChoice(graphicsChoiceList[i][1], graphicsChoiceList[i][2])
            end

            graphicsComboBox:AddSpacer()

            graphicsComboBox.OnSelect = function(self, index, value)
                local selectedGraphicsKey = graphicsChoiceList[index][2]
                RunConsoleCommand('armor_status_indicator_player_hudgraphics_type', selectedGraphicsKey)
            end

        optionPanel:CheckBox('Random Graphics Picker', 'armor_status_indicator_player_hudgraphics_type_random')
        optionPanel:ControlHelp(HUDGraphicsRandom_desc)
        optionPanel:CheckBox('HUD Concussion FX', 'armor_status_indicator_player_hudconcussion')
        optionPanel:ControlHelp(HUDConcussionFXEnable_desc)

        optionPanel:Help('====================')
        optionPanel:CheckBox('Sounds', 'armor_status_indicator_player_sound')
        optionPanel:ControlHelp(soundEnable_desc)
        local soundsComboBox = optionPanel:ComboBox('Sound Selection', 'armor_status_indicator_player_sound_type')
            soundsComboBox:SetSortItems(false)

            for i = 1, #soundsChoiceList do
                soundsComboBox:AddChoice(soundsChoiceList[i][1], soundsChoiceList[i][2])
            end

            soundsComboBox:AddSpacer()

            soundsComboBox.OnSelect = function(self, index, value)
                RunConsoleCommand('armor_status_indicator_player_sound_type', soundsChoiceList[index][2])
                if index != 1 then
                    selectedBreakSound = breakSounds[index - 1]
                    noStyle = false
                else 
                    noStyle = true
                end
            end
        optionPanel:CheckBox('Random Sound Picker', 'armor_status_indicator_player_sound_type_random')
        optionPanel:ControlHelp(soundRandom_desc)
    end)
end )


-- HUD Graphics rendering hook.
-- Has Invalid Graphics Rendering Conditions
local function hasInvalidGRC()
    return not asi_enable:GetBool() or not asi_graphics_enable:GetBool() or asi_graphics_type:GetString() == 'none' or lastExecTGraphics < CurTime()
end

-- Switcher render
local 

hook.Add('HUDPaint', 'ZWASI_PlayerGraphicsRendering', function()
    if hasInvalidGRC() then return end
    

end)

    
-- HUD rendering hooks: Concussion FX.
-- Has Invalid Concussion FX Rendering Conditions
local function hasInvalidCFXRC()
    return not asi_enable:GetBool() or not asi_concussion_enable:GetBool() or lastExecTConcussion < CurTime()
end 

hook.Add('RenderScreenspaceEffects', 'ZWASI_PlayerOnCrackedConcussionFX', function ()
    if hasInvalidCFXRC() then return end
    
    if not noStyle then
        DrawMotionBlur( vfxSpeed, 10, 0.01 )
        
        if vfxSpeed <= 1 then
            vfxSpeed = vfxSpeed + 0.00375
        end
    end
end )

hook.Add('HUDPaint', 'ZWASI_PlayerOnCrackedConcussionBlindness', function()
    if hasInvalidCFXRC() then return end

    surface.SetDrawColor(255, 255, 255, ( lastExecTConcussion - CurTime() - 1.75 ) * 255)
    surface.DrawRect(0, 0, ScrW(), ScrH())
end )


-- Netcode handlers
net.Receive(netcodeArmorBrokenLive, function()
    if asi_enable:GetBool() and not noStyle then
        if asi_concussion_enable:GetBool() then
            lastExecTConcussion = CurTime() + 2.5
            vfxSpeed = 0.075
        end

        if asi_graphics_enable:GetBool() then
            lastExecTGraphics = CurTime() + 2.5
        end
        
        if asi_sound_enable:GetBool() then
            surface.PlaySound(selectedBreakSound)
        end
    else return end
end )

net.Receive(netcodeArmorBrokenDeath, function()
    if asi_enable:GetBool() and not noStyle then
        if asi_sound_enable:GetBool() then
            surface.PlaySound(selectedBreakSound)
        end
    else return end
end )