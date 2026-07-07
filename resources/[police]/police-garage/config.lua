Config = Config or {}

Config.PoliceGarage = {
    Categories = {
        PoliceBikes = {
            label = 'Police Motorcycles',
            rank = 2,
            vehicles = {
                { model = 'policeb', label = 'Stock Police Bike', speed = 210, seats = 2 },
                { model = '1200RT', label = 'BMW R1200RT', speed = 220, seats = 2 },
                { model = 'bmwrp', label = 'BMW R Police', speed = 210, seats = 2 },
                { model = 'hpbikes', label = 'HP Police Bike', speed = 230, seats = 2 },
                { model = 'pbike', label = 'Police Bike', speed = 200, seats = 2 },
                { model = 'zzninja33', label = 'Kawasaki Ninja', speed = 235, seats = 2 },
            }
        },
        Patrol = {
            label = 'Patrol Vehicles',
            rank = 0,
            vehicles = {
                { model = 'police', label = 'Police Cruiser', speed = 180, seats = 4 },
                { model = 'police2', label = 'Police SUV', speed = 170, seats = 6 },
                { model = 'police3', label = 'Police Interceptor', speed = 200, seats = 4 },
                { model = 'police4', label = 'Undercover', speed = 190, seats = 4 },
                { model = 'policet', label = 'Police Transporter', speed = 150, seats = 6 },
                { model = 'sheriff2', label = 'Sheriff Cruiser', speed = 175, seats = 4 },
                { model = 'sheriff3', label = 'Sheriff Slicktop', speed = 180, seats = 4 },
            }
        },
        SRT = {
            label = 'Special Response',
            rank = 3,
            vehicles = {
                { model = 'policeb', label = 'Police Bike', speed = 210, seats = 2 },
                { model = 'riot', label = 'Armored Truck', speed = 140, seats = 8 },
                { model = 'sheriff', label = 'Sheriff SUV', speed = 175, seats = 6 },
                { model = 'blazer', label = 'Police ATV', speed = 120, seats = 2 },
                { model = 'scorcher', label = 'Mountain Bike', speed = 50, seats = 1 },
            }
        },
        Helicopters = {
            label = 'Air Support',
            rank = 3,
            vehicles = {
                { model = 'polmav', label = 'Police Maverick', speed = 160, seats = 4 },
                { model = 'buzzard', label = 'Buzzard', speed = 180, seats = 2 },
                { model = 'frogger', label = 'Frogger', speed = 170, seats = 4 },
                { model = 'seasparrow', label = 'Sea Sparrow', speed = 165, seats = 2 },
                { model = 'valkyrie', label = 'Transport Heli', speed = 155, seats = 8 },
                { model = 'buzzard2', label = 'Armed Buzzard', speed = 190, seats = 2 },
            }
        },
        AttackHeli = {
            label = 'Attack Helicopters',
            rank = 4,
            vehicles = {
                { model = 'hunter', label = 'Hunter Attack Heli', speed = 200, seats = 2 },
                { model = 'akula', label = 'Akula Stealth Heli', speed = 195, seats = 2 },
                { model = 'savage', label = 'Savage Attack Heli', speed = 185, seats = 2 },
                { model = 'annihilator', label = 'Annihilator Gunship', speed = 175, seats = 6 },
            }
        },
        TacticalAir = {
            label = 'Tactical Air Command',
            rank = 4,
            vehicles = {
                { model = 'hydra', label = 'Hydra VTOL Jet', speed = 250, seats = 1 },
                { model = 'lazer', label = 'P-996 Lazer', speed = 260, seats = 1 },
                { model = 'b11_strikeforce', label = 'B-11 Strikeforce', speed = 230, seats = 2 },
                { model = 'besra', label = 'Besra Trainer Jet', speed = 220, seats = 1 },
            }
        },
        Marine = {
            label = 'Marine Unit',
            rank = 3,
            vehicles = {
                { model = 'predator', label = 'Police Boat', speed = 150, seats = 4 },
                { model = 'seashark', label = 'Seashark', speed = 120, seats = 2 },
                { model = 'speeder', label = 'Patrol Speeder', speed = 140, seats = 4 },
            }
        },
        Unmarked = {
            label = 'Unmarked / Detective',
            rank = 2,
            vehicles = {
                { model = 'policeold1', label = 'Stanier LE', speed = 180, seats = 4 },
                { model = 'policeold2', label = 'Buffalo LE', speed = 195, seats = 4 },
                { model = 'stanier', label = 'Unmarked Sedan', speed = 185, seats = 4 },
                { model = 'schafter5', label = 'Pursuit Sedan', speed = 200, seats = 4 },
                { model = 'tolcharger2', label = 'Charger UC', speed = 210, seats = 4 },
                { model = 'toldemon', label = 'Demon UC', speed = 215, seats = 2 },
                { model = 'tolaudidy', label = 'Audi UC', speed = 205, seats = 4 },
                { model = 'tols63amg', label = 'AMG S63 UC', speed = 215, seats = 4 },
                { model = 'tolc63', label = 'C63 AMG UC', speed = 210, seats = 4 },
            }
        },
        Intercept = {
            label = 'Intercept Division',
            rank = 2,
            vehicles = {
                { model = 'police3', label = 'Interceptor Pursuit', speed = 220, seats = 4 },
                { model = 'buffalo3', label = 'Gauntlet Interceptor', speed = 215, seats = 4 },
                { model = 'schafter2', label = 'Schafter SRT', speed = 210, seats = 4 },
                { model = 'seminole', label = 'Seminole Scout', speed = 190, seats = 6 },
                { model = 'cheetah2', label = 'Cheetah Pursuit', speed = 225, seats = 2 },
                { model = 'komoda', label = 'Komoda Urban', speed = 200, seats = 4 },
                { model = 'jugular', label = 'Jugular Heavy', speed = 215, seats = 4 },
            }
        },
        Armored = {
            label = 'Tactical Armored',
            rank = 4,
            vehicles = {
                { model = 'riot', label = 'Riot Truck', speed = 140, seats = 8 },
                { model = 'insurgent', label = 'BearCat', speed = 150, seats = 6 },
                { model = 'nightshark', label = 'Nightshark APC', speed = 160, seats = 4 },
                { model = 'barracks', label = 'LSPD MRAP', speed = 120, seats = 10 },
                { model = 'barracks2', label = 'Tactical Transport', speed = 125, seats = 10 },
                { model = 'patriot', label = 'Armored Scout', speed = 145, seats = 4 },
                { model = 'speedo', label = 'Tactical Response Van', speed = 135, seats = 6 },
            }
        }
    },

    SpawnSettings = {
        deleteOldVehicle = true,
        spawnInside = false,
        godMode = false,
        platePrefix = 'PD',
        fuelLevel = 100.0,
        bodyHealth = 1000.0,
        engineHealth = 1000.0,
        impoundOnDutyEnd = true,
        dutyRequired = true
    },

    Locations = {
        MRPD = {
            coords = vector3(454.5, -999.0, 25.8),
            spawns = {
                { coords = vector3(443.0, -1007.5, 26.0), heading = 90.0 },
                { coords = vector3(447.0, -1007.5, 26.0), heading = 90.0 },
                { coords = vector3(451.0, -1007.5, 26.0), heading = 90.0 },
                { coords = vector3(455.0, -1007.5, 26.0), heading = 90.0 },
                { coords = vector3(459.0, -1007.5, 26.0), heading = 90.0 }
            },
            heliSpawns = {
                { coords = vector3(449.0, -981.0, 43.7), heading = 0.0 }
            },
            deleteZone = vector3(450.0, -1010.0, 26.0)
        },
        Davis = {
            coords = vector3(368.0, -1612.0, 22.5),
            spawns = {
                { coords = vector3(360.0, -1615.0, 22.5), heading = 90.0 },
                { coords = vector3(364.0, -1615.0, 22.5), heading = 90.0 },
                { coords = vector3(368.0, -1615.0, 22.5), heading = 90.0 },
                { coords = vector3(372.0, -1615.0, 22.5), heading = 90.0 }
            },
            heliSpawns = {
                { coords = vector3(361.0, -1590.0, 28.0), heading = 0.0 },
            },
            deleteZone = vector3(365.0, -1618.0, 22.5)
        },
        SandyShores = {
            coords = vector3(1850.0, 3690.0, 34.0),
            spawns = {
                { coords = vector3(1855.0, 3685.0, 34.0), heading = 180.0 },
                { coords = vector3(1855.0, 3695.0, 34.0), heading = 180.0 },
            },
            heliSpawns = {
                { coords = vector3(1850.0, 3705.0, 38.0), heading = 180.0 },
            },
            deleteZone = vector3(1855.0, 3680.0, 34.0)
        },
        Paleto = {
            coords = vector3(-240.0, 6325.0, 32.0),
            spawns = {
                { coords = vector3(-235.0, 6320.0, 32.0), heading = 90.0 },
                { coords = vector3(-245.0, 6320.0, 32.0), heading = 90.0 },
            },
            heliSpawns = {
                { coords = vector3(-240.0, 6340.0, 36.0), heading = 0.0 },
            },
            deleteZone = vector3(-235.0, 6315.0, 32.0)
        },
        Airport = {
            coords = vector3(-1056.0, -2363.0, 14.0),
            spawns = {
                { coords = vector3(-1060.0, -2360.0, 14.0), heading = 0.0 },
                { coords = vector3(-1060.0, -2366.0, 14.0), heading = 0.0 }
            },
            heliSpawns = {
                { coords = vector3(-1050.0, -2370.0, 14.5), heading = 0.0 },
            },
            deleteZone = vector3(-1056.0, -2368.0, 14.0)
        }
    },

    Liveries = {
        { livery = 0, label = 'Standard' },
        { livery = 1, label = 'Slicktop' },
        { livery = 2, label = 'Unmarked' }
    },

    Extras = {
        lightbar = { extraId = 1, label = 'Lightbar' },
        pushbar = { extraId = 2, label = 'Push Bar' },
        cage = { extraId = 3, label = 'Partition' },
        computer = { extraId = 4, label = 'MDT' },
        rifleRack = { extraId = 5, label = 'Rifle Rack' }
    },

    ImpoundReasons = {
        { id = 'no_insurance', label = 'No Insurance', fee = 500 },
        { id = 'expired_reg', label = 'Expired Registration', fee = 350 },
        { id = 'suspended_license', label = 'Suspended License', fee = 750 },
        { id = 'stolen', label = 'Stolen Vehicle', fee = 0 },
        { id = 'illegal_parking', label = 'Illegal Parking', fee = 250 },
        { id = 'reckless_driving', label = 'Reckless Driving', fee = 600 },
        { id = 'evidence', label = 'Evidence Hold', fee = 0 },
        { id = 'other', label = 'Other Violation', fee = 400 }
    },

    TargetOptions = {
        icon = 'fas fa-car-side',
        label = 'Police Garage',
        group = 'police',
        distance = 3.0,
        deleteIcon = 'fas fa-trash',
        deleteLabel = 'Store Vehicle'
    }
}
