if SERVER then return end

local enable_desc = 'Activates the Armor Break Indicator'
local type_desc = 'Set the Indicator style'
local sfx_desc = 'Enable the sound of the Indicator'
local icon_desc = 'Set the resolution of the indicator icon'

local sounds = 
    {
        Sound('break_cod.ogg'), 
        Sound('break_mc.ogg'),
        Sound('break_apex.ogg')
    }

local icons = 
    {
        Material('icon_cod.png'), 
        Material('icon_mc.png'),
        Material('icon_apex.png')
    }

local chosenID = math.random(1, 3)
local selectedIcon = icons[chosenID]
local selectedSound = sounds[chosenID]

CreateConVar('asbindicator_enable','0', {FCVAR_ARCHIVE, FCVAR_USERINFO}, enable_desc)

local asbi_type = nil

if chosenID == 1 then
    asbi_type = CreateConVar('asbindicator_type', 'cod', {FCVAR_ARCHIVE}, type_desc)
elseif chosenID == 2 then
    asbi_type = CreateConVar('asbindicator_type', 'mc', {FCVAR_ARCHIVE}, type_desc)
elseif chosenID == 3 then
    asbi_type = CreateConVar('asbindicator_type', 'apex', {FCVAR_ARCHIVE}, type_desc)
end

local asbi_vol = CreateConVar('asbindicator_sound', '1', {FCVAR_ARCHIVE}, sfx_desc)
local asbi_icon_res = CreateConVar('asbindicator_icon_res', '256', {FCVAR_ARCHIVE}, icon_desc)
local lastExecT = 0
local noStyle = false

hook.Add('HUDPaint', 'asbi', function()
    
    if lastExecT < CurTime() then return end
    local icon_size = math.max(asbi_icon_res:GetInt(), 0)

    if not noStyle then
        surface.SetDrawColor( 255, 255, 255, ( lastExecT - CurTime() ) * 255 )
        surface.SetMaterial(selectedIcon)
        surface.DrawTexturedRect(ScrW() / 2 - icon_size / 2, ScrH() / 2 - (0.4 / 9) * (ScrH() / 2), icon_size, icon_size)
    end
    
end )

hook.Add('PopulateToolMenu', 'asbi', function()

    spawnmenu.AddToolMenuOption('Utilities', 'ZachWK', 'asbi', 'Armor Break Indicator', '', '', function(optionPanel)
        optionPanel:Clear()
        optionPanel:CheckBox('Activate', 'asbindicator_enable')
        optionPanel:ControlHelp('Enables the addon')
        optionPanel:CheckBox('Enable sounds', 'asbindicator_sound')
        optionPanel:ControlHelp('Enables sounds for the Indicator')

        local indicator_styles = optionPanel:ComboBox('Type', 'asbindicator_type')
            indicator_styles:SetSortItems(false)
            indicator_styles:AddChoice('None', nil)
            indicator_styles:AddChoice('Call of Duty - Warzone', 'cod')
            indicator_styles:AddChoice('Minecraft', 'mc')
            indicator_styles:AddChoice('Apex Legends', 'apex')
            indicator_styles:AddSpacer()
            indicator_styles:ChooseOptionID(chosenID + 1)
            indicator_styles.OnSelect = function(self, index, value)
                if index != 1 then
                    selectedSound = sounds[index - 1]
                    selectedIcon = icons[index - 1]
                    noStyle = false

                else noStyle = true
                end
            end
            
        optionPanel:NumSlider('Indicator Resolution', 'asbindicator_icon_res', 128, 256, 0)

    end)
end )

net.Receive('asbi_act', function()

    if asbi_vol:GetBool() and not noStyle then
        surface.PlaySound(selectedSound)
    end
    lastExecT = CurTime() + 1.5;

end )