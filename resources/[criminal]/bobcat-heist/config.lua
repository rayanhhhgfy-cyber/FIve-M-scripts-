Config = Config or {}

Config.BobcatHeist = {
    MinPolice = 5,
    Cooldown = 3600,
    PoliceAlertChance = 0.90,

    Location = {
        coords = vector3(720.0, -970.0, 24.0),
        label = 'Bobcat Security Depot',
        interior = vector3(720.0, -970.0, 24.0)
    },

    Gates = {
        { coords = vector3(720.0, -970.0, 24.0), model = 'prop_gate_airport_01', requiredItem = 'thermite', time = 12000, label = 'Main Gate' },
        { coords = vector3(725.0, -975.0, 24.0), model = 'prop_gate_airport_01', requiredItem = 'thermite', time = 12000, label = 'Inner Gate' },
        { coords = vector3(730.0, -980.0, 24.0), model = 'prop_gate_airport_01', requiredItem = 'thermite', time = 12000, label = 'Storage Gate' }
    },

    Lootables = {
        { coords = vector3(720.0, -960.0, 24.0), label = 'Weapons Crate', type = 'weapons', time = 6000,
          items = { 'WEAPON_PISTOL', 'WEAPON_SMG', 'WEAPON_CARBINERIFLE', 'WEAPON_SHOTGUN' }, cash = { min = 1000, max = 3000 } },
        { coords = vector3(725.0, -965.0, 24.0), label = 'Medical Supplies', type = 'medical', time = 5000,
          items = { 'bandage', 'firstaid', 'painkillers' }, cash = { min = 500, max = 2000 } },
        { coords = vector3(730.0, -970.0, 24.0), label = 'Valuables Cache', type = 'valuables', time = 8000,
          items = { 'gold_bar', 'diamond_ring', 'gold_watch' }, cash = { min = 3000, max = 8000 } },
        { coords = vector3(715.0, -955.0, 24.0), label = 'Electronics', type = 'electronics', time = 6000,
          items = { 'phone', 'tablet', 'usb_drive', 'hacking_device' }, cash = { min = 1000, max = 4000 } }
    },

    Security = {
        cameras = 4,
        cameraTime = 8000,
        guards = { count = { min = 2, max = 4 }, models = { 's_m_m_security_01' } }
    },

    Escape = {
        vehicleSpawn = vector3(710.0, -940.0, 24.0),
        timeout = 300
    },

    RequiredItems = {
        thermite = 'Thermite',
        hackingDevice = 'Hacking Device',
        boltCutters = 'Bolt Cutters'
    },

    TargetOptions = {
        gate = { icon = 'fas fa-fire', label = 'Burn Gate', distance = 2.0 },
        loot = { icon = 'fas fa-box-open', label = 'Loot Container', distance = 1.5 },
        camera = { icon = 'fas fa-video', label = 'Disable Camera', distance = 2.0 },
        hack = { icon = 'fas fa-microchip', label = 'Hack Terminal', distance = 1.5 }
    }
}
