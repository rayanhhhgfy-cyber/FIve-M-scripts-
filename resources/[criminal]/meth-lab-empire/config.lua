Config = Config or {}
Config.MethLab = Config.MethLab or {}

Config.MethLab = {

    defaultPasscode = '2193',

    cidJobs = { 'cid', 'police', 'sheriff', 'statepolice' },

    adminGroups = { 'admin', 'superadmin', 'god' },

    passcodeCooldown = 30,
    maxPasscodeAttempts = 3,

    cooking = {
        stationModel = 'prop_cs_pot_01',
        stationOffset = vector3(1.5, 0.0, 0.0),

        stages = {
            mix = { label = 'Mix Precursors', duration = 8000, failedLabel = 'Spilled mixture' },
            heat = { label = 'Heat Reaction', duration = 15000, failedLabel = 'Temperature失控' },
            extract = { label = 'Solvent Extraction', duration = 10000, failedLabel = 'Extraction failed' },
            crystallize = { label = 'Crystallization', duration = 30000, failedLabel = 'Crystals ruined' },
        },

        recipes = {
            blue_sky = {
                label = 'Blue Sky',
                difficulty = 'hard',
                baseDuration = 60000,
                purityCap = 85,
                ingredients = {
                    { item = 'pseudoephedrine', label = 'Pseudoephedrine', amount = 2 },
                    { item = 'lithium', label = 'Lithium', amount = 1 },
                    { item = 'anhydrous_ammonia', label = 'Anhydrous Ammonia', amount = 2 },
                },
                outputItem = 'meth_blue_sky',
                outputMin = 2,
                outputMax = 5,
            },
            crystal = {
                label = 'Crystal',
                difficulty = 'very_hard',
                baseDuration = 75000,
                purityCap = 98,
                ingredients = {
                    { item = 'p2p', label = 'P2P', amount = 1 },
                    { item = 'methylamine', label = 'Methylamine', amount = 1 },
                    { item = 'red_phosphorus', label = 'Red Phosphorus', amount = 2 },
                },
                outputItem = 'meth_crystal',
                outputMin = 1,
                outputMax = 4,
            },
            street = {
                label = 'Street Shake',
                difficulty = 'easy',
                baseDuration = 40000,
                purityCap = 60,
                ingredients = {
                    { item = 'pseudoephedrine', label = 'Pseudoephedrine', amount = 1 },
                    { item = 'battery_acid', label = 'Battery Acid', amount = 2 },
                    { item = 'lye', label = 'Lye', amount = 1 },
                },
                outputItem = 'meth_street',
                outputMin = 3,
                outputMax = 7,
            },
        },

        purityStages = {
            { min = 90, label = 'Blue Sky Glass', priceMult = 2.5 },
            { min = 70, label = 'Crystal Shards', priceMult = 1.5 },
            { min = 40, label = 'Street Meth', priceMult = 1.0 },
            { min = 0, label = 'Burned Batch', priceMult = 0.0 },
        },

        temperature = {
            min = 200,
            max = 400,
            idealMin = 270,
            idealMax = 300,
            explosionTemp = 350,
            freezeTemp = 230,
            explosionChance = 0.15,
        },

        toxicWastePerCook = { min = 1, max = 3 },
    },

    ingredients = {
        pseudoephedrine = { label = 'Pseudoephedrine', weight = 100, buyPrice = 200, canBuyFromBlackMarket = true },
        lithium = { label = 'Lithium', weight = 200, buyPrice = 400, canBuyFromBlackMarket = true },
        anhydrous_ammonia = { label = 'Anhydrous Ammonia', weight = 300, buyPrice = 150, canBuyFromBlackMarket = true },
        red_phosphorus = { label = 'Red Phosphorus', weight = 150, buyPrice = 500, canBuyFromBlackMarket = true },
        p2p = { label = 'P2P', weight = 200, buyPrice = 800, canBuyFromBlackMarket = true },
        methylamine = { label = 'Methylamine', weight = 250, buyPrice = 1200, canBuyFromBlackMarket = true },
        battery_acid = { label = 'Battery Acid', weight = 400, buyPrice = 100, canBuyFromBlackMarket = true },
        lye = { label = 'Lye', weight = 100, buyPrice = 50, canBuyFromBlackMarket = true },
        toxic_waste = { label = 'Toxic Waste', weight = 500, buyPrice = 0, canBuyFromBlackMarket = false },
    },

    dealing = {
        minPolice = 2,
        policeAlertChance = 0.25,

        zones = {
            { coords = vector3(-1150.0, -1520.0, 4.0), label = 'Docks Warehouse District', radius = 30.0, risk = 'high' },
            { coords = vector3(-180.0, -900.0, 30.0), label = 'South Central Alleys', radius = 25.0, risk = 'medium' },
            { coords = vector3(270.0, -1580.0, 28.0), label = 'Strawberry Backstreets', radius = 20.0, risk = 'medium' },
            { coords = vector3(110.0, -1280.0, 29.0), label = 'Vespucci Boardwalk', radius = 20.0, risk = 'low' },
            { coords = vector3(1700.0, 4800.0, 42.0), label = 'Grapeseed Forest Clearing', radius = 25.0, risk = 'low' },
            { coords = vector3(1850.0, 3700.0, 34.0), label = 'Sandy Shores Trailer Park', radius = 30.0, risk = 'medium' },
            { coords = vector3(2200.0, 5600.0, 53.0), label = 'Paleto Bay Forest', radius = 25.0, risk = 'low' },
            { coords = vector3(-1200.0, -890.0, 13.0), label = 'Textile City Alleys', radius = 20.0, risk = 'medium' },
            { coords = vector3(750.0, -200.0, 29.0), label = 'Mirror Park Underpass', radius = 20.0, risk = 'low' },
            { coords = vector3(1400.0, 1100.0, 114.0), label = 'El Burro Heights', radius = 25.0, risk = 'low' },
            { coords = vector3(-1650.0, -1050.0, 13.0), label = 'Del Perro Pier (Night)', radius = 25.0, risk = 'high' },
            { coords = vector3(1000.0, -2200.0, 30.0), label = 'La Mesa Factory Row', radius = 25.0, risk = 'high' },
        },

        riskModifiers = {
            low = 1,
            medium = 2,
            high = 3,
        },

        npc = {
            models = {
                'a_m_y_skater_01', 'a_m_y_stwhi_02', 'a_m_y_stbla_02', 'a_m_y_stlat_01',
                'a_m_o_ktown_01', 'a_f_y_skater_01', 'a_m_y_skater_02', 'a_m_y_skater_03',
                'a_m_y_breach_01', 'a_m_y_business_03', 'a_m_y_business_02',
                'a_m_y_business_01', 'a_m_y_cyclist_01', 'a_m_y_beach_01',
            },
            spawnCount = { min = 3, max = 6 },
            approachRange = 2.5,
            despawnTime = 180,
        },

        buyerTypes = {
            junkie = { chance = 35, minQty = 1, maxQty = 3, priceMult = 0.8, risk = 1 },
            regular = { chance = 30, minQty = 3, maxQty = 8, priceMult = 1.0, risk = 2 },
            bulk = { chance = 15, minQty = 10, maxQty = 25, priceMult = 1.3, risk = 3 },
            gang = { chance = 10, minQty = 15, maxQty = 40, priceMult = 1.5, risk = 4 },
            undercover = { chance = 10, minQty = 0, maxQty = 0, priceMult = 0.0, risk = 10 },
        },

        undercoverChanceBase = 0.10,
        undercoverChancePerHeat = 0.005,

        negotiation = {
            enabled = true,
            successChance = 0.6,
            priceBonus = 0.15,
            penaltyMult = 0.85,
        },

        reputation = {
            levels = { 0, 15, 40, 80, 150 },
            perks = {
                { priceMult = 1.0, maxDealSize = 5, undercoverWarning = false },
                { priceMult = 1.1, maxDealSize = 10, undercoverWarning = false },
                { priceMult = 1.25, maxDealSize = 15, undercoverWarning = false },
                { priceMult = 1.5, maxDealSize = 25, undercoverWarning = true },
                { priceMult = 2.0, maxDealSize = 50, undercoverWarning = true },
            },
        },

        police = {
            fine = { min = 1000, max = 5000 },
            jailTime = { min = 60, max = 300 },
        },
    },

    heat = {
        cookingPerBatch = 3,
        saleBase = 1,
        perUnitSold = 0.5,
        explosion = 15,
        toxicDumping = 2,
        failedHack = 10,
        decayInterval = 600,
        decayAmount = 1,
        maxHeat = 100,
        thresholds = {
            safe = { max = 20, label = 'Safe', color = '#32ff64' },
            suspicious = { max = 40, label = 'Suspicious', color = '#ffd700' },
            investigated = { max = 60, label = 'Investigated', color = '#ff8800' },
            dangerous = { max = 80, label = 'Dangerous', color = '#ff4444' },
            critical = { max = 100, label = 'CRITICAL', color = '#ff0000' },
        },
    },

    upgrades = {
        ventilation = { label = 'Better Ventilation', cost = 15000, description = '-25% heat from cooking' },
        industrial_mixer = { label = 'Industrial Mixer', cost = 25000, description = '+10% base purity' },
        chemical_storage = { label = 'Chemical Storage', cost = 10000, description = '50 slot ingredient locker' },
        hidden_compartment = { label = 'Hidden Compartment', cost = 50000, description = 'Hide evidence during raid (60%)' },
        escape_tunnel = { label = 'Escape Tunnel', cost = 75000, description = 'Escape route during raid' },
        security_cameras = { label = 'Security Cameras', cost = 30000, description = 'See exterior feed' },
        purity_analyzer = { label = 'Purity Analyzer', cost = 20000, description = 'See exact purity before final step' },
    },

    raid = {
        prepTime = 60,
        hideCompartmentChance = 0.6,
        evidenceFoundFine = 5000,
        evidenceFoundJail = 180,
        escapeTunnelRange = 200,
    },

    targetOptions = {
        enterBunker = { icon = 'fas fa-door-open', label = 'Enter Bunker', distance = 2.0 },
        useCookStation = { icon = 'fas fa-flask', label = 'Use Chemistry Station', distance = 1.5 },
        chemicalStorage = { icon = 'fas fa-boxes', label = 'Chemical Storage', distance = 1.5 },
        bunkerTerminal = { icon = 'fas fa-desktop', label = 'Bunker Terminal', distance = 1.5 },
        approachCustomer = { icon = 'fas fa-handshake', label = 'Approach Customer', distance = 2.0 },
        sellDrugs = { icon = 'fas fa-dollar-sign', label = 'Sell Drugs', distance = 2.0 },
        negotiate = { icon = 'fas fa-comments', label = 'Negotiate Price', distance = 2.0 },
        disposeWaste = { icon = 'fas fa-trash-alt', label = 'Dispose Toxic Waste', distance = 2.0 },
    },
}
