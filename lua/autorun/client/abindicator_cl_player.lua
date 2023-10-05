local enable_desc = 'Activates the Player Armor Break Indicator'
local type_desc = 'Set the Player Indicator style. Applicable values are: \n\tnone, apex, bdrls, mw1, dv2, fnite, mc'
local sfx_desc = 'Enables indicator sounds'
local fx_desc = 'Enables indicator visual effects'
local random_desc = "Automatically sets a random style if 'None' value is selected.\n\nWhen enabled, this functionality takes effect immediately on the next map load"

local sounds = 
    {
        Sound('player/break_apex.ogg'),
        Sound('player/break_bdrls.ogg'), 
        Sound('player/break_mw1.ogg'), 
        Sound('player/break_mw2.ogg'),
        Sound('player/break_dv2.ogg'),
        Sound('player/break_fortnite.ogg'),
        Sound('player/break_mc.ogg')
    }

local combolist = 
    {
        {'None', 'none'},
        {'Apex Legends', 'apex'},
        {'Borderlands', 'bdrls'},
        {'Call of Duty - Modern Warfare 1', 'mw1'},
        {'Call of Duty - Modern Warfare 2', 'mw2'},
        {'The Division 2', 'dv2'},
        {'Fortnite', 'fnite'},
        {'Minecraft', 'mc'}
    }

local selectedSound = nil

local abi_on = CreateConVar('abindicator_player_enable','1', {FCVAR_ARCHIVE, FCVAR_USERINFO}, enable_desc)
local abi_type = CreateConVar('abindicator_player_type', 'none', {FCVAR_ARCHIVE}, type_desc)
local abi_vol = CreateConVar('abindicator_player_sound', '1', {FCVAR_ARCHIVE}, sfx_desc)
local abi_fx = CreateConVar('abindicator_player_fx', '1', {FCVAR_ARCHIVE}, fx_desc)
local abi_random_on = CreateConVar('abindicator_player_type_random', '1', {FCVAR_ARCHIVE}, random_desc)

local noStyle = false
local lastExecT = 0
local vfxSpeed = 0.075

-- Some useful local functions
local function isNil(s) return s == nil or s == '' end
local function loadSavedStyle()
    local tarkey = GetConVar('abindicator_player_type')
    local err404 = true

    if not isNil(tarkey) then
        local key = tarkey:GetString()

        for i = 2, #combolist do
            if key == combolist[i][2] then
                selectedSound = sounds[i - 1]
                err404 = false
                break
            end
        end
    end
    -- If there is no style found, a random style is generated for user.
    if err404 and abi_random_on:GetBool() then
        math.randomseed(os.time())
        for iter = 1, #combolist do math.random() end
        RunConsoleCommand('abindicator_player_type', combolist[math.random(2, #combolist)][2])
    end
end

--load specific settings--
loadSavedStyle()
--------------------------

hook.Add('PopulateToolMenu', 'PlayerArmorBreakIndicatorOptions', function()
    spawnmenu.AddToolMenuOption('Utilities', 'ZachWattz', 'PlayerArmorBreakIndicatorOptionsMenu', 'Player Armor Break Indicator', '', '', function(optionPanel)
        optionPanel:Clear()
        optionPanel:CheckBox('Activate', 'abindicator_player_enable')
        optionPanel:ControlHelp(enable_desc)
        optionPanel:CheckBox('Sounds', 'abindicator_player_sound')
        optionPanel:ControlHelp(sfx_desc)
        optionPanel:CheckBox('Indicator FX', 'abindicator_player_fx')
        optionPanel:ControlHelp(fx_desc)
        optionPanel:Help('====================')

        local indicator_styles = optionPanel:ComboBox('Styles', 'abindicator_player_type')
            indicator_styles:SetSortItems(false)

            for i = 1, #combolist do
                indicator_styles:AddChoice(combolist[i][1], combolist[i][2])
            end

            indicator_styles:AddSpacer()

            indicator_styles.OnSelect = function(self, index, value)
                RunConsoleCommand('abindicator_player_type', combolist[index][2])
                if index != 1 then
                    selectedSound = sounds[index - 1]
                    noStyle = false
                else 
                    noStyle = true
                end
            end
        optionPanel:CheckBox('Random Style Picker', 'abindicator_player_type_random')
        optionPanel:ControlHelp(random_desc)
    end)
end )

hook.Add('RenderScreenspaceEffects', 'PlayerOnCrackedVFX', function ()
    if lastExecT < CurTime() then 
        vfxSpeed = 0.075
    return end
    
    if not noStyle and abi_fx:GetBool() then
        DrawMotionBlur( vfxSpeed, 10, 0.01 )
        
        if vfxSpeed <= 1 then
            vfxSpeed = vfxSpeed + 0.00375
        end
    end
end )

hook.Add('HUDPaint', 'PlayerOnCrackedConcussion', function()
    if lastExecT < CurTime() then return end

    if abi_fx:GetBool() then
        surface.SetDrawColor(255, 255, 255, ( lastExecT - CurTime() - 1.75 ) * 255)
        surface.DrawRect(0, 0, ScrW(), ScrH())
    end
end )

net.Receive('ab_armor_broken_live', function()
    if abi_on:GetBool() and not noStyle then
        if abi_fx:GetBool() then
            lastExecT = CurTime() + 2.5
        end
        
        if abi_vol:GetBool() then
            surface.PlaySound(selectedSound)
        end
    else return end
end )

net.Receive('ab_armor_broken_death', function()
    if abi_on:GetBool() and not noStyle then
        if abi_vol:GetBool() then
            surface.PlaySound(selectedSound)
        end
    else return end
end )