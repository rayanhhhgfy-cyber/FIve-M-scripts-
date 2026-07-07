Config = Config or {}

Config.Restaurants = {
    {
        name = 'burger_shot',
        label = 'Burger Shot',
        coords = vector3(-1197.18, -893.56, 14.14),
        stations = {
            register = vector3(-1194.87, -892.26, 13.99),
            grill = vector3(-1198.47, -895.56, 14.14),
            prep = vector3(-1195.34, -898.04, 14.14),
            counter = vector3(-1194.87, -892.26, 13.99),
        },
        menu = {
            { name = 'heart_stopper', label = 'Heart Stopper Burger', price = 15, time = 5000 },
            { name = 'moneyshot', label = 'Moneyshot Burger', price = 12, time = 4000 },
            { name = 'fries', label = 'Large Fries', price = 5, time = 2000 },
            { name = 'soda', label = 'Soda', price = 3, time = 1000 },
        },
        requiredJob = 'burger_shot',
        payment = 50,
    },
    {
        name = 'upnatom',
        label = 'Up-n-Atom',
        coords = vector3(810.06, -753.32, 26.78),
        stations = {
            register = vector3(813.04, -750.41, 26.78),
            grill = vector3(807.77, -753.89, 26.78),
            prep = vector3(808.95, -756.88, 26.78),
            counter = vector3(813.04, -750.41, 26.78),
        },
        menu = {
            { name = 'atomic_burger', label = 'Atomic Burger', price = 18, time = 5000 },
            { name = 'tender_burger', label = 'Tender Burger', price = 14, time = 4000 },
            { name = 'rings', label = 'Onion Rings', price = 5, time = 2000 },
            { name = 'cola', label = 'Cola', price = 3, time = 1000 },
        },
        requiredJob = 'upnatom',
        payment = 55,
    },
}

Config.Rewards = {
    heart_stopper = { item = 'heart_stopper', min = 1, max = 1 },
    moneyshot = { item = 'moneyshot', min = 1, max = 1 },
    fries = { item = 'fries', min = 1, max = 1 },
    soda = { item = 'soda', min = 1, max = 1 },
    atomic_burger = { item = 'atomic_burger', min = 1, max = 1 },
    tender_burger = { item = 'tender_burger', min = 1, max = 1 },
    rings = { item = 'rings', min = 1, max = 1 },
    cola = { item = 'cola', min = 1, max = 1 },
}
