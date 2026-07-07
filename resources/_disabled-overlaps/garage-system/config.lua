Config = Config or {}

Config.Garages = {
    Personal = {
        {
            name = 'Personal Garage 1',
            coords = vec3(215.79, -808.57, 30.72),
            spawn = vec4(222.0, -809.0, 30.72, 160.0),
            type = 'personal',
            slots = 10,
            blip = { sprite = 357, color = 3, scale = 0.6, label = 'Personal Garage' }
        },
        {
            name = 'Personal Garage 2',
            coords = vec3(-339.78, -875.56, 31.08),
            spawn = vec4(-335.0, -880.0, 31.08, 180.0),
            type = 'personal',
            slots = 10,
            blip = { sprite = 357, color = 3, scale = 0.6, label = 'Personal Garage' }
        },
        {
            name = 'Personal Garage 3',
            coords = vec3(68.99, 12.43, 69.21),
            spawn = vec4(73.0, 15.0, 69.21, 160.0),
            type = 'personal',
            slots = 10,
            blip = { sprite = 357, color = 3, scale = 0.6, label = 'Personal Garage' }
        }
    },
    Public = {
        {
            name = 'Public Parking A',
            coords = vec3(-266.78, -958.4, 30.93),
            spawn = vec4(-270.0, -955.0, 30.93, 0.0),
            type = 'public',
            slots = 2,
            blip = { sprite = 357, color = 5, scale = 0.5, label = 'Public Parking' }
        },
        {
            name = 'Public Parking B',
            coords = vec3(1157.63, -1825.59, 36.58),
            spawn = vec4(1160.0, -1828.0, 36.58, 270.0),
            type = 'public',
            slots = 2,
            blip = { sprite = 357, color = 5, scale = 0.5, label = 'Public Parking' }
        },
        {
            name = 'Public Parking C',
            coords = vec3(-1069.66, -2110.82, 13.73),
            spawn = vec4(-1065.0, -2112.0, 13.73, 90.0),
            type = 'public',
            slots = 2,
            blip = { sprite = 357, color = 5, scale = 0.5, label = 'Public Parking' }
        }
    },
    Apartment = {
        {
            name = 'Apartment Garage A',
            coords = vec3(-346.89, -381.36, 35.60),
            spawn = vec4(-350.0, -378.0, 35.60, 0.0),
            type = 'apartment',
            slots = 5,
            blip = { sprite = 357, color = 47, scale = 0.5, label = 'Apartment Garage' }
        },
        {
            name = 'Apartment Garage B',
            coords = vec3(-666.84, -930.35, 21.83),
            spawn = vec4(-662.0, -932.0, 21.83, 0.0),
            type = 'apartment',
            slots = 5,
            blip = { sprite = 357, color = 47, scale = 0.5, label = 'Apartment Garage' }
        }
    },
    Impound = {
        {
            name = 'Police Impound Lot',
            coords = vec3(436.08, -987.27, 29.69),
            spawn = vec4(440.0, -990.0, 29.69, 90.0),
            type = 'impound',
            blip = { sprite = 68, color = 1, scale = 0.6, label = 'Impound Lot' }
        },
        {
            name = 'Airport Impound',
            coords = vec3(-1067.8, -2661.7, 13.94),
            spawn = vec4(-1065.0, -2665.0, 13.94, 0.0),
            type = 'impound',
            blip = { sprite = 68, color = 1, scale = 0.6, label = 'Impound Lot' }
        }
    }
}

Config.GarageSettings = {
    ImpoundFeePerMinute = 10,
    MaxImpoundFee = 5000,
    ImpoundGraceMinutes = 5,
    VehicleSpawnDistance = 8.0,
    StoreVehicleRadius = 10.0,
    PersonalSlots = 10,
    ApartmentSlots = 5,
    PublicSlots = 2,
    DespawnStoredVehicleDelay = 3000,
    ImpoundCooldownHours = 48
}
