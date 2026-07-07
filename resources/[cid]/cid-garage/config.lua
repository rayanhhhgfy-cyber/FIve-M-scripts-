Config = Config or {}
Config.CIDGarage = Config.CIDGarage or {}

Config.CIDGarage = {
    Categories = {
        Intercept = {
            label = 'Intercept Division',
            rank = 0,
            vehicles = {
                { model = 'buffalo', label = 'CID Buffalo SRT', speed = 195, seats = 4 },
                { model = 'schafter3', label = 'CID Schafter', speed = 205, seats = 4 },
                { model = 'komoda', label = 'CID Komoda', speed = 195, seats = 4 },
                { model = 'jugular', label = 'CID Jugular', speed = 215, seats = 4 },
                { model = 'deity', label = 'CID Deity Command', speed = 210, seats = 4 },
                { model = 'panther', label = 'CID Pursuit', speed = 225, seats = 2 },
                { model = 'cog552', label = 'CID Executive', speed = 200, seats = 4 },
                { model = 'schafter5', label = 'CID Pursuit Sedan', speed = 210, seats = 4 },
            }
        },
        Armored = {
            label = 'Armored Division',
            rank = 2,
            vehicles = {
                { model = 'nightshark', label = 'Nightshark', speed = 160, seats = 4 },
                { model = 'patriot2', label = 'Patriot Armored', speed = 145, seats = 6 },
                { model = 'granger', label = 'Granger SAP', speed = 155, seats = 8 },
                { model = 'dubsta3', label = 'Dubsta Protection', speed = 150, seats = 4 },
                { model = 'speedo', label = 'Armored Speedo', speed = 130, seats = 6 },
                { model = 'schafter6', label = 'CID Armored', speed = 185, seats = 4 },
                { model = 'xls', label = 'CID Protection', speed = 170, seats = 6 },
            }
        },
        Surveillance = {
            label = 'Surveillance',
            rank = 1,
            vehicles = {
                { model = 'police4', label = 'Unmarked Sedan', speed = 185, seats = 4 },
                { model = 'seminole', label = 'Field SUV', speed = 175, seats = 4 },
                { model = 'burrito3', label = 'Surveillance Van', speed = 140, seats = 4 },
                { model = 'huntley', label = 'Field SUV', speed = 170, seats = 4 },
                { model = 'patriot3', label = 'CID Surveillance', speed = 160, seats = 4 },
                { model = 'stretch', label = 'CID Command', speed = 190, seats = 6 },
            }
        }
    },

    SpawnSettings = {
        deleteOldVehicle = true,
        spawnInside = false,
        godMode = false,
        platePrefix = 'CID',
        fuelLevel = 100.0,
        bodyHealth = 1000.0,
        engineHealth = 1000.0,
        impoundOnDutyEnd = true,
        dutyRequired = true
    },

    Locations = {
        CIDHQ = {
            coords = vector3(100.0, -730.0, 44.0),
            spawns = {
                { coords = vector3(95.0, -725.0, 44.0), heading = 90.0 },
                { coords = vector3(99.0, -725.0, 44.0), heading = 90.0 },
                { coords = vector3(103.0, -725.0, 44.0), heading = 90.0 },
                { coords = vector3(107.0, -725.0, 44.0), heading = 90.0 },
            },
            deleteZone = vector3(100.0, -735.0, 44.0)
        }
    },

    Liveries = {
        { livery = 0, label = 'Unmarked' },
        { livery = 1, label = 'CID Marked' },
        { livery = 2, label = 'Slicktop' }
    },

    Extras = {
        lightbar = { extraId = 1, label = 'Lightbar' },
        pushbar = { extraId = 2, label = 'Push Bar' },
        computer = { extraId = 3, label = 'MDT' },
    },

    TargetOptions = {
        icon = 'fas fa-car-side',
        label = 'CID Garage',
        group = 'cid',
        distance = 3.0,
        deleteIcon = 'fas fa-trash',
        deleteLabel = 'Store Vehicle'
    }
}
