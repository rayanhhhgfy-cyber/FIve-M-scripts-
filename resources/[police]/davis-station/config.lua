Config = Config or {}

Config.DavisStation = {
    Building = {
        Interiors = {
            Main = {
                ipl = 'davis_pd_main',
                coords = vector3(360.0, -1600.0, 25.0),
                heading = 0.0
            },
            Garage = {
                ipl = 'davis_pd_garage',
                coords = vector3(365.0, -1610.0, 22.0),
                heading = 90.0
            },
            Armory = {
                ipl = 'davis_pd_armory',
                coords = vector3(363.0, -1600.0, 25.0),
                heading = 270.0
            },
            Briefing = {
                ipl = 'davis_pd_briefing',
                coords = vector3(358.0, -1602.0, 25.0),
                heading = 180.0
            },
            LockerRoom = {
                ipl = 'davis_pd_lockers',
                coords = vector3(366.0, -1598.0, 25.0),
                heading = 0.0
            },
            Cells = {
                ipl = 'davis_pd_cells',
                coords = vector3(372.0, -1605.0, 22.0),
                heading = 0.0
            }
        },
        Entrances = {
            Front = { coords = vector3(362.0, -1595.0, 25.5), heading = 180.0 },
            Back = { coords = vector3(357.0, -1608.0, 25.0), heading = 0.0 },
            Garage = { coords = vector3(368.0, -1612.0, 22.5), heading = 90.0 }
        },
        Doors = {
            { model = -1603817716, coords = vector3(362.0, -1595.0, 25.5), locked = true },
            { model = 749848321, coords = vector3(368.0, -1598.0, 25.5), locked = true },
            { model = -1116041313, coords = vector3(357.0, -1608.0, 25.0), locked = true }
        }
    },

    Blips = {
        { coords = vector3(360.0, -1600.0, 25.0), sprite = 60, color = 38, scale = 0.8, label = 'Davis PD' }
    },

    Zones = {
        Lobby = {
            coords = vector3(361.0, -1597.0, 25.2),
            radius = 10.0,
            actions = {
                ClockIn = { coords = vector3(361.0, -1594.0, 25.2), heading = 180.0 },
                DutyBoard = { coords = vector3(358.0, -1598.0, 25.2), heading = 0.0 }
            }
        },
        Armory = {
            coords = vector3(363.0, -1602.0, 25.0),
            radius = 6.0,
            weapons = {
                { model = 'WEAPON_STUNGUN', label = 'Taser', price = 0, rank = 0 },
                { model = 'WEAPON_NIGHTSTICK', label = 'Baton', price = 0, rank = 0 },
                { model = 'WEAPON_PISTOL', label = 'Pistol', price = 0, rank = 1 },
                { model = 'WEAPON_SMG', label = 'SMG', price = 0, rank = 2 }
            },
            equipment = {
                { item = 'lspd_cadet_uniform', label = 'LSPD Cadet Uniform', price = 0, rank = 0 },
                { item = 'lspd_officer_uniform', label = 'LSPD Officer Uniform', price = 0, rank = 1 },
                { item = 'lspd_sgt_uniform', label = 'LSPD Sergeant Uniform', price = 0, rank = 2 },
                { item = 'lspd_patrol_vest', label = 'LSPD Patrol Vest', price = 0, rank = 0 },
                { item = 'handcuffs', label = 'Handcuffs', price = 0, rank = 0 },
                { item = 'police_badge', label = 'Badge', price = 0, rank = 0 },
                { item = 'police_radio', label = 'Radio', price = 0, rank = 0 },
                { item = 'gps_tracker', label = 'GPS Tracker', price = 0, rank = 4 },
                { item = 'tracker_sweeper', label = 'Tracker Sweeper', price = 0, rank = 4 },
            }
        },
        Briefing = {
            coords = vector3(359.0, -1601.0, 25.2),
            radius = 5.0
        },
        Cells = {
            coords = vector3(372.0, -1605.0, 22.0),
            radius = 12.0,
            cellCount = 6,
            release = { coords = vector3(373.5, -1608.0, 22.0), heading = 0.0 }
        },
        Garage = {
            coords = vector3(368.0, -1612.0, 22.5),
            radius = 15.0,
            vehicleSpawns = {
                { coords = vector3(360.0, -1615.0, 22.5), heading = 90.0 },
                { coords = vector3(364.0, -1615.0, 22.5), heading = 90.0 },
                { coords = vector3(368.0, -1615.0, 22.5), heading = 90.0 },
                { coords = vector3(372.0, -1615.0, 22.5), heading = 90.0 }
            }
        },
        EvidenceLocker = {
            coords = vector3(365.0, -1604.0, 25.0),
            radius = 3.0,
            storageSlots = 200
        }
    },

    TargetOptions = {
        Armory = {
            icon = 'fas fa-vest',
            label = 'Open Armory',
            group = 'police',
            distance = 2.5
        },
        Garage = {
            icon = 'fas fa-car',
            label = 'Police Garage',
            group = 'police',
            distance = 3.0
        },
        ClockIn = {
            icon = 'fas fa-clock',
            label = 'Clock In / Out',
            group = 'police',
            distance = 2.0
        },
        Cells = {
            icon = 'fas fa-lock',
            label = 'Manage Cells',
            group = 'police',
            distance = 2.5,
            minRank = 2
        },
        EvidenceLocker = {
            icon = 'fas fa-dna',
            label = 'Evidence Locker',
            group = 'police',
            distance = 2.5
        },
        Briefing = {
            icon = 'fas fa-clipboard',
            label = 'Briefing Board',
            group = 'police',
            distance = 2.0
        }
    },

    Restrictions = {
        requireDuty = true,
        minRank = 0,
        allowedJobs = { 'police', 'sheriff' },
        armoryMinRank = 1,
        garageMinRank = 0,
        cellsMinRank = 2
    }
}
