Config = Config or {}

Config.Status = {
    enabled = true,
    updateInterval = 10000,
    saveInterval = 60000,
    decayInterval = 30000,
    maxHunger = 100,
    maxThirst = 100,
    maxStress = 100,
    maxStamina = 100
}

Config.Decay = {
    hungerPerInterval = 2.0,
    thirstPerInterval = 3.0,
    stressPerInterval = 0.5,
    staminaPerInterval = 1.0,
    hungerRunningMultiplier = 1.5,
    thirstRunningMultiplier = 1.5,
    stressCombatMultiplier = 3.0,
    stressDrivingMultiplier = 1.5,
    staminaRunningMultiplier = 2.0,
    staminaSprintingMultiplier = 4.0
}

Config.FoodItems = {
    bread = { hunger = 25, thirst = 0, stress = -5 },
    water = { hunger = 0, thirst = 40, stress = -2 },
    sandwich = { hunger = 35, thirst = 0, stress = -3 },
    burger = { hunger = 50, thirst = 0, stress = -5 },
    pizza = { hunger = 45, thirst = 0, stress = -5 },
    soda = { hunger = 0, thirst = 25, stress = -1 },
    coffee = { hunger = 0, thirst = 15, stress = -10, stamina = 10 },
    beer = { hunger = 0, thirst = -10, stress = -15 },
    wine = { hunger = 0, thirst = -5, stress = -20 },
    whiskey = { hunger = 0, thirst = -15, stress = -25 },
    cigarettes = { hunger = -2, thirst = 0, stress = -20 },
    drug_weed = { hunger = 10, thirst = 5, stress = -30 }
}

Config.StressTriggers = {
    damageTaken = 10.0,
    killerReceived = 25.0,
    highSpeedDriving = 0.5,
    nearMiss = 2.0,
    combat = 5.0,
    weaponDrawn = 1.0,
    policeChase = 3.0
}

Config.ArmorEffects = {
    stressReduction = 0.5,
    staminaReduction = 0.3
}

Config.CriticalThresholds = {
    hunger = 20,
    thirst = 20,
    stress = 80,
    stamina = 20
}

Config.Effects = {
    lowHunger = { speedMalus = 0.1, shakeIntensity = 0.1 },
    lowThirst = { speedMalus = 0.1, shakeIntensity = 0.1 },
    highStress = { aimJitter = 0.2, shakeIntensity = 0.3, speedMalus = 0.05 },
    lowStamina = { speedMalus = 0.3, shakeIntensity = 0.05 }
}
