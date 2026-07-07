Config = Config or {}

Config.HUD = {
    enabled = true,
    updateInterval = 250,
    showMinimap = true,
    showHealth = true,
    showArmor = true,
    showHunger = true,
    showThirst = true,
    showStress = true,
    showStamina = true,
    showSpeed = true,
    showFuel = true,
    showSeatbelt = true,
    showEngine = true,
    showStreetName = true,
    showTime = true,
    showJob = true,
    showMoney = true,
    showVoice = true,
    showRadio = true,
    minimapX = 0.0,
    minimapY = 0.0,
    hudPosition = 'bottom-left'
}

Config.Speedometer = {
    enabled = true,
    showInVehicle = true,
    showOnFoot = false,
    speedUnit = 'kmh',
    maxSpeed = 300,
    mphMultiplier = 2.23694,
    kmhMultiplier = 3.6
}

Config.Fuel = {
    enabled = true,
    showInVehicle = true,
    lowFuelThreshold = 15,
    criticalFuelThreshold = 5,
    lowFuelWarning = 'Low fuel: %s%%',
    criticalFuelWarning = 'CRITICAL FUEL: %s%%'
}

Config.Seatbelt = {
    enabled = true,
    detectionInterval = 500,
    disableDamage = true,
    ejectOnCrash = true,
    ejectSpeedThreshold = 50.0,
    soundEnabled = true,
    soundName = 'seatbelt',
    warningInterval = 5000,
    warningMessage = '~r~You are not wearing a seatbelt!'
}

Config.Status = {
    hungerDecreaseRate = 0.02,
    thirstDecreaseRate = 0.03,
    stressIncreaseRate = 0.01,
    staminaDecreaseRate = 0.05,
    maxHunger = 100,
    maxThirst = 100,
    maxStress = 100,
    maxStamina = 100
}

Config.Money = {
    showCash = true,
    showBank = true,
    showCrypto = false,
    format = 'short'
}

Config.Colors = {
    health = { r = 255, g = 50, b = 50 },
    armor = { r = 50, g = 150, b = 255 },
    hunger = { r = 255, g = 200, b = 50 },
    thirst = { r = 50, g = 150, b = 255 },
    stress = { r = 200, b = 50, g = 50 },
    stamina = { r = 50, g = 255, b = 50 },
    fuel = { r = 255, g = 255, b = 50 },
    speed = { r = 255, g = 255, b = 255 },
    taxi = { r = 255, g = 200, b = 0 },
    mechanic = { r = 0, g = 100, b = 255 },
    police = { r = 50, b = 200, g = 50 }
}
