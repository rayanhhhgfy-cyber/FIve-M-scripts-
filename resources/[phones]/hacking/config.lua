Config = Config or {}

Config.Hacking = {
    AppName = 'Hacking Tool',
    ItemName = 'hacking_tool',
    ItemLabel = 'Hacking Tool',
    RequireItem = true,
    MinAttempts = 3,
    MaxAttempts = 8,
    AttemptTime = 15000,

    DifficultyLevels = {
        easy = { label = 'Easy', attempts = 4, time = 10000, reward = 1000 },
        medium = { label = 'Medium', attempts = 6, time = 15000, reward = 2500 },
        hard = { label = 'Hard', attempts = 8, time = 20000, reward = 5000 },
        expert = { label = 'Expert', attempts = 10, time = 25000, reward = 10000 }
    },

    HackingTypes = {
        phone = { label = 'Phone Breach', difficulty = 'easy', jailTime = 120 },
        terminal = { label = 'Terminal Hack', difficulty = 'medium', jailTime = 300 },
        server = { label = 'Server Infiltration', difficulty = 'hard', jailTime = 600 },
        network = { label = 'Network Crack', difficulty = 'expert', jailTime = 1200 }
    },

    Minigame = {
        GridSize = 4,
        Symbols = { '0', '1', '#' },
        BufferSize = 4,
        SequenceLength = 6,
        DecayRate = 0.1
    }
}
