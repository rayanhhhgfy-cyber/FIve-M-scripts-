Config = Config or {}

Config.YachtHeist = {
    MinPolice = 5,
    Cooldown = 1800,
    PoliceAlertChance = 0.85,

    Yacht = {
        coords = vector3(-2045.0, -1032.0, 1.0),
        interior = vector3(-2045.0, -1032.0, 10.0),
        label = 'Galaxy Yacht',
        model = 'gabz_yacht_sm'
    },

    Stealth = {
        detectionRadius = 8.0,
        disguiseItem = 'security_uniform',
        noiseThreshold = 0.3,
        guardSightline = 30.0
    },

    Guards = {
        count = { min = 4, max = 8 },
        models = { 's_m_m_security_01', 's_m_y_swat_01' },
        weapons = { 'WEAPON_PISTOL', 'WEAPON_STUNGUN' },
        respawnTime = 120
    },

    Vault = {
        coords = vector3(-2045.0, -1032.0, 8.0),
        hackTime = 20000,
        crackTime = 30000,
        cash = { min = 25000, max = 60000 },
        valuableItems = { 'gold_bar', 'diamond_necklace', 'rare_coin', 'gold_watch', 'painting' },
        itemCount = { min = 3, max = 6 }
    },

    GuestRooms = {
        count = 6,
        searchTime = 5000,
        loot = { cash = { min = 500, max = 2000 }, items = { 'phone', 'gold_chain', 'tablet', 'usb_drive' } }
    },

    Alarm = {
        triggered = false,
        autoTriggerTime = 600,
        panels = 3
    },

    TargetOptions = {
        sneakOnboard = { icon = 'fas fa-ship', label = 'Sneak Onboard', distance = 3.0 },
        pickpocket = { icon = 'fas fa-user-secret', label = 'Pickpocket Guest', distance = 1.5 },
        searchRoom = { icon = 'fas fa-door-open', label = 'Search Guest Room', distance = 1.5 },
        hackVault = { icon = 'fas fa-laptop', label = 'Hack Vault Terminal', distance = 1.5 },
        crackSafe = { icon = 'fas fa-vault', label = 'Crack Safe', distance = 1.5 },
        lootVault = { icon = 'fas fa-hand', label = 'Take Valuables', distance = 1.5 },
        disableAlarm = { icon = 'fas fa-shield', label = 'Disable Alarm Panel', distance = 1.5 }
    }
}
