-- Script meant to run on Client only!
if SERVER then return end


--- Separated rendering functions for Vignette FOV
--- Declares working variables.
local lastExecTime = 0
local overlayOpacityRatio = 1
local zoomRatio = -0.1
local maxZoomRatioBound = 0.1
local effectDuration = 2 -- in secs!
local vignetteZoomStart = effectDuration * 1
local vignetteZoomStop = effectDuration * 0.625


-- Resource retrieval
local vignetteOverlay = Material('zw_hud/player/vignette_overlay.png')
if vignetteOverlay == nil then error('Graphics resource for "Vignette FOV" cannot be found') return end
local resWidth = vignetteOverlay:Width()
local resHeight = vignetteOverlay:Height()

--- Locally used functions (not shared with others).
local function reset()
    lastExecTime = 0
    overlayOpacityRatio = 1
    zoomRatio = -0.1
end


--- Engages the concussion indication effect.
function ZWASI_EngageVignetteFOV()
    hook.Add('HUDPaint', 'ZWASI_PlayerOnBrokenVignetteFOV', function()
        local timeDiff = lastExecTime - CurTime()
        
        -- Exits function
        if timeDiff < 0 then return end
        if timeDiff <= effectDuration * 0.375 and timeDiff >= 0 then
            overlayOpacityRatio = timeDiff - (1 / effectDuration * 0.375)
        end


        if timeDiff <= vignetteZoomStart and timeDiff >= vignetteZoomStop then
            zoomRatio = maxZoomRatioBound * math.sin(math.pi * timeDiff + math.pi / 2) - maxZoomRatioBound
        elseif timeDiff < vignetteZoomStop then
            zoomRatio = zoomRatio - 0.1
        end
        
        surface.SetDrawColor(255, 255, 255, 255 * overlayOpacityRatio)
        surface.SetMaterial(vignetteOverlay)
        surface.DrawTexturedRect(
            resWidth * zoomRatio,
            resHeight * zoomRatio,
            ScrW() - resWidth * zoomRatio * 2,
            ScrH() - resHeight * zoomRatio * 2
        )
    end)
end


--- Disengages the concussion indication effect.
function ZWASI_DisengageVignetteFOV()
    hook.Remove('HUDPaint', 'ZWASI_PlayerOnBrokenVignetteFOV')
    reset()
end


--- Triggers the concussion indication effect
function ZWASI_TriggerVignetteFOV()
    reset()
    lastExecTime = CurTime() + effectDuration
end

