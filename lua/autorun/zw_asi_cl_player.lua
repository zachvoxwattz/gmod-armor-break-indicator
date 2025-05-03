-- Script is meant to run on client only!
if SERVER then return end

-- Set this variable to true during development and false during release.
local DEV_MODE = true


-- Some description for UI elements.
local enable_desc = 'Activate player Armor Break Indicator.'
local soundType_desc = 'Set indicator sound type. Applicable values are:\n\tnone\n\tapex\n\tbdrls\n\tmw1\n\tmw2\n\tmw3\n\tdv2\n\tfortnite\n\tmc'
local soundEnable_desc = 'Enable break indicator sounds.'
local soundRandom_desc = "Automatically pick a random sound if 'None' value is selected.\n\nWhen enabled, this functionality takes effect as soon as the next map is loaded."
local HUDGraphicsEnable_desc = 'Enable break indicator HUD graphics.'
local HUDGraphicsType_desc = 'Set indicator HUD graphics type. Applicable values are:\n\tnone\n\tcircle\n\tvignette\n\tconcuss'
local HUDGraphicsRandom_desc = "Automatically pick a random graphics style if 'None' value is selected.\n\n When enabled, this functionality takes effect as soon as the next map is loaded."


-- Net codes
local netcodeArmorBrokenLive = 'zachwattz_asi_armor_broken_live'
local netcodeArmorBrokenDeath = 'zachwattz_asi_armor_broken_death'


--- Sounds initialization phase
-- Declares all of the tables for sounds
local breakSounds = {}
local soundsChoiceList = { {'None', 'none'} }


-- Reads the registry and initializes sounds and choices
local soundsChoicesContent = nil
if not DEV_MODE then soundsChoicesContent = file.Read('data_static/zw_asi/player/sounds_choices.json', 'WORKSHOP')
else soundsChoicesContent = file.Read('zw_asi/player/sounds_choices.json', 'DATA') end


-- If 'soundsChoicesContent' is nil, displays warning message to console and performs no futher action to the addon.
if soundsChoicesContent == nil then
    error('Sounds and choices registry file for player cannot be found. Please report to mod creator for this message', 1)
return end


-- Initializes the tables related to sound and choice.
local SFXChoicesJSONContentTable = util.JSONToTable(soundsChoicesContent)
for key, value in pairs(SFXChoicesJSONContentTable) do
    table.insert(breakSounds, Sound(value.breakSoundUri))
    table.insert(soundsChoiceList, key + 1, { value.label, value.key })
end
------------------------------


--- Graphics Choices and Render functions initialization phase
-- Declares the table for graphics choice and render functions.
local graphicsChoiceList = { {'None', 'none'} }
local renderFunctionsTable = {}

-- Reads the registry for graphics choice and initializes all of them
local graphicsChoiceContent = nil
if not DEV_MODE then graphicsChoiceContent = file.Read('data_static/zw_asi/player/graphics_choices.json', 'WORKSHOP')
else graphicsChoiceContent = file.Read('zw_asi/player/graphics_choices.json', 'DATA') end


-- If 'graphicsChoiceContent' is nil, displays warning message to console and performs no futher action to the addon.
if graphicsChoiceContent == nil then
    error('Graphics choices registry file for player cannot be found. Please report to mod creator for this message', 1)
return end


-- Initializes the table related to graphics choices.
local GChoicesJSONContentTable = util.JSONToTable(graphicsChoiceContent)
for key, value in pairs(GChoicesJSONContentTable) do
    table.insert(graphicsChoiceList, { value.label, value.key })
    renderFunctionsTable[value.key] =
        {
            engage = nil,
            disengage = nil,
            trigger = nil
        }
end


-- Imports and manually assigns the functions
-- to the render functions table here.
include("zw_asi/render_funcs1.lua")
include("zw_asi/render_funcs2.lua")
include("zw_asi/render_funcs3.lua")

renderFunctionsTable['concuss'] = 
    {
        engage = ZWASI_EngageConcussionFX,
        disengage = ZWASI_DisengageConcussionFX,
        trigger = ZWASI_TriggerConcussionFX
    }

renderFunctionsTable['vignette'] = 
    {
        engage = ZWASI_EngageVignetteFOV,
        disengage = ZWASI_DisengageVignetteFOV,
        trigger = ZWASI_TriggerVignetteFOV
    }

renderFunctionsTable['circle'] = 
    {
        engage = ZWASI_EngageImpulseCircleHUD,
        disengage = ZWASI_DisengageImpulseCircleHUD,
        trigger = ZWASI_TriggerImpulseCircleHUD
    }

------------------------------


-- Initializes the CVars
local asi_enable = CreateConVar('armor_status_indicator_player_break_enable','1', {FCVAR_ARCHIVE, FCVAR_USERINFO}, enable_desc)
local asi_sound_enable = CreateConVar('armor_status_indicator_player_sound', '1', {FCVAR_ARCHIVE}, soundEnable_desc)
local asi_sound_type = CreateConVar('armor_status_indicator_player_sound_type', 'none', {FCVAR_ARCHIVE}, soundType_desc)
local asi_sound_random_enable = CreateConVar('armor_status_indicator_player_sound_type_random', '1', {FCVAR_ARCHIVE}, soundRandom_desc)
local asi_graphics_enable = CreateConVar('armor_status_indicator_player_hudgraphics', '1', {FCVAR_ARCHIVE}, HUDGraphicsEnable_desc)
local asi_graphics_type = CreateConVar('armor_status_indicator_player_hudgraphics_type', 'none', {FCVAR_ARCHIVE}, HUDGraphicsType_desc)
local asi_graphics_random_enable = CreateConVar('armor_status_indicator_player_hudgraphics_type_random', '1', {FCVAR_ARCHIVE}, HUDGraphicsRandom_desc)


-- Local working variables.
local selectedBreakSound = nil
local previousBreakGraphicsKey = nil
local currentSelectedGraphicsKey = nil
local noSoundSelected = false
local noGraphicsSelected = false

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
        
        local randomlyChosenIndex = math.random(2, #soundsChoiceList)
        RunConsoleCommand('armor_status_indicator_player_sound_type', soundsChoiceList[randomlyChosenIndex][2])
        selectedBreakSound = breakSounds[randomlyChosenIndex - 1]
        soundError404 = false
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
                currentSelectedGraphicsKey = key
                renderFunctionsTable[currentSelectedGraphicsKey].engage()

                graphicsError404 = false
                break
            end
        end
    end

    -- If there is no chosen graphics found, a random one is picked for user.
    if graphicsError404 and asi_graphics_random_enable:GetBool() then
        math.randomseed(os.time())
        for iter = 1, #graphicsChoiceList do math.random() end

        local randomlyPickedGraphicsKey = graphicsChoiceList[math.random(2, #graphicsChoiceList)][2]
        RunConsoleCommand('armor_status_indicator_player_hudgraphics_type', randomlyPickedGraphicsKey)

        currentSelectedGraphicsKey = randomlyPickedGraphicsKey
        renderFunctionsTable[currentSelectedGraphicsKey].engage()

        graphicsError404 = false
    end
end

--load specific settings--
loadSavedStyle()
--------------------------


--- UI Options component setup
local function SetUpOptionsPanel()
    spawnmenu.AddToolMenuOption('Options', "ZachWattz's HUD", 'ZWASI_PlayerArmorBreakIndicatorOptionsMenu', 'Player Armor Break Indicator', '', '', function(optionPanel)
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
                local selectedKey = graphicsChoiceList[index][2]
                RunConsoleCommand('armor_status_indicator_player_hudgraphics_type', selectedKey)
                if index != 1 then
                    noGraphicsSelected = false
                
                    previousBreakGraphicsKey = currentSelectedGraphicsKey
                    currentSelectedGraphicsKey = selectedKey
                    
                    -- Disengages previously selected function if exists.
                    if previousBreakGraphicsKey ~= nil then
                        renderFunctionsTable[previousBreakGraphicsKey].disengage()
                    end

                    renderFunctionsTable[currentSelectedGraphicsKey].engage() -- Engages new hook
                else
                    noGraphicsSelected = true
                    -- Disengages currently selected function if exists.
                    if currentSelectedGraphicsKey ~= nil then
                        renderFunctionsTable[currentSelectedGraphicsKey].disengage()
                    end

                    previousBreakGraphicsKey = nil
                    currentSelectedGraphicsKey = nil
                end
            end

        optionPanel:CheckBox('Random Graphics Picker', 'armor_status_indicator_player_hudgraphics_type_random')
        optionPanel:ControlHelp(HUDGraphicsRandom_desc)

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
                    noSoundSelected = false
                else 
                    noSoundSelected = true
                end
            end
        optionPanel:CheckBox('Random Sound Picker', 'armor_status_indicator_player_sound_type_random')
        optionPanel:ControlHelp(soundRandom_desc)
    end)
end


-- and binds it to the hook.
hook.Add('PopulateToolMenu', 'ZWASI_PlayerArmorBreakIndicatorOptions', SetUpOptionsPanel)


--- Event handling
local function OnArmorBrokenLive()
    if asi_enable:GetBool() then
        if asi_graphics_enable:GetBool() and not noGraphicsSelected then
            renderFunctionsTable[currentSelectedGraphicsKey].trigger() -- Triggers graphics here.
        end
        
        if asi_sound_enable:GetBool() and not noSoundSelected then
            surface.PlaySound(selectedBreakSound)
        end
    else return end
end


local function OnArmorBrokenDeath()
    if asi_enable:GetBool() then
        if asi_sound_enable:GetBool() and not noSoundSelected then
            surface.PlaySound(selectedBreakSound)
        end
    else return end
end

-- Binds all handling function to net library.
net.Receive(netcodeArmorBrokenLive, OnArmorBrokenLive)
net.Receive(netcodeArmorBrokenDeath, OnArmorBrokenDeath)