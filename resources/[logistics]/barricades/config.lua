Config = Config or {}

Config.Barricades = {
    MaxActive = 10,
    DeployTime = 3000,
    PickupTime = 2000,
    DespawnTime = 600,
    RequireJob = false,
    AllowedJobs = { 'police', 'tow' },

    Types = {
        cone = { model = 'prop_roadcone02a', label = 'Road Cone', deployTime = 1500, limit = 10 },
        barrier = { model = 'prop_barrier_work05', label = 'Barrier', deployTime = 3000, limit = 5 },
        fence = { model = 'prop_fncsec_08b', label = 'Metal Fence', deployTime = 4000, limit = 3 },
        light = { model = 'prop_worklight_03a', label = 'Work Light', deployTime = 2500, limit = 4 },
        sign = { model = 'prop_sign_road_03a', label = 'Road Sign', deployTime = 2000, limit = 6 }
    },

    TargetOptions = {
        deploy = { icon = 'fas fa-traffic-cone', label = 'Deploy Barricade', distance = 2.0 },
        pickup = { icon = 'fas fa-hand', label = 'Remove', distance = 2.0 },
        menu = { icon = 'fas fa-tools', label = 'Barricade Menu', distance = 2.5 }
    },

    UI = {
        ShowCount = true,
        Color = { r = 255, g = 165, b = 0 }
    }
}
