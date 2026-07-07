Config = Config or {}

Config.ArtHeist = {
    MinPolice = 4,
    Cooldown = 1800,
    HackingTime = 15000,
    DrillTime = 20000,
    LaserDisarmTime = 5000,
    PoliceAlertChance = 0.80,

    Locations = {
        { coords = vector3(-530.0, 210.0, 55.0), label = 'Los Santos Art Gallery', model = 'gabz_mm_museum' },
        { coords = vector3(130.0, -760.0, 200.0), label = 'Kortz Center', model = 'gabz_mm_museum' }
    },

    Paintings = {
        { name = 'The Lost Canvas', value = 15000, model = 'h4_prop_h4_painting_01a' },
        { name = 'Blue Period', value = 12000, model = 'h4_prop_h4_painting_02a' },
        { name = 'Sunset Over LS', value = 18000, model = 'h4_prop_h4_painting_03a' },
        { name = 'Abstract Mind', value = 10000, model = 'h4_prop_h4_painting_04a' },
        { name = 'Portrait of a King', value = 22000, model = 'h4_prop_h4_painting_05a' }
    },

    LaserGrid = {
        sections = 4,
        disarmed = {},
        duration = 8000,
        difficulty = 'hard'
    },

    RequiredItems = {
        hackingDevice = 'Hacking Device',
        drillingTool = 'Advanced Drill',
        wireCutters = 'Wire Cutters'
    },

    Rewards = {
        paintings = { min = 1, max = 3 },
        cash = { min = 5000, max = 15000 }
    },

    Escape = {
        timeout = 300,
        radius = 100.0
    },

    TargetOptions = {
        hackPanel = { icon = 'fas fa-microchip', label = 'Hack Security Panel', distance = 1.5 },
        disableLaser = { icon = 'fas fa-bolt', label = 'Disable Laser', distance = 2.0 },
        removePainting = { icon = 'fas fa-palette', label = 'Remove Painting', distance = 1.5 }
    }
}
