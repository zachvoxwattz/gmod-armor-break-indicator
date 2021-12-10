if SERVER then return end

local enable_desc = 'Activates the Player Armor Break Indicator'
local type_desc = 'Set the Player Indicator style'
local sfx_desc = 'Enable the sound of the Player Indicator'

local sounds = 
    {
        Sound('player/break_apex.ogg'),
        Sound('player/break_bdrls.ogg'), 
        Sound('player/break_cod.ogg'),
        Sound('player/break_dv2.ogg'),
        Sound('player/break_fortnite.ogg'),
        Sound('player/break_mc.ogg')
    }

local combolist = 
    {
        {'None', 'none'},
        {'Apex Legends', 'apex'},
        {'Borderlands', 'bdrls'},
        {'Call of Duty - Warzone', 'codwz'},
        {'Division 2', 'dv2'},
        {'Fortnite', 'fnite'},
        {'Minecraft', 'mc'}
    }

local selectedSound = nil

local function isNil(s) return s == nil or s == '' end
local function loadSavedStyle()
    local tarkey = GetConVar('abindicator_player_type')
    local err404 = true

    if not isNil(tarkey) then
        local key = tarkey:GetString()

        for i = 1, #combolist do
            if key == combolist[i][2] then
                selectedSound = sounds[i - 1]
                err404 = false
                break
            end
        end
    end
    if err404 then RunConsoleCommand('abindicator_player_type', 'none') end
end

CreateConVar('abindicator_player_enable','0', {FCVAR_ARCHIVE, FCVAR_USERINFO}, enable_desc)
local abi_type = CreateConVar('abindicator_player_type', 'none', {FCVAR_ARCHIVE}, type_desc)
local abi_vol = CreateConVar('abindicator_player_sound', '1', {FCVAR_ARCHIVE}, sfx_desc)
local lastExecT = 0
local noStyle = false

--load specific settings--
loadSavedStyle()
--------------------------
--[[
hook.Add('HUDPaint', 'abi2', function()
    if lastExecT < CurTime() then return end
    local icon_size = math.max(abi_icon_res:GetInt(), 0)

    if not noStyle and not isNil(selectedIcon) then
        surface.SetDrawColor( 255, 255, 255, ( lastExecT - CurTime() ) * 255 )
        surface.SetMaterial(selectedIcon)
        surface.DrawTexturedRect(ScrW() / 2 - icon_size / 2, ScrH() / 2 + (0.4 / 9) * (ScrH() / 2), icon_size, icon_size)
    end
end )]]

hook.Add('PopulateToolMenu', 'abi2', function()

    spawnmenu.AddToolMenuOption('Utilities', 'ZachWK', 'abi2', 'Player Armor Break Indicator', '', '', function(optionPanel)
        optionPanel:Clear()
        optionPanel:CheckBox('Activate', 'abindicator_player_enable')
        optionPanel:ControlHelp('Enables the Player Armor Break Indicator')
        optionPanel:CheckBox('Sounds', 'abindicator_player_sound')
        optionPanel:ControlHelp('Enables sounds for the Indicator')

        local indicator_styles = optionPanel:ComboBox('Styles', 'abindicator_player_type')
            indicator_styles:SetSortItems(false)
            indicator_styles:AddChoice('None', nil)

            for i = 2, #combolist do
                indicator_styles:AddChoice(combolist[i][1], combolist[i][2])
            end
            indicator_styles:AddSpacer()
            indicator_styles.OnSelect = function(self, index, value)
                RunConsoleCommand('abindicator_player_type', combolist[index][2])
                if index != 1 then
                    selectedSound = sounds[index - 1]
                    noStyle = false
                else noStyle = true
                end
            end
    end)
end )

net.Receive('ab_cracked', function()

    if abi_vol:GetBool() and not noStyle and not isNil(selectedSound) then
        surface.PlaySound(selectedSound)
    end
    lastExecT = CurTime() + 1.5;

end )