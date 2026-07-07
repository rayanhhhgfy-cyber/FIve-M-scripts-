Config = Config or {}
Config.UndercoverVehicles = Config.UndercoverVehicles or {}

Config.UndercoverVehicles = {
    AllowedJobs = { 'cid' },
    MinRank = 0,
    TrackerRange = 100.0,
    SignalScannerRange = 100.0,
    IdentitySwapDuration = 2000,
    TrackerDeployDuration = 3000,
    TrackerSweepDuration = 3000,
    GpsSyncInterval = 30000,

    Locations = {
        CIDHQ = {
            coords = vector3(100.0, -730.0, 44.0),
            label = 'CID HQ Underground',
            spawns = {
                { coords = vector3(90.0, -720.0, 44.0), heading = 90.0 },
                { coords = vector3(94.0, -720.0, 44.0), heading = 90.0 },
                { coords = vector3(98.0, -720.0, 44.0), heading = 90.0 },
                { coords = vector3(102.0, -720.0, 44.0), heading = 90.0 },
                { coords = vector3(106.0, -720.0, 44.0), heading = 90.0 },
                { coords = vector3(110.0, -720.0, 44.0), heading = 90.0 },
            }
        },
        Satellite1 = {
            coords = vector3(-1040.0, -2750.0, 14.0),
            label = 'Airport Lot',
            spawns = {
                { coords = vector3(-1045.0, -2745.0, 14.0), heading = 180.0 },
                { coords = vector3(-1050.0, -2745.0, 14.0), heading = 180.0 },
                { coords = vector3(-1055.0, -2745.0, 14.0), heading = 180.0 },
            }
        },
        Satellite2 = {
            coords = vector3(1502.0, 3921.0, 31.0),
            label = 'Sandy Shores Lot',
            spawns = {
                { coords = vector3(1507.0, 3921.0, 31.0), heading = 0.0 },
                { coords = vector3(1512.0, 3921.0, 31.0), heading = 0.0 },
                { coords = vector3(1497.0, 3921.0, 31.0), heading = 0.0 },
            }
        }
    },

    Vehicles = {
        { model = 'asea', label = 'Asea', speed = 160, seats = 4 },
        { model = 'asterope', label = 'Asterope', speed = 170, seats = 4 },
        { model = 'blista', label = 'Blista', speed = 155, seats = 2 },
        { model = 'calico', label = 'Calico GTF', speed = 200, seats = 2 },
        { model = 'cavalcade', label = 'Cavalcade', speed = 165, seats = 8 },
        { model = 'cossie', label = 'Cossie', speed = 195, seats = 2 },
        { model = 'jester', label = 'Jester', speed = 210, seats = 2 },
        { model = 'kuruma', label = 'Kuruma', speed = 180, seats = 4 },
        { model = 'oracle', label = 'Oracle XS', speed = 190, seats = 4 },
        { model = 'sultan', label = 'Sultan Classic', speed = 185, seats = 4 },
        { model = 'tailgater', label = 'Tailgater', speed = 175, seats = 4 },
        { model = 'washington', label = 'Washington', speed = 165, seats = 4 },
    },

    Identities = {
        {
            label = 'Identity 1 - Clean',
            platePrefix = 'CIV',
            livery = 0,
        },
        {
            label = 'Identity 2 - Cover',
            platePrefix = 'COV',
            livery = 1,
        },
        {
            label = 'Identity 3 - Deep',
            platePrefix = 'DP',
            livery = 2,
        },
    },

    HiddenExtras = {
        lightbar = { extraId = 1, label = 'Hidden Lightbar', key = 'H' },
        siren = { extraId = 2, label = 'Siren', key = 'J' },
        silentMode = { extraId = 3, label = 'Silent Mode', key = 'K' },
    },

    MarkerColors = {
        friendly = { r = 0, g = 255, b = 0 },
        hostile = { r = 255, g = 0, b = 0 },
        tracker = { r = 255, g = 200, b = 0 },
    }
}
