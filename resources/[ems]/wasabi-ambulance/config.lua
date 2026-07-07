Config = Config or {}

Config.Ambulance = {
    jobName = 'ambulance',
    reviveTime = 10000,
    respawnTime = 30000,
    maxDownsBeforeDeath = 3,
    downTimer = 600000,
    bleedoutTime = 300000,
    hospitalBills = true,
    billAmount = 5000,
    allowRevive = true,
    allowDrag = true,
    allowStretcher = true,
    allowBedHeal = true,
    emsCountForAutoRevive = 1,
    autoReviveTime = 120000
}

Config.DownStates = {
    injured = { label = 'Injured', canMove = true, canUseItems = true, canSpeak = true },
    critical = { label = 'Critical', canMove = false, canUseItems = false, canSpeak = false },
    dying = { label = 'Bleeding Out', canMove = false, canUseItems = false, canSpeak = false, bleedoutTime = 120000 },
    dead = { label = 'Deceased', canMove = false, canUseItems = false, canSpeak = false }
}

Config.RevivalMethods = {
    defibrillator = { time = 8000, successRate = 0.85, item = 'defibrillator' },
    cpr = { time = 15000, successRate = 0.40 },
    hospital_bed = { time = 20000, successRate = 1.0 },
    medic_kit = { time = 10000, successRate = 0.65, item = 'medic_kit' },
    painkillers = { time = 5000, successRate = 0.25, item = 'painkillers' }
}

Config.RespawnLocations = {
    { name = 'Pillbox Hill', coords = { x = 300.0, y = -580.0, z = 43.0 } },
    { name = 'Sandy Shores Medical', coords = { x = 1850.0, y = 3680.0, z = 34.0 } },
    { name = 'Paleto Bay Medical', coords = { x = -250.0, y = 6320.0, z = 31.0 } }
}

Config.DamageStates = {
    head = { label = 'Head Trauma', effects = { blur = true, shake = true } },
    torso = { label = 'Chest Injury', effects = { breath = true } },
    left_arm = { label = 'Left Arm Fracture', effects = { aim = true } },
    right_arm = { label = 'Right Arm Fracture', effects = { aim = true } },
    left_leg = { label = 'Left Leg Fracture', effects = { limp = true } },
    right_leg = { label = 'Right Leg Fracture', effects = { limp = true } }
}

Config.Bleeding = {
    enabled = true,
    levels = { 'light', 'moderate', 'severe', 'critical' },
    damagePerTick = { light = 0.5, moderate = 1.5, severe = 3.0, critical = 5.0 },
    tickInterval = 5000,
    bandageStops = 'light',
    medicKitStops = 'moderate',
    surgeryStops = 'critical',
    tourniquetTime = 60000
}
