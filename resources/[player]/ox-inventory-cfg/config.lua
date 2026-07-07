Config = Config or {}

Config.Items = {
    ['radio'] = {
        label = 'Radio',
        weight = 200,
        stack = true,
        description = 'Handheld radio for communication',
    },
    ['gps_tracker'] = {
        label = 'GPS Tracker',
        weight = 50,
        stack = true,
        description = 'Magnetic GPS tracker for undercover vehicle deployment. Attach to any vehicle to track its location.',
    },
    ['tracker_sweeper'] = {
        label = 'Tracker Sweeper',
        weight = 300,
        stack = false,
        description = 'RF scanner that detects hidden GPS trackers. Use near vehicles to sweep for bugs.',
    },
    ['covert_lockpick'] = {
        label = 'Covert Lockpick Set',
        weight = 200,
        stack = false,
        description = 'Advanced ceramic lockpick set. Silent entry for doors and vehicles. Leaves minimal trace.',
    },
    ['alarm_bypass'] = {
        label = 'Alarm Bypass Module',
        weight = 150,
        stack = true,
        description = 'Electronic bypass module for vehicle and property alarm systems. Single-use.',
    },
    ['plant_evidence'] = {
        label = 'Plant Evidence Kit',
        weight = 250,
        stack = true,
        description = 'Pre-packaged evidence kit for covert operations. Includes DNA swab, fake IDs, and trace materials.',
    },
    ['surveillance_camera'] = {
        label = 'Pen Camera',
        weight = 80,
        stack = true,
        description = 'Covert pen camera with 48-hour battery. Streams live footage to CID surveillance console.',
    },
    ['audio_bug'] = {
        label = 'Audio Bug',
        weight = 50,
        stack = true,
        description = 'Covert audio listening device. 72-hour battery. Live audio feed to CID surveillance console.',
    },

    -- LSPD Uniforms & Armor
    ['lspd_cadet_uniform'] = {
        label = 'LSPD Cadet Uniform',
        weight = 500,
        stack = false,
        consume = 0,
        description = 'Standard LSPD Cadet uniform — Mission Row PD',
    },
    ['lspd_officer_uniform'] = {
        label = 'LSPD Officer Uniform',
        weight = 500,
        stack = false,
        consume = 0,
        description = 'Standard LSPD Officer uniform — Mission Row PD',
    },
    ['lspd_sgt_uniform'] = {
        label = 'LSPD Sergeant Uniform',
        weight = 550,
        stack = false,
        consume = 0,
        description = 'LSPD Sergeant uniform — Mission Row PD',
    },
    ['lspd_lt_uniform'] = {
        label = 'LSPD Lieutenant Uniform',
        weight = 550,
        stack = false,
        consume = 0,
        description = 'LSPD Lieutenant uniform — Mission Row PD',
    },
    ['lspd_chief_uniform'] = {
        label = 'LSPD Chief Uniform',
        weight = 600,
        stack = false,
        consume = 0,
        description = 'LSPD Chief of Police uniform — Mission Row PD',
    },
    ['lspd_patrol_vest'] = {
        label = 'LSPD Patrol Vest',
        weight = 2000,
        stack = false,
        description = 'Standard issue LSPD patrol vest — ballistic protection',
    },
    ['lspd_heavy_vest'] = {
        label = 'LSPD Heavy Vest',
        weight = 3500,
        stack = false,
        description = 'Heavy-duty LSPD tactical vest — maximum protection',
    },
    ['cid_agent_uniform'] = {
        label = 'CID Agent Uniform',
        weight = 500,
        stack = false,
        consume = 0,
        description = 'CID Agent field uniform — CID Headquarters',
    },
    ['cid_director_uniform'] = {
        label = 'CID Director Uniform',
        weight = 600,
        stack = false,
        consume = 0,
        description = 'CID Director command uniform — CID Headquarters',
    },
    ['cid_tactical_vest'] = {
        label = 'CID Tactical Vest',
        weight = 2500,
        stack = false,
        description = 'CID tactical vest — lightweight ballistic protection',
    },
    ['cid_heavy_armor'] = {
        label = 'CID Heavy Armor',
        weight = 4000,
        stack = false,
        description = 'CID heavy armor rig — full tactical protection',
    },
}

Config.Inventory = {
    weaponSerials = true,
    serialPrefix = 'FIV',
    serialLength = 8,
    uniqueItems = { 'id_card', 'driver_license', 'phone', 'radio', 'laptop', 'cryptostick' },
    blacklistedItems = { 'black_money', 'marked_bills' }
}

Config.Weapons = {
    enableSerials = true,
    serialChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789',
    components = {
        ['at_suppressor'] = { label = 'Suppressor', type = 'suppressor' },
        ['at_flashlight'] = { label = 'Flashlight', type = 'flashlight' },
        ['at_grip'] = { label = 'Grip', type = 'grip' },
        ['at_scope'] = { label = 'Scope', type = 'scope' },
        ['at_barrel'] = { label = 'Barrel', type = 'barrel' },
        ['at_clip'] = { label = 'Extended Clip', type = 'clip' }
    },
    ammoTypes = {
        ['AMMO_PISTOL'] = { label = 'Pistol Ammo', weight = 0.02 },
        ['AMMO_SMG'] = { label = 'SMG Ammo', weight = 0.025 },
        ['AMMO_RIFLE'] = { label = 'Rifle Ammo', weight = 0.03 },
        ['AMMO_SHOTGUN'] = { label = 'Shotgun Shells', weight = 0.04 },
        ['AMMO_SNIPER'] = { label = 'Sniper Ammo', weight = 0.05 }
    }
}

Config.Shops = {
    ['electronics_store'] = {
        label = 'Electronics Store',
        slots = 10,
        items = {
            { name = 'radio', price = 250 },
        }
    },
    ['weapon'] = {
        label = 'Ammunation',
        slots = 30,
        items = {
            { name = 'weapon_knife', price = 200, metadata = { serial = 'WEAPON' } },
            { name = 'weapon_bat', price = 100, metadata = { serial = 'WEAPON' } },
            { name = 'weapon_pistol', price = 5000, metadata = { serial = 'WEAPON' }, license = 'weapon' },
            { name = 'weapon_combatpistol', price = 7500, metadata = { serial = 'WEAPON' }, license = 'weapon' },
            { name = 'pistol_ammo', price = 25 },
            { name = 'rifle_ammo', price = 50 }
        }
    },
    ['ammunation'] = {
        label = 'Ammunation',
        slots = 20,
        items = {
            { name = 'weapon_pistol', price = 5000, metadata = { serial = 'WEAPON' }, license = 'weapon' },
            { name = 'weapon_microsmg', price = 15000, metadata = { serial = 'WEAPON' }, license = 'weapon' },
            { name = 'weapon_assaultrifle', price = 35000, metadata = { serial = 'WEAPON' }, license = 'weapon' },
            { name = 'pistol_ammo', price = 25 },
            { name = 'smg_ammo', price = 40 },
            { name = 'rifle_ammo', price = 50 }
        }
    }
}

Config.Shops['cid_equipment'] = {
    label = 'CID Equipment Locker',
    slots = 20,
    items = {
        { name = 'gps_tracker', price = 0 },
        { name = 'tracker_sweeper', price = 0 },
        { name = 'covert_lockpick', price = 0 },
        { name = 'alarm_bypass', price = 0 },
        { name = 'plant_evidence', price = 0 },
        { name = 'surveillance_camera', price = 0 },
        { name = 'audio_bug', price = 0 },
    }
}

Config.Stashes = {
    property = { slots = 50, weight = 100000 },
    glovebox = { slots = 5, weight = 10000 },
    trunk = { slots = 30, weight = 50000 },
    evidence = { slots = 40, weight = 50000 },
    police_armory = { slots = 100, weight = 200000 }
}

Config.WeightClasses = {
    weapon = 1.0,
    ammo = 0.02,
    food = 0.2,
    drink = 0.3,
    drug = 0.05,
    tool = 0.5,
    valuable = 0.1,
    misc = 0.25
}
