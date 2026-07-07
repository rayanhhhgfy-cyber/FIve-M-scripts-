local function ApplyClientOptimizations()
    if not Config.Optimizer.enabled then return end
    local opt = Config.ClientOptimizations
    if opt.disableDistanceShadows then
        CascadeshadowsClear() -- Clear all cascade shadow data
        CascadeshadowsSetMaximumDistance(opt.shadowDistance)
        CascadeshadowsSetCascadeBounds(opt.shadowDistance, opt.shadowDistance * 0.5, opt.shadowDistance * 0.25)
    end
    SetStreamedTextureDictAsNoLongerNeeded('LOD')
    if opt.lodScale then
        SetLodScale(opt.lodScale)
    end
    SetGrassDistance(opt.grassDistance)
    SetTextureQuality(opt.textureQuality)
    SetWaterQuality(opt.waterQuality)
    SetParticleQuality(opt.particleQuality)
    SetExtendedDistanceScaling(opt.extendedDistanceScaling)
    SetMaxAnisotropy(opt.maxAnisotropy)
    SetReflectionQuality(opt.reflectionQuality)
    if not opt.ssaoEnabled then
        SetArtficialLightsLmsEnabled(false)
        SetSsaoEnabled(false)
    end
    SetMsaaLevel(opt.msaa)
    SetFxaaEnabled(opt.fxaaEnabled)
end

Citizen.CreateThread(function()
    Citizen.Wait(5000)
    ApplyClientOptimizations()
    print('^2[optimizer] Client optimizations applied.^7')
end)

RegisterCommand('fpsboost', function()
    ApplyClientOptimizations()
    Wrappers.Notify({ type = 'success', description = 'FPS optimizations applied' })
end, false)

exports('ApplyOptimizations', ApplyClientOptimizations)
