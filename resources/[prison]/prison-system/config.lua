Config = Config or {}
Config.Prison = {
    interior = {
        enter = vector3(1695.0, 2580.0, 46.0),
        exit = vector3(1845.0, 2585.0, 46.0),
        cellBlock = vector3(1760.0, 2550.0, 46.0),
        yard = vector3(1710.0, 2620.0, 46.0),
        cafeteria = vector3(1790.0, 2530.0, 46.0),
        infirmary = vector3(1820.0, 2500.0, 46.0),
        wardenOffice = vector3(1695.0, 2500.0, 46.0),
    },
    inmateJobs = {
        { id = 'laundry', name = 'Laundry Duty', pay = 25, duration = 60000, coords = vector3(1760.0, 2520.0, 46.0) },
        { id = 'kitchen', name = 'Kitchen Duty', pay = 30, duration = 60000, coords = vector3(1790.0, 2530.0, 46.0) },
        { id = 'cleaning', name = 'Cell Block Cleanup', pay = 20, duration = 45000, coords = vector3(1760.0, 2550.0, 46.0) },
        { id = 'library', name = 'Library Sorting', pay = 15, duration = 30000, coords = vector3(1740.0, 2560.0, 46.0) },
    },
    contraband = {
        { id = 'shank', name = 'Shank', item = 'weapon_switchblade', risk = 'high', smugglerPrice = 500 },
        { id = 'phone', name = 'Cell Phone', item = 'phone', risk = 'medium', smugglerPrice = 1000 },
        { id = 'smokes', name = 'Cigarettes', item = 'cigarette', risk = 'low', smugglerPrice = 200 },
        { id = 'booze', name = 'Prison Wine', item = 'alcohol', risk = 'low', smugglerPrice = 300 },
        { id = 'drugs', name = 'Narcotics', item = 'drug_bag', risk = 'high', smugglerPrice = 2000 },
    },
    breakout = {
        methods = {
            tunnel = { name = 'Tunnel Escape', preparation = 300000, risk = 'medium', toolRequired = 'shovel' },
            truck = { name = 'Supply Truck', preparation = 600000, risk = 'high', toolRequired = 'lockpick' },
            diversion = { name = 'Create Diversion', preparation = 120000, risk = 'low', toolRequired = nil },
        },
        manhuntDuration = 600, -- seconds
        manhuntRadius = 5000.0,
    },
    guardJob = 'police',
    sentenceReductionPerJob = 60, -- seconds per job completed
    adminGroups = { 'admin', 'superadmin', 'god' },
}
