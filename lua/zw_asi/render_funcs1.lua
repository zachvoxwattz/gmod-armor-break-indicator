-- Script meant to run on Client only!
if SERVER then return end


--- Separated rendering functions for Concussion FX
--- Declares working variables.
local lastExecTime = 0
local vfxSpeed = 0.075


--- Locally used functions (not shared with others).
local function reset()
    lastExecTime = 0
    vfxSpeed = 0.075
end


--- Engages the concussion indication effect.
function ZWASI_EngageConcussionFX()
    hook.Add('RenderScreenspaceEffects', 'ZWASI_PlayerOnBrokenConcussionFX', function()
        if lastExecTime < CurTime() then return end

        DrawMotionBlur( vfxSpeed, 10, 0.01 )
        if vfxSpeed <= 1 then
            vfxSpeed = vfxSpeed + 0.00375
        end
    end )
    

    hook.Add('HUDPaint', 'ZWASI_PlayerOnBrokenConcussionBlindness', function()
        surface.SetDrawColor(255, 255, 255, ( lastExecTime - CurTime() - 1.75 ) * 255)
        surface.DrawRect(0, 0, ScrW(), ScrH())
    end )
end


--- Disengages the concussion indication effect.
function ZWASI_DisengageConcussionFX()
    hook.Remove('RenderScreenspaceEffects', 'ZWASI_PlayerOnBrokenConcussionFX')
    hook.Remove('HUDPaint', 'ZWASI_PlayerOnBrokenConcussionBlindness')
    reset()
end


--- Triggers the concussion indication effect
function ZWASI_TriggerConcussionFX()
    reset()
    lastExecTime = CurTime() + 2.5
end
