Config = Config or {}

Config.Pillbox = {
    enabled = true,
    loadIPLs = true,
    enableInterior = true
}

Config.IPLs = {
    'plg_hospital',
    'plg_hospital_entrance',
    'plg_hospital_er',
    'plg_hospital_surgery',
    'plg_hospital_icu',
    'plg_hospital_pharmacy',
    'plg_hospital_morgue',
    'plg_hospital_admin',
    'plg_hospital_lab',
    'plg_hospital_radiology'
}

Config.InteriorZones = {
    emergency_room = {
        label = 'Emergency Room',
        coords = { x = 300.0, y = -580.0, z = 43.0 },
        radius = 15.0,
        beds = 5
    },
    surgery = {
        label = 'Surgery Wing',
        coords = { x = 320.0, y = -560.0, z = 43.0 },
        radius = 10.0,
        beds = 2
    },
    icu = {
        label = 'Intensive Care',
        coords = { x = 340.0, y = -570.0, z = 43.0 },
        radius = 8.0,
        beds = 4
    },
    radiology = {
        label = 'Radiology',
        coords = { x = 315.0, y = -590.0, z = 43.0 },
        radius = 8.0
    },
    pharmacy = {
        label = 'Pharmacy',
        coords = { x = 295.0, y = -575.0, z = 43.0 },
        radius = 5.0
    },
    morgue = {
        label = 'Morgue',
        coords = { x = 280.0, y = -590.0, z = 43.0 },
        radius = 10.0
    },
    reception = {
        label = 'Reception',
        coords = { x = 305.0, y = -595.0, z = 43.0 },
        radius = 5.0
    }
}

Config.InteriorPortals = {
    { name = 'Main Entrance', coords = { x = 295.0, y = -600.0, z = 43.0 }, interior = 'emergency_room' },
    { name = 'Surgery Door', coords = { x = 325.0, y = -565.0, z = 43.0 }, interior = 'surgery' },
    { name = 'ICU Door', coords = { x = 345.0, y = -575.0, z = 43.0 }, interior = 'icu' },
    { name = 'Radiology Door', coords = { x = 310.0, y = -595.0, z = 43.0 }, interior = 'radiology' },
    { name = 'Morgue Door', coords = { x = 275.0, y = -595.0, z = 43.0 }, interior = 'morgue' }
}

Config.HealingZones = {
    { coords = { x = 300.0, y = -580.0, z = 43.0 }, radius = 2.0, label = 'ER Bed' },
    { coords = { x = 310.0, y = -580.0, z = 43.0 }, radius = 2.0, label = 'ER Bed' },
    { coords = { x = 320.0, y = -580.0, z = 43.0 }, radius = 2.0, label = 'ER Bed' },
    { coords = { x = 330.0, y = -570.0, z = 43.0 }, radius = 2.0, label = 'ICU Bed' },
    { coords = { x = 340.0, y = -570.0, z = 43.0 }, radius = 2.0, label = 'ICU Bed' }
}
