local enable_desc = 'Activates the Target Armor Break Indicator'
local hit_enable_desc = 'Activates the Target Armor Hit Indicator'
local type_desc = 'Set the Target Indicator style. Applicable values are: \n\tnone, apex, bdrls, mw1, fnite, mc'
local break_sfx_desc = 'Enables break indicator sounds'
local hit_sfx_desc = 'Enables hit indicator sounds'
local break_icon_desc = 'Enables break indicator visual icons'
local hit_icon_desc = 'Enables hit indicator visual icons'
local icon_res_desc = 'Set the resolution of the indicator icon'
local random_desc = "Automatically sets a random style if 'None' value is selected.\n\nWhen enabled, this functionality takes effect immediately on the next map load"

local breakSounds = 
    {
        Sound('target/break/break_apex.ogg'),
        Sound('target/break/break_bdrls.ogg'), 
        Sound('target/break/break_mw1.ogg'),
        Sound('target/break/break_mw2.ogg'),
        Sound('target/break/break_fortnite.ogg'),
        Sound('target/break/break_mc.ogg')
    }

local hitSounds = 
    {
        Sound('target/hit/hit_apex.ogg'),
        Sound('target/hit/hit_bdrls.ogg'), 
        Sound('target/hit/hit_mw1.ogg'),
        Sound('target/hit/hit_mw2.ogg'),
        Sound('target/hit/hit_fortnite.ogg'),
        Sound('target/hit/hit_mc.ogg')
    }

local breakIcons = 
    {
        Material('break/icon_apex.png'),
        Material('break/icon_bdrls.png'),
        Material('break/icon_mw1.png'), 
        Material('break/icon_mw2.png'), 
        Material('break/icon_fortnite.png'),
        Material('break/icon_mc.png')
    }

local hitIcons = 
    {
        Material('hit/icon_apex.png'),
        Material('hit/icon_bdrls.png'),
        Material('hit/icon_mw1.png'), 
        Material('hit/icon_mw2.png'), 
        Material('hit/icon_fortnite.png'),
        Material('hit/icon_mc.png')
    }

local combolist = 
    {
        {'None', 'none'},
        {'Apex Legends', 'apex'},
        {'Borderlands', 'bdrls'},
        {'Call of Duty - Modern Warfare 1', 'mw1'},
        {'Call of Duty - Modern Warfare 2', 'mw2'},
        {'Fortnite', 'fnite'},
        {'Minecraft', 'mc'}
    }

local selectedBreakIcon = nil
local selectedBreakSound = nil
local selectedHitIcon = nil
local selectedHitSound = nil

-- Console Variables initialization
local abi_break_on = CreateConVar('abindicator_target_break_enable','1', {FCVAR_ARCHIVE, FCVAR_USERINFO}, enable_desc)
local abi_hit_on = CreateConVar('abindicator_target_hit_enable', '1', {FCVAR_ARCHIVE, FCVAR_USERINFO}, hit_enable_desc)
local abi_type = CreateConVar('abindicator_target_type', 'none', {FCVAR_ARCHIVE}, type_desc)
local abi_break_vol = CreateConVar('abindicator_target_break_sound', '1', {FCVAR_ARCHIVE}, break_sfx_desc)
local abi_hit_vol = CreateConVar('abindicator_target_hit_sound', '1', {FCVAR_ARCHIVE}, hit_sfx_desc)
local abi_break_icon = CreateConVar('abindicator_target_break_icon', '1', {FCVAR_ARCHIVE}, break_icon_desc)
local abi_hit_icon = CreateConVar('abindicator_target_hit_icon', '1', {FCVAR_ARCHIVE}, hit_icon_desc)
local abi_icon_res = CreateConVar('abindicator_target_icon_res', '192', {FCVAR_ARCHIVE}, icon_res_desc)
local abi_random_on = CreateConVar('abindicator_target_type_random', '1', {FCVAR_ARCHIVE}, random_desc)

-- Working variables
local breakIndicationDrawTime = 0
local hitIndicationDrawTime = 0
local breakIconOpacity = 255
local hitIconOpacity = 255
local iconFXScale = 25 -- In Percentage
local iconFXRes = 0
local noStyle = false

-- Some useful local functions
local function isNil(s) return s == nil or s == '' end
local function loadSavedStyle()
    local tarkey = GetConVar('abindicator_target_type')
    local err404 = true

    if not isNil(tarkey) then
        local key = tarkey:GetString()

        for i = 2, #combolist do
            if key == combolist[i][2] then
                selectedBreakIcon = breakIcons[i - 1]
                selectedBreakSound = breakSounds[i - 1]
                selectedHitIcon = hitIcons[i - 1]
                selectedHitSound = hitSounds[i - 1]
                err404 = false
                break
            end
        end
    end
-- If there is no style found, a random style is generated for user.
    if err404 and abi_random_on:GetBool() then
        math.randomseed(os.time())
        for iter = 1, #combolist do math.random() end
        RunConsoleCommand('abindicator_target_type', combolist[math.random(2, #combolist)][2])
    end
end

--load specific settings--
loadSavedStyle()
--------------------------

hook.Add('PopulateToolMenu', 'TargetArmorIndicatorOptions', function()

    spawnmenu.AddToolMenuOption('Utilities', 'ZachWattz', 'TargetArmorIndicatorOptionsMenu', 'Target Armor Indicator', '', '', function(optionPanel)
        optionPanel:Clear()
        optionPanel:CheckBox('Break Indicator', 'abindicator_target_break_enable')
        optionPanel:ControlHelp(enable_desc)
        optionPanel:CheckBox('Break Sounds', 'abindicator_target_break_sound')
        optionPanel:ControlHelp(break_sfx_desc)
        optionPanel:CheckBox('Break Indicator Icon', 'abindicator_target_break_icon')
        optionPanel:ControlHelp(break_icon_desc)
        optionPanel:Help('====================')
        optionPanel:CheckBox('Hit Indicator', 'abindicator_target_hit_enable')
        optionPanel:ControlHelp(hit_enable_desc)
        optionPanel:CheckBox('Hit Sounds', 'abindicator_target_hit_sound')
        optionPanel:ControlHelp(hit_sfx_desc)
        optionPanel:CheckBox('Hit Indicator Icon', 'abindicator_target_hit_icon')
        optionPanel:ControlHelp(hit_icon_desc)
        optionPanel:Help('====================')

        local indicator_styles = optionPanel:ComboBox('Styles', 'abindicator_target_type')
            indicator_styles:SetSortItems(false)

            for i = 1, #combolist do
                indicator_styles:AddChoice(combolist[i][1], combolist[i][2])
            end

            indicator_styles:AddSpacer()

            indicator_styles.OnSelect = function(self, index, value)
                RunConsoleCommand('abindicator_target_type', combolist[index][2])
                if index != 1 then
                    selectedBreakSound = breakSounds[index - 1]
                    selectedHitSound = hitSounds[index - 1]
                    selectedBreakIcon = breakIcons[index - 1]
                    selectedHitIcon = hitIcons[index - 1]
                    noStyle = false
                else 
                    noStyle = true
                end
            end
        optionPanel:NumSlider('Texture Resolution', 'abindicator_target_icon_res', 192, 256, 0)
        optionPanel:CheckBox('Random Style Picker', 'abindicator_target_type_random')
        optionPanel:ControlHelp(random_desc)
    end )
end )

local function getSelectedRes()
    return math.max(abi_icon_res:GetInt(), 0)
end 

local function getIconRes()
    local selectedRes = getSelectedRes()
    local returnedValue

    if math.floor(iconFXRes) > selectedRes then
        iconFXRes = iconFXRes - 5.5
        returnedValue = iconFXRes
    else
        returnedValue = selectedRes
    end
    
    return returnedValue
end

hook.Add('HUDPaint', 'TargetArmorBrokenIndication', function()
    if breakIndicationDrawTime < CurTime() then
        breakIconOpacity = 255
    return end

    if abi_break_icon:GetBool() and not noStyle and not isNil(selectedBreakIcon) then
        local icon_size = getIconRes()

        surface.SetDrawColor( 255, 255, 255, breakIconOpacity )
        surface.SetMaterial(selectedBreakIcon)
        surface.DrawTexturedRect(ScrW() / 2 - (icon_size - 192) / 2, ScrH() / 2 - (icon_size - 192) / 2, icon_size, icon_size)        

        if math.floor(breakIconOpacity) > 0 then
            breakIconOpacity = math.floor((breakIndicationDrawTime - CurTime() - 0.125) * 255)
        end
    end
    
    shouldPlayHitSound = true
end )

hook.Add('HUDPaint', 'TargetArmorHitIndication', function()
    if hitIndicationDrawTime < CurTime() then 
        hitIconOpacity = 255
    return end

    if abi_hit_icon:GetBool() and not noStyle and not isNil(selectedHitIcon) then
        local icon_size = getIconRes()

        surface.SetDrawColor( 255, 255, 255, hitIconOpacity )
        surface.SetMaterial(selectedHitIcon)
        surface.DrawTexturedRect(ScrW() / 2 - (icon_size - 192) / 2, ScrH() / 2 - (icon_size - 192) / 2, icon_size, icon_size)

        if math.floor(hitIconOpacity) > 0 then
            hitIconOpacity = math.floor((hitIndicationDrawTime - CurTime()) * 255)
        end
    end
end )

net.Receive('ab_armor_broken', function()
    if abi_break_on:GetBool() and not noStyle then
        if abi_break_icon:GetBool() then
            breakIndicationDrawTime = CurTime() + 1.75
            hitIndicationDrawTime = -1
            iconFXRes = getSelectedRes() + getSelectedRes() * (iconFXScale / 100)
        end
        
        if abi_break_vol:GetBool() then
            surface.PlaySound(selectedBreakSound)
        end
    end
end )

net.Receive('ab_armor_hit', function()
    if abi_hit_on:GetBool() and not noStyle then
        if abi_hit_icon:GetBool() then
            hitIndicationDrawTime = CurTime() + 1
            breakIndicationDrawTime = -1
            iconFXRes = getSelectedRes() + getSelectedRes() * (iconFXScale / 100)
        end
        
        if abi_hit_vol:GetBool() then
            surface.PlaySound(selectedHitSound)
        end
    end
end)
