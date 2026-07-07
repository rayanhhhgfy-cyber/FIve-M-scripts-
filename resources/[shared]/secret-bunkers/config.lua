Config = Config or {}
Config.SecretBunkers = Config.SecretBunkers or {}

Config.SecretBunkers = {
    adminGroups = { 'admin', 'superadmin', 'god' },
    maxDistance = 5.0,
    rockSlideDuration = 2500,
    rockSlideDistance = 6.0,

    interiors = {
        { name = 'hei_sm_15_planning_room', load = { 'hei_sm_15_planning_room' }, unload = { 'hei_sm_15_planning_room' } },
        { name = 'hei_sm_16_planning_room', load = { 'hei_sm_16_planning_room' }, unload = { 'hei_sm_16_planning_room' } },
        { name = 'sm_15_planning_room_02', load = { 'sm_15_planning_room_02' }, unload = { 'sm_15_planning_room_02' } },
        { name = 'gr_case13_bunker', load = { 'gr_case13_bunker' }, unload = { 'gr_case13_bunker' } },
        { name = 'v_abattoir', load = { 'v_abattoir' }, unload = { 'v_abattoir' } },
        { name = 'hei_hangar_int', load = { 'hei_hangar_int' }, unload = { 'hei_hangar_int' } },
    },

    vehicleCategories = {
        helicopters = {
            label = 'Helicopters',
            icon = 'helicopter',
            vehicles = {
                { model = 'buzzard', label = 'Buzzard Attack', speed = 180, seats = 2 },
                { model = 'frogger', label = 'Frogger Transport', speed = 165, seats = 4 },
                { model = 'seasparrow', label = 'Sea Sparrow', speed = 170, seats = 2 },
                { model = 'havok', label = 'Havok Mini', speed = 190, seats = 2 },
            }
        },
        armored = {
            label = 'Armored Vehicles',
            icon = 'car',
            vehicles = {
                { model = 'nightshark', label = 'Nightshark', speed = 160, seats = 4 },
                { model = 'insurgent', label = 'Insurgent', speed = 155, seats = 6 },
                { model = 'patriot2', label = 'Patriot Stretch', speed = 145, seats = 6 },
                { model = 'dubsta3', label = 'Dubsta 6x6', speed = 140, seats = 4 },
                { model = 'speedo4', label = 'Armored Speedo', speed = 135, seats = 6 },
            }
        },
        sports = {
            label = 'Sports & Exotics',
            icon = 'car',
            vehicles = {
                { model = 'adder', label = 'Adder', speed = 240, seats = 2 },
                { model = 'nero', label = 'Nero', speed = 235, seats = 2 },
                { model = 'thrax', label = 'Thrax', speed = 225, seats = 2 },
                { model = 'pariah', label = 'Pariah', speed = 245, seats = 2 },
                { model = 'torero2', label = 'Torero XO', speed = 240, seats = 2 },
            }
        },
        offroad = {
            label = 'Off-Road',
            icon = 'car',
            vehicles = {
                { model = 'kamacho', label = 'Kamacho', speed = 155, seats = 4 },
                { model = 'trophy2', label = 'Trophy Truck', speed = 175, seats = 2 },
                { model = 'blazer', label = 'Blazer ATV', speed = 120, seats = 2 },
                { model = 'sanctus', label = 'Sanctus Bike', speed = 185, seats = 1 },
            }
        },
        boats = {
            label = 'Boats',
            icon = 'car',
            vehicles = {
                { model = 'speeder', label = 'Speeder', speed = 140, seats = 4 },
                { model = 'toro', label = 'Toro', speed = 135, seats = 6 },
                { model = 'dinghy', label = 'Dinghy', speed = 130, seats = 4 },
                { model = 'seashark', label = 'Seashark Jet Ski', speed = 120, seats = 2 },
            }
        },
    },

    locations = {
        del_perro = {
            id = 'del_perro_bunker',
            label = 'Del Perro Bunker',
            entrance = {
                coords = vector3(-1580.0, -575.0, 107.5),
                heading = 180.0,
                rocks = {
                    { model = 'prop_rock_4_b', coords = vector3(-1582.5, -574.0, 107.0), heading = 0.0, slideDir = vector3(-4.0, 0.0, 0.0) },
                    { model = 'prop_rock_4_c', coords = vector3(-1577.5, -576.0, 107.0), heading = 45.0, slideDir = vector3(4.0, 0.0, 0.0) },
                    { model = 'prop_rock_3_b', coords = vector3(-1580.0, -577.5, 106.5), heading = 90.0, slideDir = vector3(0.0, -4.0, 0.0) },
                },
            },
            interior = {
                coords = vector3(128.0, -130.0, 58.0),
                heading = 90.0,
                vehicleSpawn = { coords = vector3(124.0, -132.0, 57.5), heading = 90.0 },
                droneSpawn = { coords = vector3(126.0, -126.0, 59.0), heading = 0.0 },
                exit = { coords = vector3(131.0, -130.0, 58.0), heading = 270.0 },
            },
            interiorName = 'hei_sm_15_planning_room',
            armory = {
                weapons = {
                    { weapon = 'WEAPON_PISTOL50', label = 'Pistol .50', rank = 0 },
                    { weapon = 'WEAPON_SMG', label = 'SMG', rank = 1 },
                    { weapon = 'WEAPON_ASSAULTRIFLE', label = 'Assault Rifle', rank = 2 },
                    { weapon = 'WEAPON_HEAVYSNIPER', label = 'Heavy Sniper', rank = 3 },
                    { weapon = 'WEAPON_COMBATPDW', label = 'Combat PDW', rank = 1 },
                },
                ammo = {
                    { item = 'pistol_ammo', label = 'Pistol Ammo', count = 50 },
                    { item = 'rifle_ammo', label = 'Rifle Ammo', count = 100 },
                    { item = 'smg_ammo', label = 'SMG Ammo', count = 80 },
                    { item = 'sniper_ammo', label = 'Sniper Ammo', count = 20 },
                },
                equipment = {
                    { item = 'armor', label = 'Body Armor' },
                    { item = 'grenade', label = 'Grenade' },
                    { item = 'handcuffs', label = 'Handcuffs' },
                    { item = 'breaching_charge', label = 'Breaching Charge' },
                }
            },
        },
        paleto_bay = {
            id = 'paleto_bay_bunker',
            label = 'Paleto Bay Bunker',
            entrance = {
                coords = vector3(-105.0, 6595.0, 29.5),
                heading = 0.0,
                rocks = {
                    { model = 'prop_rock_4_b', coords = vector3(-107.5, 6593.0, 29.0), heading = 90.0, slideDir = vector3(0.0, -4.0, 0.0) },
                    { model = 'prop_rock_4_c', coords = vector3(-102.5, 6597.0, 29.0), heading = 135.0, slideDir = vector3(0.0, 4.0, 0.0) },
                    { model = 'prop_rock_3_b', coords = vector3(-105.0, 6592.0, 28.5), heading = 0.0, slideDir = vector3(-4.0, 0.0, 0.0) },
                },
            },
            interior = {
                coords = vector3(132.0, -130.0, 58.0),
                heading = 180.0,
                vehicleSpawn = { coords = vector3(128.0, -132.0, 57.5), heading = 180.0 },
                droneSpawn = { coords = vector3(130.0, -126.0, 59.0), heading = 0.0 },
                exit = { coords = vector3(135.0, -130.0, 58.0), heading = 0.0 },
            },
            interiorName = 'hei_sm_16_planning_room',
            armory = {
                weapons = {
                    { weapon = 'WEAPON_PISTOL50', label = 'Pistol .50', rank = 0 },
                    { weapon = 'WEAPON_SMG', label = 'SMG', rank = 1 },
                    { weapon = 'WEAPON_ASSAULTRIFLE', label = 'Assault Rifle', rank = 2 },
                    { weapon = 'WEAPON_PUMPSHOTGUN', label = 'Pump Shotgun', rank = 1 },
                },
                ammo = {
                    { item = 'pistol_ammo', label = 'Pistol Ammo', count = 50 },
                    { item = 'rifle_ammo', label = 'Rifle Ammo', count = 100 },
                    { item = 'smg_ammo', label = 'SMG Ammo', count = 80 },
                },
                equipment = {
                    { item = 'armor', label = 'Body Armor' },
                    { item = 'grenade', label = 'Grenade' },
                    { item = 'handcuffs', label = 'Handcuffs' },
                    { item = 'breaching_charge', label = 'Breaching Charge' },
                }
            },
        },
        sandy_shores = {
            id = 'sandy_shores_bunker',
            label = 'Sandy Shores Bunker',
            entrance = {
                coords = vector3(1395.0, 3695.0, 34.5),
                heading = 180.0,
                rocks = {
                    { model = 'prop_rock_4_b', coords = vector3(1392.5, 3693.0, 34.0), heading = 0.0, slideDir = vector3(-4.0, 0.0, 0.0) },
                    { model = 'prop_rock_4_c', coords = vector3(1397.5, 3697.0, 34.0), heading = 45.0, slideDir = vector3(4.0, 0.0, 0.0) },
                    { model = 'prop_rock_3_b', coords = vector3(1395.0, 3692.5, 33.5), heading = 90.0, slideDir = vector3(0.0, -4.0, 0.0) },
                },
            },
            interior = {
                coords = vector3(134.0, -132.0, 58.0),
                heading = 270.0,
                vehicleSpawn = { coords = vector3(130.0, -134.0, 57.5), heading = 270.0 },
                droneSpawn = { coords = vector3(132.0, -128.0, 59.0), heading = 0.0 },
                exit = { coords = vector3(137.0, -132.0, 58.0), heading = 90.0 },
            },
            interiorName = 'sm_15_planning_room_02',
            armory = {
                weapons = {
                    { weapon = 'WEAPON_PISTOL50', label = 'Pistol .50', rank = 0 },
                    { weapon = 'WEAPON_ASSAULTRIFLE', label = 'Assault Rifle', rank = 2 },
                },
                ammo = {
                    { item = 'pistol_ammo', label = 'Pistol Ammo', count = 50 },
                    { item = 'rifle_ammo', label = 'Rifle Ammo', count = 100 },
                },
                equipment = {
                    { item = 'armor', label = 'Body Armor' },
                    { item = 'handcuffs', label = 'Handcuffs' },
                }
            },
        },
        humane_labs = {
            id = 'humane_labs_bunker',
            label = 'Humane Labs Bunker',
            entrance = {
                coords = vector3(3595.0, 3745.0, 29.5),
                heading = 0.0,
                rocks = {
                    { model = 'prop_rock_4_b', coords = vector3(3592.5, 3743.0, 29.0), heading = 0.0, slideDir = vector3(-5.0, 0.0, 0.0) },
                    { model = 'prop_rock_4_c', coords = vector3(3597.5, 3747.0, 29.0), heading = 0.0, slideDir = vector3(5.0, 0.0, 0.0) },
                    { model = 'hei_heist_stn_rock_col_d', coords = vector3(3595.0, 3742.0, 28.5), heading = 0.0, slideDir = vector3(0.0, -4.0, 0.0) },
                },
            },
            interior = {
                coords = vector3(-136.0, -130.0, 58.0),
                heading = 0.0,
                vehicleSpawn = { coords = vector3(-140.0, -132.0, 57.5), heading = 0.0 },
                droneSpawn = { coords = vector3(-138.0, -126.0, 59.0), heading = 0.0 },
                exit = { coords = vector3(-133.0, -130.0, 58.0), heading = 180.0 },
            },
            interiorName = 'gr_case13_bunker',
            armory = {
                weapons = {
                    { weapon = 'WEAPON_PISTOL50', label = 'Pistol .50', rank = 0 },
                    { weapon = 'WEAPON_SMG', label = 'SMG', rank = 1 },
                    { weapon = 'WEAPON_ASSAULTRIFLE', label = 'Assault Rifle', rank = 2 },
                    { weapon = 'WEAPON_HEAVYSNIPER', label = 'Heavy Sniper', rank = 3 },
                    { weapon = 'WEAPON_RPG', label = 'RPG', rank = 4 },
                },
                ammo = {
                    { item = 'pistol_ammo', label = 'Pistol Ammo', count = 50 },
                    { item = 'rifle_ammo', label = 'Rifle Ammo', count = 100 },
                    { item = 'smg_ammo', label = 'SMG Ammo', count = 80 },
                    { item = 'sniper_ammo', label = 'Sniper Ammo', count = 20 },
                },
                equipment = {
                    { item = 'armor', label = 'Body Armor' },
                    { item = 'grenade', label = 'Grenade' },
                    { item = 'handcuffs', label = 'Handcuffs' },
                    { item = 'breaching_charge', label = 'Breaching Charge' },
                }
            },
        },
        abattoir = {
            id = 'abattoir_bunker',
            label = 'Abattoir Basement',
            entrance = {
                coords = vector3(-1905.0, -2055.0, 21.5),
                heading = 180.0,
                rocks = {
                    { model = 'prop_rock_4_b', coords = vector3(-1907.5, -2053.0, 21.0), heading = 90.0, slideDir = vector3(0.0, -4.0, 0.0) },
                    { model = 'prop_rock_4_c', coords = vector3(-1902.5, -2057.0, 21.0), heading = 135.0, slideDir = vector3(0.0, 4.0, 0.0) },
                },
            },
            interior = {
                coords = vector3(-140.0, -132.0, 58.0),
                heading = 90.0,
                vehicleSpawn = { coords = vector3(-144.0, -134.0, 57.5), heading = 90.0 },
                droneSpawn = { coords = vector3(-142.0, -128.0, 59.0), heading = 0.0 },
                exit = { coords = vector3(-137.0, -132.0, 58.0), heading = 270.0 },
            },
            interiorName = 'v_abattoir',
            armory = {
                weapons = {
                    { weapon = 'WEAPON_PISTOL50', label = 'Pistol .50', rank = 0 },
                    { weapon = 'WEAPON_SMG', label = 'SMG', rank = 1 },
                    { weapon = 'WEAPON_PUMPSHOTGUN', label = 'Pump Shotgun', rank = 1 },
                },
                ammo = {
                    { item = 'pistol_ammo', label = 'Pistol Ammo', count = 50 },
                    { item = 'smg_ammo', label = 'SMG Ammo', count = 80 },
                },
                equipment = {
                    { item = 'armor', label = 'Body Armor' },
                    { item = 'handcuffs', label = 'Handcuffs' },
                }
            },
        },
        cid_bunker = {
            id = 'cid_bunker',
            label = 'CID Bunker',
            allowedJobs = { 'cid', 'police', 'sheriff', 'statepolice' },
            minRank = 3,
            entrance = {
                coords = vector3(430.0, -750.0, 26.0),
                heading = 0.0,
                rocks = {
                    { model = 'prop_rock_4_b', coords = vector3(427.5, -748.0, 25.5), heading = 0.0, slideDir = vector3(-4.0, 0.0, 0.0) },
                    { model = 'prop_rock_4_c', coords = vector3(432.5, -752.0, 25.5), heading = 45.0, slideDir = vector3(4.0, 0.0, 0.0) },
                    { model = 'prop_rock_3_b', coords = vector3(430.0, -747.5, 25.0), heading = 90.0, slideDir = vector3(0.0, -4.0, 0.0) },
                },
            },
            interior = {
                coords = vector3(1000.0, -3000.0, -40.0),
                heading = 180.0,
                vehicleSpawn = { coords = vector3(996.0, -3002.0, -40.5), heading = 180.0 },
                heliSpawn = { coords = vector3(1000.0, -3004.0, -40.0), heading = 180.0 },
                droneSpawn = { coords = vector3(998.0, -2996.0, -39.0), heading = 0.0 },
                exit = { coords = vector3(1003.0, -3000.0, -40.0), heading = 0.0 },
                roofProps = {
                    { model = 'prop_rock_4_b', coords = vector3(997.0, -3004.0, -36.0), heading = 0.0, slideDir = vector3(0.0, 0.0, 6.0) },
                    { model = 'prop_rock_4_c', coords = vector3(1003.0, -3004.0, -36.0), heading = 90.0, slideDir = vector3(0.0, 0.0, 6.0) },
                    { model = 'prop_rock_3_b', coords = vector3(1000.0, -3008.0, -36.5), heading = 180.0, slideDir = vector3(0.0, 0.0, 6.0) },
                },
            },
            interiorName = 'hei_hangar_int',
            armory = {
                weapons = {
                    { weapon = 'WEAPON_PISTOL50', label = 'Pistol .50', rank = 0 },
                    { weapon = 'WEAPON_SMG', label = 'SMG', rank = 1 },
                    { weapon = 'WEAPON_ASSAULTRIFLE', label = 'Assault Rifle', rank = 2 },
                    { weapon = 'WEAPON_HEAVYSNIPER', label = 'Heavy Sniper', rank = 3 },
                },
                ammo = {
                    { item = 'pistol_ammo', label = 'Pistol Ammo', count = 50 },
                    { item = 'smg_ammo', label = 'SMG Ammo', count = 80 },
                    { item = 'rifle_ammo', label = 'Rifle Ammo', count = 100 },
                    { item = 'sniper_ammo', label = 'Sniper Ammo', count = 20 },
                },
                equipment = {
                    { item = 'cid_badge', label = 'CID Badge' },
                    { item = 'cid_radio', label = 'CID Radio' },
                    { item = 'cid_tactical_vest', label = 'CID Tactical Vest' },
                    { item = 'cid_heavy_armor', label = 'CID Heavy Armor' },
                }
            },
        },
    },
}
