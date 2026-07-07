Config = Config or {}

Config.FIB = {
    entrance = {
        coords = vector3(135.0, -749.0, 45.0),
        heading = 0.0,
        label = 'FIB Building',
    },
    interior = {
        coords = vector3(110.0, -740.0, 42.0),
        heading = 180.0,
    },

    doors = {
        {
            name = 'main_entrance',
            label = 'FIB Main Entrance',
            coords = vector3(135.0, -749.0, 45.0),
            defaultLocked = false,
        },
    },

    elevator = {
        coords = vector3(110.0, -738.0, 42.0),
        heading = 0.0,
        travelTimePerFloor = 1200,
        floors = {
            { name = 'lobby', label = 'Lobby', coords = vector3(110.0, -740.0, 42.0), heading = 180.0, minRank = 0 },
            { name = 'offices', label = 'Offices', coords = vector3(115.0, -745.0, 48.0), heading = 180.0, minRank = 0 },
            { name = 'armory', label = 'Armory / Evidence', coords = vector3(110.0, -730.0, 36.0), heading = 0.0, minRank = 2 },
            { name = 'interrogation', label = 'Interrogation', coords = vector3(105.0, -750.0, 54.0), heading = 0.0, minRank = 1 },
            { name = 'server', label = 'Server Room', coords = vector3(120.0, -735.0, 30.0), heading = 90.0, minRank = 3 },
            { name = 'roof', label = 'Roof / Helipad', coords = vector3(135.0, -760.0, 62.0), heading = 0.0, minRank = 3 },
        },
    },

    computers = {
        { name = 'lobby_terminal', label = 'FIB Terminal', coords = vector3(108.0, -742.0, 42.0), heading = 0.0 },
    },

    allowedJobs = { 'police', 'cid' },
    restrictedJobs = { 'cid' },
    canToggleDoors = { 'cid', 'police' },
}
