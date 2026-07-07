Config = Config or {}
Config.AdvancedTrauma = Config.AdvancedTrauma or {}

Config.AdvancedTrauma = {
  autopsy = { enabled = true, allowedJobs = { 'ambulance', 'police', 'cid' } },
  addiction = {
    enabled = true,
    substances = {
      meth = { label = 'Methamphetamine', dependencyRate = 5, withdrawalDebuffs = { tremor = true, staminaDrain = 2, healthDecay = 1 } },
      cocaine = { label = 'Cocaine', dependencyRate = 4, withdrawalDebuffs = { tremor = false, staminaDrain = 3, healthDecay = 0.5 } },
      heroin = { label = 'Heroin', dependencyRate = 8, withdrawalDebuffs = { tremor = true, staminaDrain = 5, healthDecay = 3 } },
      morphine = { label = 'Morphine', dependencyRate = 3, withdrawalDebuffs = { tremor = false, staminaDrain = 1, healthDecay = 0.3 } },
    },
    checkInterval = 300,
  },
  vectorPathogens = {
    enabled = true,
    diseases = {
      flu = { label = 'Influenza', transmissionChance = 0.3, cureItem = 'flu_medicine', debuff = { staminaDrain = 2 } },
      infection = { label = 'Wound Infection', transmissionChance = 0.1, cureItem = 'antibiotics', debuff = { healthDecay = 1 } },
    }
  },
  bloodBank = { enabled = true, types = { 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-' } },
  firePropagation = { enabled = true, spreadRate = 5.0, maxRadius = 20.0 },
  prosthetics = { enabled = true, recoveryTime = 7200 },
  medevac = { enabled = true, radarRange = 100.0 },
  toxicology = { enabled = true },
  amnesia = { enabled = true, duration = 300 },
  fieldKits = { enabled = true, maxKitsPerPlayer = 2, restockItems = { 'bandage', 'painkillers', 'splint', 'antiseptic' } },
  rateLimits = { autopsy = 3, diagnose = 5, restock = 3 }
}
