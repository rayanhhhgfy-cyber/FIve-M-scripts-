Config = Config or {}

Config.MiniGames = {
    darts = {
        locations = {
            vector3(756.45, -787.34, 26.00),
            vector3(-554.67, 289.34, 82.00),
        },
        maxScore = 501,
        startingScore = 501,
        doublesRequired = true,
        ocheDistance = 2.0,
        boardCoords = {
            vector3(754.00, -786.00, 27.00),
            vector3(-556.00, 290.00, 83.00),
        },
    },
    pool = {
        locations = {
            vector3(760.00, -785.00, 25.50),
            vector3(-560.00, 292.00, 82.00),
        },
        maxPlayers = 2,
        type = 'eight_ball',
    },
    chess = {
        locations = {
            vector3(758.00, -783.00, 25.50),
        },
    },
}
