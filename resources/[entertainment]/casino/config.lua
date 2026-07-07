Config = Config or {}

Config.Casino = {
    loc = vector3(966.21, 26.44, 81.12),
    chipItem = 'casino_chip',
    minBuyIn = 100,
    maxBuyIn = 10000,
    tables = {
        blackjack = { coords = vector3(964.00, 28.00, 81.12), label = 'Blackjack' },
        roulette = { coords = vector3(968.00, 30.00, 81.12), label = 'Roulette' },
        slots = { coords = vector3(970.00, 24.00, 81.12), label = 'Slot Machine' },
    },
    blackjackPayout = 2.0,
    roulettePayouts = { single = 35, split = 17, corner = 8, red = 2, black = 2, odd = 2, even = 2 },
    slotPayouts = {
        { combination = { 'cherry', 'cherry', 'cherry' }, multiplier = 50 },
        { combination = { 'bell', 'bell', 'bell' }, multiplier = 25 },
        { combination = { 'bar', 'bar', 'bar' }, multiplier = 10 },
        { combination = { 'seven', 'seven', 'seven' }, multiplier = 100 },
    },
}
