Config = Config or {}

Config.Prison = {
    Location = vector3(1690.0, 2550.0, 45.0),
    SpawnPoint = { coords = vector3(1697.0, 2540.0, 45.5), heading = 180.0 },
    ReleasePoint = { coords = vector3(1850.0, 2585.0, 45.0), heading = 0.0 },
    LaborPoints = {
        { coords = vector3(1650.0, 2520.0, 45.0), label = 'Quarry', rewardPerMin = 10 },
        { coords = vector3(1620.0, 2480.0, 45.0), label = 'Road Work', rewardPerMin = 8 },
        { coords = vector3(1710.0, 2590.0, 45.0), label = 'Yard Duty', rewardPerMin = 5 }
    },
    GuardZones = {
        { coords = vector3(1670.0, 2530.0, 45.0), radius = 100.0 },
        { coords = vector3(1620.0, 2480.0, 45.0), radius = 80.0 }
    },
    BreakTime = 300,
    MaxLaborTime = 240,
    BaseTimeReductionRatio = 2,
    GuardMinRank = 2,
    StrippedItems = { 'WEAPON_PISTOL', 'WEAPON_KNIFE', 'phone', 'radio' },
    PrisonBlip = { coords = vector3(1690.0, 2550.0, 45.0), sprite = 188, color = 1, scale = 1.0, label = 'Bolingbroke Penitentiary' },

    TargetOptions = {
        labor = { icon = 'fas fa-hammer', label = 'Start Prison Labor', distance = 2.5 },
        release = { icon = 'fas fa-door-open', label = 'Release Prisoner', group = 'police', distance = 2.0, minRank = 2 },
        guard = { icon = 'fas fa-shield-alt', label = 'Guard Duty', group = 'police', distance = 2.0, minRank = 2 }
    }
}
