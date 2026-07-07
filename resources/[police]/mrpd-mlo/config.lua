Config = Config or {}

Config.MRPD = {
    Building = {
        Interiors = {
            Main = {
                ipl = 'mrpd_main',
                coords = vector3(440.0, -980.0, 30.0),
                heading = 0.0
            },
            Garage = {
                ipl = 'mrpd_garage',
                coords = vector3(445.0, -997.0, 25.0),
                heading = 90.0
            },
            Roof = {
                ipl = 'mrpd_roof',
                coords = vector3(437.0, -985.0, 35.0),
                heading = 0.0
            },
            Helipad = {
                ipl = 'mrpd_helipad',
                coords = vector3(450.0, -980.0, 40.0),
                heading = 0.0
            },
            Basement = {
                ipl = 'mrpd_basement',
                coords = vector3(440.0, -975.0, 20.0),
                heading = 180.0
            },
            Armory = {
                ipl = 'mrpd_armory',
                coords = vector3(445.0, -985.0, 30.0),
                heading = 270.0
            },
            LockerRoom = {
                ipl = 'mrpd_lockers',
                coords = vector3(448.0, -985.0, 30.0),
                heading = 90.0
            },
            BreakRoom = {
                ipl = 'mrpd_break',
                coords = vector3(450.0, -975.0, 30.0),
                heading = 0.0
            },
            Briefing = {
                ipl = 'mrpd_briefing',
                coords = vector3(435.0, -985.0, 30.0),
                heading = 180.0
            },
            Cells = {
                ipl = 'mrpd_cells',
                coords = vector3(460.0, -990.0, 24.0),
                heading = 0.0
            }
        },
        Entrances = {
            Front = { coords = vector3(434.7, -983.2, 30.8), heading = 0.0 },
            Back = { coords = vector3(468.7, -1014.5, 26.4), heading = 180.0 },
            Garage = { coords = vector3(454.5, -999.0, 25.8), heading = 90.0 },
            Roof = { coords = vector3(437.0, -985.0, 35.0), heading = 0.0 },
            ParkingLot = { coords = vector3(409.0, -998.0, 29.2), heading = 180.0 }
        },
        Doors = {
            { model = -1603817716, coords = vector3(434.7, -983.2, 30.8), locked = true },
            { model = 749848321, coords = vector3(443.9, -989.1, 30.8), locked = true },
            { model = 1557126584, coords = vector3(450.1, -987.0, 30.8), locked = true },
            { model = -1116041313, coords = vector3(469.9, -1014.5, 26.5), locked = true },
            { model = -1873535732, coords = vector3(457.8, -991.6, 30.8), locked = true }
        }
    },

    Blips = {
        { coords = vector3(440.0, -980.0, 30.0), sprite = 60, color = 38, scale = 1.0, label = 'MRPD' }
    },

    Zones = {
        Lobby = {
            coords = vector3(440.0, -985.0, 30.0),
            radius = 15.0,
            actions = {
                ClockIn = { coords = vector3(440.0, -993.0, 30.0), heading = 180.0 },
                DutyBoard = { coords = vector3(435.0, -983.0, 30.0), heading = 0.0 }
            }
        },
        Armory = {
            coords = vector3(445.0, -987.0, 30.0),
            radius = 10.0,
            weapons = {
                { model = 'WEAPON_STUNGUN', label = 'Taser', price = 0, rank = 0 },
                { model = 'WEAPON_NIGHTSTICK', label = 'Baton', price = 0, rank = 0 },
                { model = 'WEAPON_FLASHLIGHT', label = 'Flashlight', price = 0, rank = 0 },
                { model = 'WEAPON_PISTOL', label = 'Pistol', price = 0, rank = 1 },
                { model = 'WEAPON_CARBINERIFLE', label = 'Carbine', price = 0, rank = 4 },
                { model = 'WEAPON_PUMPSHOTGUN', label = 'Shotgun', price = 0, rank = 3 },
                { model = 'WEAPON_SMG', label = 'SMG', price = 0, rank = 2 }
            },
            ammo = {
                { item = 'pistol_ammo', label = 'Pistol Ammo', price = 0, rank = 1 },
                { item = 'rifle_ammo', label = 'Rifle Ammo', price = 0, rank = 4 },
                { item = 'shotgun_ammo', label = 'Shotgun Shells', price = 0, rank = 3 },
                { item = 'smg_ammo', label = 'SMG Ammo', price = 0, rank = 2 }
            },
            equipment = {
                { item = 'lspd_cadet_uniform', label = 'LSPD Cadet Uniform', price = 0, rank = 0 },
                { item = 'lspd_officer_uniform', label = 'LSPD Officer Uniform', price = 0, rank = 1 },
                { item = 'lspd_sgt_uniform', label = 'LSPD Sergeant Uniform', price = 0, rank = 2 },
                { item = 'lspd_lt_uniform', label = 'LSPD Lieutenant Uniform', price = 0, rank = 3 },
                { item = 'lspd_chief_uniform', label = 'LSPD Chief Uniform', price = 0, rank = 4 },
                { item = 'lspd_patrol_vest', label = 'LSPD Patrol Vest', price = 0, rank = 0 },
                { item = 'lspd_heavy_vest', label = 'LSPD Heavy Vest', price = 0, rank = 3 },
                { item = 'police_radio', label = 'Radio', price = 0, rank = 0 },
                { item = 'handcuffs', label = 'Handcuffs', price = 0, rank = 0 },
                { item = 'police_badge', label = 'Badge', price = 0, rank = 0 },
                { item = 'gps_tracker', label = 'GPS Tracker', price = 0, rank = 3 },
                { item = 'tracker_sweeper', label = 'Tracker Sweeper', price = 0, rank = 3 },
                { item = 'covert_lockpick', label = 'Covert Lockpick', price = 0, rank = 4 },
            }
        },
        Evidence = {
            coords = vector3(444.0, -980.0, 30.0),
            radius = 5.0,
            storageSlots = 500
        },
        Dispatch = {
            coords = vector3(434.0, -980.0, 30.0),
            radius = 3.0,
            computers = {
                { coords = vector3(434.0, -980.0, 30.0), heading = 0.0 },
                { coords = vector3(434.0, -978.0, 30.0), heading = 0.0 }
            }
        },
        Briefing = {
            coords = vector3(440.0, -988.0, 30.0),
            radius = 8.0,
            boardZones = {
                { coords = vector3(441.0, -993.0, 30.5), label = 'Active Warrants' },
                { coords = vector3(443.0, -993.0, 30.5), label = 'BOLO Alerts' },
                { coords = vector3(445.0, -993.0, 30.5), label = 'Shift Assignments' }
            }
        },
        Cells = {
            coords = vector3(460.0, -992.0, 24.0),
            radius = 20.0,
            cellCount = 8,
            release = { coords = vector3(461.5, -996.0, 24.0), heading = 0.0 }
        },
        Garage = {
            coords = vector3(454.5, -999.0, 25.8),
            radius = 20.0,
            vehicleSpawns = {
                { coords = vector3(443.0, -1007.5, 26.0), heading = 90.0 },
                { coords = vector3(447.0, -1007.5, 26.0), heading = 90.0 },
                { coords = vector3(451.0, -1007.5, 26.0), heading = 90.0 },
                { coords = vector3(455.0, -1007.5, 26.0), heading = 90.0 },
                { coords = vector3(459.0, -1007.5, 26.0), heading = 90.0 }
            },
            heliSpawns = {
                { coords = vector3(449.0, -981.0, 43.7), heading = 0.0 }
            }
        },
        Roof = {
            coords = vector3(437.0, -985.0, 35.0),
            radius = 15.0,
            sniperSpots = {
                { coords = vector3(435.0, -983.0, 35.5), heading = 180.0 },
                { coords = vector3(442.0, -983.0, 35.5), heading = 180.0 }
            }
        }
    },

    Props = {
        Lobby = {
            { model = 'v_ilev_mm_fdoor', coords = vector3(434.7, -983.2, 30.8), heading = 0.0 },
            { model = 'v_ilev_mm_fdoor2', coords = vector3(443.9, -989.1, 30.8), heading = 0.0 }
        },
        Armory = {
            { model = 'gr_prop_gr_armoured_01', coords = vector3(445.0, -987.0, 30.0), heading = 0.0 }
        },
        Dispatch = {
            { model = 'prop_monitor_01b', coords = vector3(434.0, -980.0, 30.5), heading = 0.0 },
            { model = 'prop_monitor_01b', coords = vector3(434.0, -978.0, 30.5), heading = 0.0 }
        },
        Cells = {
            { model = 'prop_cell_door', coords = vector3(460.0, -992.0, 24.0), heading = 0.0 },
            { model = 'prop_cell_door2', coords = vector3(462.0, -992.0, 24.0), heading = 0.0 }
        }
    },

    TargetOptions = {
        Armory = {
            icon = 'fas fa-vest',
            label = 'Open Armory',
            group = 'police',
            distance = 2.5
        },
        Evidence = {
            icon = 'fas fa-dna',
            label = 'Evidence Locker',
            group = 'police',
            distance = 2.5
        },
        Dispatch = {
            icon = 'fas fa-desktop',
            label = 'Use Computer',
            group = 'police',
            distance = 1.5
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
        Roof = {
            icon = 'fas fa-crosshairs',
            label = 'Access Roof',
            group = 'police',
            distance = 2.0
        }
    },

    Restrictions = {
        requireDuty = true,
        minRank = 0,
        allowedJobs = { 'police', 'sheriff', 'statepolice' },
        armoryMinRank = 1,
        garageMinRank = 0,
        cellsMinRank = 2,
        dispatchMinRank = 0,
        evidenceMinRank = 0
    }
}
