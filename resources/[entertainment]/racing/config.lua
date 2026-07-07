Config = Config or {}

Config.Racing = {
    meetLocations = {
        vector3(-1450.67, -450.34, 35.00),
        vector3(400.34, -1200.56, 29.00),
        vector3(1200.45, 300.67, 50.00),
    },
    tracks = {
        {
            name = 'Highway Sprint',
            checkpoints = {
                vector3(-1450.67, -450.34, 35.00),
                vector3(-1200.00, -300.00, 35.00),
                vector3(-900.00, -200.00, 35.00),
                vector3(-600.00, -100.00, 35.00),
            },
            laps = 1,
            minBet = 100,
            maxBet = 5000,
        },
        {
            name = 'City Circuit',
            checkpoints = {
                vector3(400.34, -1200.56, 29.00),
                vector3(500.00, -1000.00, 29.00),
                vector3(700.00, -900.00, 29.00),
                vector3(600.00, -1100.00, 29.00),
            },
            laps = 3,
            minBet = 50,
            maxBet = 2000,
        },
    },
    defaultPayoutMultiplier = 0.8,
    maxRacers = 8,
    countdownTime = 5,
}
