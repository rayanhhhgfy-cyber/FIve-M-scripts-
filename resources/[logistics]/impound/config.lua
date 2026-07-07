Config = Config or {}

Config.Impound = {
    ImpoundTime = 86400,
    ReleaseFee = 500,
    PoliceFee = 250,
    MaxStored = 50,
    ImpoundDuration = 604800,

    Locations = {
        Police = {
            coords = vector3(410.0, -1000.0, 26.0),
            spawns = {
                { coords = vector3(415.0, -1005.0, 25.5), heading = 90.0 },
                { coords = vector3(420.0, -1005.0, 25.5), heading = 90.0 },
                { coords = vector3(425.0, -1005.0, 25.5), heading = 90.0 }
            },
            label = 'Police Impound'
        },
        City = {
            coords = vector3(830.0, -1150.0, 25.0),
            spawns = {
                { coords = vector3(835.0, -1155.0, 25.0), heading = 0.0 },
                { coords = vector3(840.0, -1155.0, 25.0), heading = 0.0 },
                { coords = vector3(845.0, -1155.0, 25.0), heading = 0.0 }
            },
            label = 'City Impound'
        }
    },

    Blips = {
        { coords = vector3(410.0, -1000.0, 26.0), sprite = 68, color = 38, scale = 0.8, label = 'Police Impound' },
        { coords = vector3(830.0, -1150.0, 25.0), sprite = 68, color = 5, scale = 0.8, label = 'City Impound' }
    },

    TargetOptions = {
        impound = { icon = 'fas fa-warehouse', label = 'Impound Lot', distance = 3.0 },
        retrieve = { icon = 'fas fa-car', label = 'Retrieve Vehicle', distance = 3.0 },
        policeImpound = { icon = 'fas fa-gavel', label = 'Impound Vehicle', group = 'police', distance = 3.0 }
    },

    ImpoundReasons = {
        { id = 'illegal_parking', label = 'Illegal Parking', fee = 200 },
        { id = 'no_insurance', label = 'No Insurance', fee = 500 },
        { id = 'expired_reg', label = 'Expired Registration', fee = 300 },
        { id = 'abandoned', label = 'Abandoned Vehicle', fee = 400 },
        { id = 'evidence', label = 'Evidence Hold', fee = 0 },
        { id = 'police_order', label = 'Police Order', fee = 250 }
    }
}
