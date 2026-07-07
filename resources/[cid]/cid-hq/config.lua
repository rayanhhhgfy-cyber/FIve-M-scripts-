Config = Config or {}

Config.CIDHQ = {
    Building = {
        Interiors = {
            Main = { ipl = 'cid_hq_main', coords = vector3(110.0, -750.0, 45.0), heading = 0.0 },
            ServerRoom = { ipl = 'cid_hq_server', coords = vector3(115.0, -745.0, 45.0), heading = 0.0 },
            Archive = { ipl = 'cid_hq_archive', coords = vector3(105.0, -755.0, 45.0), heading = 180.0 },
            Interrogation = { ipl = 'cid_hq_interrogation', coords = vector3(118.0, -760.0, 45.0), heading = 0.0 },
            Surveillance = { ipl = 'cid_hq_surveillance', coords = vector3(112.0, -770.0, 45.0), heading = 0.0 },
            Lab = { ipl = 'cid_hq_lab', coords = vector3(108.0, -740.0, 45.0), heading = 0.0 }
        },
        Entrances = {
            Front = { coords = vector3(110.0, -745.0, 45.5), heading = 0.0 },
            Back = { coords = vector3(120.0, -760.0, 45.0), heading = 180.0 },
            Garage = { coords = vector3(100.0, -730.0, 44.0), heading = 0.0 }
        },
        Doors = {
            { model = -1603817716, coords = vector3(110.0, -745.0, 45.5), locked = true },
            { model = 749848321, coords = vector3(115.0, -750.0, 45.5), locked = true }
        }
    },

    Blips = {
        { coords = vector3(110.0, -750.0, 45.0), sprite = 60, color = 3, scale = 0.9, label = 'CID Headquarters' }
    },

    Zones = {
        Lobby = {
            coords = vector3(110.0, -748.0, 45.0),
            radius = 8.0,
            actions = {
                Reception = { coords = vector3(108.0, -746.0, 45.0), heading = 0.0 },
                DutyBoard = { coords = vector3(112.0, -746.0, 45.0), heading = 180.0 }
            }
        },
        Armory = {
            coords = vector3(115.0, -755.0, 45.0),
            radius = 5.0,
            equipment = {
                { item = 'cid_agent_uniform', label = 'CID Agent Uniform', price = 0, rank = 0 },
                { item = 'cid_director_uniform', label = 'CID Director Uniform', price = 0, rank = 4 },
                { item = 'cid_tactical_vest', label = 'CID Tactical Vest', price = 0, rank = 0 },
                { item = 'cid_heavy_armor', label = 'CID Heavy Armor', price = 0, rank = 2 },
                { item = 'cid_badge', label = 'CID Badge', price = 0, rank = 0 },
                { item = 'cid_radio', label = 'CID Radio', price = 0, rank = 0 },
                { item = 'cid_tablet', label = 'CID Tablet', price = 0, rank = 0 },
                { item = 'gps_tracker', label = 'GPS Tracker', price = 0, rank = 0 },
                { item = 'tracker_sweeper', label = 'Tracker Sweeper', price = 0, rank = 0 },
                { item = 'spikestrip', label = 'Spike Strip', price = 0, rank = 0 },
                { item = 'handcuffs', label = 'Handcuffs', price = 0, rank = 0 },
                { item = 'bodycam', label = 'Body Camera', price = 0, rank = 0 },
                { item = 'radio', label = 'Radio', price = 0, rank = 0 },
                { item = 'roadflare', label = 'Road Flare', price = 0, rank = 0 },
                { item = 'medikit', label = 'Medical Kit', price = 0, rank = 0 },
                { item = 'ammo-9', label = '9mm Ammo', price = 0, rank = 0 },
                { item = 'ammo-rifle', label = '5.56 Ammo', price = 0, rank = 2 },
                { item = 'ammo-rifle2', label = '7.62 Ammo', price = 0, rank = 2 },
                { item = 'at_flashlight', label = 'Tactical Flashlight', price = 0, rank = 0 },
                { item = 'at_suppressor_light', label = 'Suppressor', price = 0, rank = 2 },
                { item = 'WEAPON_BZGAS', label = 'BZ Tear Gas', price = 0, rank = 2 },
                { item = 'lockpick', label = 'Lockpick', price = 0, rank = 0 },
                { item = 'heist_mask', label = 'Head Bag', price = 0, rank = 0 },
                { item = 'repair_kit', label = 'Repair Kit', price = 0, rank = 0 },
                { item = 'fingerprint_kit', label = 'Fingerprint Kit', price = 0, rank = 0 },
                { item = 'casing_kit', label = 'Casing Collection Kit', price = 0, rank = 0 },
                { item = 'dna_swab', label = 'DNA Swab Kit', price = 0, rank = 0 },
                { item = 'evidence_bag', label = 'Evidence Bag', price = 0, rank = 0 },
                { item = 'cid_laptop', label = 'CID Laptop', price = 0, rank = 0 },
                { item = 'covert_lockpick', label = 'Covert Lockpick', price = 0, rank = 1 },
                { item = 'alarm_bypass', label = 'Alarm Bypass', price = 0, rank = 2 },
                { item = 'plant_evidence', label = 'Plant Evidence Kit', price = 0, rank = 1 },
                { item = 'surveillance_camera', label = 'Pen Camera', price = 0, rank = 1 },
                { item = 'audio_bug', label = 'Audio Bug', price = 0, rank = 1 },
                { item = 'wiretap_kit', label = 'Wiretap Kit', price = 0, rank = 2 },
                { item = 'drone', label = 'Surveillance Drone', price = 0, rank = 3 },
                { item = 'radar_gun', label = 'Radar Gun', price = 0, rank = 0 },
                { item = 'traffic_cone', label = 'Traffic Cone', price = 0, rank = 0 },
                { item = 'barrier', label = 'Road Barrier', price = 0, rank = 0 }
            }
        },
        ServerRoom = {
            coords = vector3(115.0, -745.0, 45.0),
            radius = 4.0,
            minRank = 3,
            terminals = {
                { coords = vector3(114.0, -744.0, 45.5), heading = 0.0, label = 'Database Terminal' },
                { coords = vector3(116.0, -744.0, 45.5), heading = 0.0, label = 'Analysis Terminal' }
            }
        },
        Archive = {
            coords = vector3(105.0, -755.0, 45.0),
            radius = 4.0,
            minRank = 1,
            storageSlots = 500
        },
        Interrogation = {
            coords = vector3(118.0, -760.0, 45.0),
            radius = 5.0,
            rooms = {
                { coords = vector3(117.0, -759.0, 45.0), camera = true, oneWayMirror = true },
                { coords = vector3(119.0, -759.0, 45.0), camera = true, oneWayMirror = true }
            }
        },
        Surveillance = {
            coords = vector3(112.0, -770.0, 45.0),
            radius = 6.0,
            monitors = {
                { coords = vector3(111.0, -769.0, 45.5), heading = 0.0 },
                { coords = vector3(113.0, -769.0, 45.5), heading = 0.0 },
                { coords = vector3(112.0, -771.0, 45.5), heading = 180.0 }
            }
        },
        Lab = {
            coords = vector3(108.0, -740.0, 45.0),
            radius = 5.0,
            workstations = {
                { coords = vector3(107.0, -739.0, 45.5), heading = 0.0, type = 'digital' },
                { coords = vector3(109.0, -739.0, 45.5), heading = 0.0, type = 'forensic' }
            }
        }
    },

    TargetOptions = {
        Armory = { icon = 'fas fa-vest', label = 'CID Armory', group = 'cid', distance = 2.5 },
        ServerRoom = { icon = 'fas fa-server', label = 'Server Room', group = 'cid', distance = 2.0, minRank = 3 },
        Archive = { icon = 'fas fa-folder-open', label = 'Case Archive', group = 'cid', distance = 2.0 },
        Interrogation = { icon = 'fas fa-chair', label = 'Interrogation Room', group = 'cid', distance = 2.0, minRank = 2 },
        Surveillance = { icon = 'fas fa-video', label = 'Surveillance Center', group = 'cid', distance = 2.0 },
        Lab = { icon = 'fas fa-microscope', label = 'Digital Forensics Lab', group = 'cid', distance = 2.0 },
        DutyBoard = { icon = 'fas fa-clipboard-list', label = 'Duty Status', group = 'cid', distance = 2.0 },
        Garage = { icon = 'fas fa-car-side', label = 'CID Garage', group = 'cid', distance = 3.0 }
    },

    Garage = {
        coords = vector3(100.0, -730.0, 44.0),
        radius = 5.0,
        spawns = {
            { coords = vector3(95.0, -725.0, 44.0), heading = 90.0 },
            { coords = vector3(99.0, -725.0, 44.0), heading = 90.0 },
            { coords = vector3(103.0, -725.0, 44.0), heading = 90.0 },
            { coords = vector3(107.0, -725.0, 44.0), heading = 90.0 },
        }
    },

    Restrictions = {
        requireDuty = true,
        minRank = 0,
        allowedJobs = { 'cid', 'police' },
        armoryRank = 0,
        serverRank = 3,
        interrogationRank = 2
    }
}
