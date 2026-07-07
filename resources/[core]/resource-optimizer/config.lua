Config = Config or {}

Config.Optimizer = {
    enabled = true,
    gcInterval = 60000,
    reportInterval = 300000,
    threadPriority = 'low',
    maxThreadSleep = 100
}

Config.GarbageCollection = {
    collectOnInterval = true,
    interval = 60000,
    collectOnResourceStop = true,
    collectOnPlayerDrop = true
}

Config.EntityLimits = {
    maxVehicles = 250,
    maxPeds = 150,
    maxObjects = 500,
    maxProps = 200,
    cleanupInterval = 180000
}

Config.MemoryThresholds = {
    warningMB = 1024,
    criticalMB = 1536,
    actionMB = 2048
}

Config.ThreadProfiling = {
    enabled = true,
    logSlowThreads = true,
    slowThreshold = 50,
    sampleInterval = 10000
}

Config.ClientOptimizations = {
    disableDistanceShadows = true,
    shadowDistance = 50.0,
    lodScale = 1.0,
    grassDistance = 0.0,
    textureQuality = 2,
    waterQuality = 1,
    particleQuality = 1,
    extendedDistanceScaling = 0.5,
    maxAnisotropy = 4,
    reflectionQuality = 1,
    ssaoEnabled = false,
    msaa = 0,
    fxaaEnabled = true
}

Config.ScheduledCleanup = {
    interval = 300000,
    abandonedVehicleAge = 600000,
    abandonedPedAge = 300000,
    abandonedPropAge = 600000
}
