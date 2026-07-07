Config = Config or {}
Config.Doorlock = {
    doors = {
        {
            id = 'police_entrance',
            label = 'Police Station Entrance',
            model = -1501157055,
            coords = vector3(434.0, -982.0, 30.0),
            locked = true,
            groups = { 'police', 'sheriff' },
            jobLevel = 0,
        },
        {
            id = 'pd_armory',
            label = 'Armory',
            model = -1501157055,
            coords = vector3(445.0, -976.0, 30.0),
            locked = true,
            groups = { 'police' },
            jobLevel = 1,
        },
    },
    maxDistance = 2.5,
    autolockTime = 30,
}
