Config = Config or {}

Config.Arcade = {
    locations = {
        vector3(336.45, -777.23, 29.34),
    },
    machines = {
        { coords = vector3(338.00, -775.00, 29.34), game = 'snake', label = 'Snake' },
        { coords = vector3(340.00, -775.00, 29.34), game = 'tetris', label = 'Tetris' },
        { coords = vector3(342.00, -775.00, 29.34), game = 'pong', label = 'Pong' },
    },
    costPerPlay = 5,
    highScoreLimit = 10,
}
