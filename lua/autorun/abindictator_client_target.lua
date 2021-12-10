if SERVER then return end

local enable_desc = 'Activates the Target Armor Break Indicator'
local type_desc = 'Set the Target Indicator style'
local sfx_desc = 'Enable the sound of the Target Indicator'
local icon_desc = 'Set the resolution of the indicator icon'

local sounds = 
    {
        Sound('target/break_apex.ogg'),
        Sound('target/break_bdrls.ogg'), 
        Sound('target/break_cod.ogg'),
        Sound('target/break_fortnite.ogg'),
        Sound('target/break_mc.ogg')
    }

local icons = 
    {
        Material('icon_apex.png'),
        Material('icon_bdrls.png'),
        Material('icon_cod.png'), 
        Material('icon_fortnite.png'),
        Material('icon_mc.png')
    }

local combolist = 
    {
        {'None', 'none'},
        {'Apex Legends', 'apex'},
        {'Borderlands', 'bdrls'},
        {'Call of Duty - Warzone', 'codwz'},
        {'Fortnite', 'fnite'},
        {'Minecraft', 'mc'}
    }

local selectedIcon = nil
local selectedSound = nil

local function isNil(s) return s == nil or s == '' end
local function loadSavedStyle()
    local tarkey = GetConVar('abindicator_target_type')
    local err404 = true

    if not isNil(tarkey) then
        local key = tarkey:GetString()

        for i = 1, #combolist do
            if key == combolist[i][2] then
                selectedIcon = icons[i - 1]
                selectedSound = sounds[i - 1]
                err404 = false
                break
            end
        end
    end
    if err404 then RunConsoleCommand('abindicator_target_type', 'none') end
end

CreateConVar('abindicator_target_enable','0', {FCVAR_ARCHIVE, FCVAR_USERINFO}, enable_desc)
local abi_type = CreateConVar('abindicator_target_type', 'none', {FCVAR_ARCHIVE}, type_desc)
local abi_vol = CreateConVar('abindicator_target_sound', '1', {FCVAR_ARCHIVE}, sfx_desc)
local abi_icon_res = CreateConVar('abindicator_target_icon_res', '256', {FCVAR_ARCHIVE}, icon_desc)
local lastExecT = 0
local noStyle = false

--load specific settings--
loadSavedStyle()
--------------------------

hook.Add('HUDPaint', 'abi', function()
    if lastExecT < CurTime() then return end
    local icon_size = math.max(abi_icon_res:GetInt(), 0)

    if not noStyle and not isNil(selectedIcon) then
        surface.SetDrawColor( 255, 255, 255, ( lastExecT - CurTime() ) * 255 )
        surface.SetMaterial(selectedIcon)
        surface.DrawTexturedRect(ScrW() / 2 - icon_size / 2, ScrH() / 2 + (0.4 / 9) * (ScrH() / 2), icon_size, icon_size)
    end
end )

hook.Add('PopulateToolMenu', 'abi', function()

    spawnmenu.AddToolMenuOption('Utilities', 'ZachWK', 'abi', 'Target Armor Break Indicator', '', '', function(optionPanel)
        optionPanel:Clear()
        optionPanel:CheckBox('Activate', 'abindicator_target_enable')
        optionPanel:ControlHelp('Enables the Target Armor Break Indicator')
        optionPanel:CheckBox('Sounds', 'abindicator_target_sound')
        optionPanel:ControlHelp('Enables sounds for the Indicator')

        local indicator_styles = optionPanel:ComboBox('Styles', 'abindicator_target_type')
            indicator_styles:SetSortItems(false)
            indicator_styles:AddChoice('None', nil)

            for i = 2, #combolist do
                indicator_styles:AddChoice(combolist[i][1], combolist[i][2])
            end
            indicator_styles:AddSpacer()
            indicator_styles.OnSelect = function(self, index, value)
                RunConsoleCommand('abindicator_target_type', combolist[index][2])
                if index != 1 then
                    selectedSound = sounds[index - 1]
                    selectedIcon = icons[index - 1]
                    noStyle = false

                else noStyle = true
                end
            end
            
        optionPanel:NumSlider('Texture Resolution', 'abindicator_target_icon_res', 192, 256, 0)

    end)
end )

net.Receive('ab_broken', function()

    if abi_vol:GetBool() and not noStyle and not isNil(selectedSound) then
        surface.PlaySound(selectedSound)
    end
    lastExecT = CurTime() + 1.5;

end )