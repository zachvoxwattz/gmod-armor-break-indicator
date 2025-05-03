--- Separated rendering functions for Impulse circle
--- Declares working variables.
local lastCircleExecTime = 0
local lastScreenExecTime = 0
local circleDisplayTime = 0.75 -- in seconds.
local circleZoomRatio = 0.5
local screenDisplayTime = 2 -- in seconds
local screenDisplayOpacity = 1

-- Resource retrieval
local circleGraphics = Material('zw_hud/player/impulse_circle.png')
if circleGraphics == nil then error('Graphics resource for "Impulse Circle" (the circle) cannot be found') return end
local circleSideLength = circleGraphics:Width()

local screenDisplayOverlay = Material('zw_hud/player/impulse_circle_screen.png')
if screenDisplayOverlay == nil then error('Graphics resource for "Impulse Circle" (the screen) cannot be found') return end

--- Locally used functions (not shared with others).
local function reset()
    lastCircleExecTime = 0
    lastScreenExecTime = 0
    circleZoomRatio = 1
    screenDisplayOpacity = 1
end


--- Engages the impulse circle HUD display.
function ZWASI_EngageImpulseCircleHUD()
    hook.Add('HUDPaint', 'ZWASI_PlayerOnBrokenImpulseCircleHUD', function()
        local timeDiffCircle = lastCircleExecTime - CurTime()
        
        -- Exits function
        if timeDiffCircle < 0 then return end
        if timeDiffCircle <= circleDisplayTime and timeDiffCircle >= 0 then
            circleZoomRatio = circleZoomRatio + 0.25
        end 
        
        surface.SetDrawColor(255, 255, 255)
        surface.SetMaterial(circleGraphics)
        surface.DrawTexturedRect(
            (ScrW() - (circleSideLength * circleZoomRatio)) / 2,
            (ScrH() - (circleSideLength * circleZoomRatio)) / 2,
            circleSideLength * circleZoomRatio,
            circleSideLength * circleZoomRatio
        )
    end)

    hook.Add('HUDPaint', 'ZWASI_PlayerOnBrokenImpulseCircleBG', function()
        local timeDiffScreen = lastScreenExecTime - CurTime()
        
        -- Exits function
        if timeDiffScreen < 0 then return end

        if timeDiffScreen < screenDisplayTime * 0.5 then
            screenDisplayOpacity = screenDisplayOpacity - 0.1
        end
        
        surface.SetDrawColor(0, 144, 255, 255 * screenDisplayOpacity)
        surface.SetMaterial(screenDisplayOverlay)
        surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
    end)

    hook.Add('RenderScreenspaceEffects', 'ZWASI_PlayerOnBrokenImpulseCircleVFX', function()
        local timeDiffScreen = lastScreenExecTime - CurTime()
        
        -- Exits function
        if timeDiffScreen < 0 then return end
        DrawMotionBlur(0.4, 0.8, 0.01)
    end )
end


--- Disengages the impulse circle HUD display.
function ZWASI_DisengageImpulseCircleHUD()
    hook.Remove('HUDPaint', 'ZWASI_PlayerOnBrokenImpulseCircleHUD')
    hook.Remove('HUDPaint', 'ZWASI_PlayerOnBrokenImpulseCircleBG')
    hook.Remove('RenderScreenspaceEffects', 'ZWASI_PlayerOnBrokenImpulseCircleVFX')
    reset()
end


--- Triggers the impulse circle HUD display.
function ZWASI_TriggerImpulseCircleHUD()
    reset()
    lastCircleExecTime = CurTime() + circleDisplayTime
    lastScreenExecTime = CurTime() + screenDisplayTime
end

