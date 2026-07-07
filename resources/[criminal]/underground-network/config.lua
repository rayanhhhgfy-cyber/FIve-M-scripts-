Config = Config or {}
Config.Underground = Config.Underground or {}

Config.Underground = {
  borderSmuggling = {
    enabled = true, interval = 3600, zones = {
      { coords = vector3(2400.0, 4800.0, 35.0), label = 'Grapeseed Air-Drop' },
      { coords = vector3(-1700.0, -3000.0, 15.0), label = 'Coastal Drop Zone' },
    }
  },
  mobileLabs = {
    enabled = true, rvModels = { 'rumpo', 'rumpo2', 'speedo', 'speedo2', 'burrito3', 'gburrito2' },
    maxVelocityForSafety = 5.0, explosionChanceOnCrash = 0.3
  },
  frontLaundering = {
    enabled = true, businesses = { 'car_wash', 'laundromat', 'convenience_store' },
    cleanRate = 0.1, payoutInterval = 600
  },
  surveillanceCams = { enabled = true, maxCamsPerPlayer = 5, camRange = 50.0 },
  hostageShells = { enabled = true, explosionRadius = 5.0, damage = 200 },
  atmSkimmers = { enabled = true, interceptRate = 0.05 },
  gangRenown = { enabled = true, xpPerRobbery = 100, xpPerTurf = 50, levels = { 1, 2, 3, 4, 5 } },
  blackMarket = { enabled = true, taxRate = 0.15 },
  prisonBreakout = { enabled = true, searchlightDuration = 30, gateC4Required = 2 },
  npcInterrogations = { enabled = true, complianceChance = 0.4 },
  rateLimits = { smash = 5, deployCamera = 3, skinATM = 2, interrogate = 5 }
}
