local QBCore = exports['qbx-core']:GetCoreObject()
local RATE_LIMITS = {}

local function checkRateLimit(src, action, maxPerMin)
    local key = src .. ':' .. action
    local now = os.time()
    if not RATE_LIMITS[key] then
        RATE_LIMITS[key] = { count = 1, start = now }
        return true
    end
    if now - RATE_LIMITS[key].start >= 60 then
        RATE_LIMITS[key] = { count = 1, start = now }
        return true
    end
    if RATE_LIMITS[key].count >= maxPerMin then
        return false
    end
    RATE_LIMITS[key].count = RATE_LIMITS[key].count + 1
    return true
end

local function hasChips(src, amount)
    local count = exports.ox_inventory:Search(src, 'count', Config.Casino.chipItem)
    return (count or 0) >= amount
end

local function removeChips(src, amount)
    exports.ox_inventory:RemoveItem(src, Config.Casino.chipItem, amount)
end

local function addChips(src, amount)
    exports.ox_inventory:AddItem(src, Config.Casino.chipItem, amount)
end

local SUITS = { 'hearts', 'diamonds', 'clubs', 'spades' }
local RANKS = { '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A' }
local RANK_VALUES = { ['2'] = 2, ['3'] = 3, ['4'] = 4, ['5'] = 5, ['6'] = 6, ['7'] = 7, ['8'] = 8, ['9'] = 9, ['10'] = 10, ['J'] = 10, ['Q'] = 10, ['K'] = 10, ['A'] = 11 }

local function createDeck()
    local deck = {}
    for _, suit in ipairs(SUITS) do
        for _, rank in ipairs(RANKS) do
            table.insert(deck, { suit = suit, rank = rank, value = RANK_VALUES[rank] })
        end
    end
    return deck
end

local function shuffleDeck(deck)
    for i = #deck, 2, -1 do
        local j = math.random(i)
        deck[i], deck[j] = deck[j], deck[i]
    end
    return deck
end

local function handValue(hand)
    local total = 0
    local aces = 0
    for _, card in ipairs(hand) do
        total = total + card.value
        if card.rank == 'A' then aces = aces + 1 end
    end
    while total > 21 and aces > 0 do
        total = total - 10
        aces = aces - 1
    end
    return total
end

local function dealCard(deck)
    return table.remove(deck)
end

local ROULETTE_NUMBERS = { 0, 32, 15, 19, 4, 21, 2, 25, 17, 34, 6, 27, 13, 36, 11, 30, 8, 23, 10, 5, 24, 16, 33, 1, 20, 14, 31, 9, 22, 18, 29, 7, 28, 12, 35, 3, 26 }
local RED_NUMBERS = { 1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36 }

local function isRed(num)
    for _, n in ipairs(RED_NUMBERS) do
        if n == num then return true end
    end
    return false
end

local SLOT_SYMBOLS = { 'cherry', 'bell', 'bar', 'seven', 'lemon', 'orange' }

local function spinReels()
    local a = SLOT_SYMBOLS[math.random(#SLOT_SYMBOLS)]
    local b = SLOT_SYMBOLS[math.random(#SLOT_SYMBOLS)]
    local c = SLOT_SYMBOLS[math.random(#SLOT_SYMBOLS)]
    return { a, b, c }
end

local function getSlotMultiplier(reels)
    for _, payout in ipairs(Config.Casino.slotPayouts) do
        if reels[1] == payout.combination[1] and reels[2] == payout.combination[2] and reels[3] == payout.combination[3] then
            return payout.multiplier
        end
    end
    return 0
end

RegisterNetEvent('casino:buyChips', function(data)
    local src = source
    if type(data) ~= 'table' or type(data.amount) ~= 'number' then
        return
    end
    if not checkRateLimit(src, 'buyChips', 5) then
        Wrappers.Notify(src, Locale('error.rate_limit'), 'error')
        return
    end
    local amount = math.floor(data.amount)
    if amount < Config.Casino.minBuyIn or amount > Config.Casino.maxBuyIn then
        Wrappers.Notify(src, Locale('casino.not_enough'), 'error')
        return
    end
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    local cash = Player.PlayerData.money.cash or 0
    if cash < amount then
        Wrappers.Notify(src, Locale('casino.not_enough'), 'error')
        return
    end
    Player.Functions.RemoveMoney('cash', amount, nil)
    addChips(src, amount)
    Wrappers.Notify(src, Locale('casino.buy_chips'), 'success')
end)

RegisterNetEvent('casino:cashChips', function(data)
    local src = source
    if type(data) ~= 'table' or type(data.amount) ~= 'number' then
        return
    end
    if not checkRateLimit(src, 'cashChips', 5) then
        Wrappers.Notify(src, Locale('error.rate_limit'), 'error')
        return
    end
    local amount = math.floor(data.amount)
    if amount < 1 then return end
    if not hasChips(src, amount) then
        Wrappers.Notify(src, Locale('casino.no_chips'), 'error')
        return
    end
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    removeChips(src, amount)
    Player.Functions.AddMoney('cash', amount, nil)
    Wrappers.Notify(src, Locale('casino.cash_chips'), 'success')
end)

RegisterNetEvent('casino:blackjackBet', function(data)
    local src = source
    if type(data) ~= 'table' or type(data.bet) ~= 'number' then
        return
    end
    if not checkRateLimit(src, 'blackjackBet', 1) then
        Wrappers.Notify(src, Locale('error.rate_limit'), 'error')
        return
    end
    local bet = math.floor(data.bet)
    if bet < 1 then return end
    if not hasChips(src, bet) then
        Wrappers.Notify(src, Locale('casino.no_chips'), 'error')
        return
    end
    removeChips(src, bet)

    local deck = shuffleDeck(createDeck())
    local playerHand = { dealCard(deck), dealCard(deck) }
    local dealerHand = { dealCard(deck), dealCard(deck) }

    local playerValue = handValue(playerHand)
    local dealerValue = handValue(dealerHand)
    local result = 'lose'
    local payout = 0

    if playerValue == 21 then
        if dealerValue == 21 then
            result = 'push'
            payout = bet
        else
            result = 'blackjack'
            payout = math.floor(bet * Config.Casino.blackjackPayout * 1.5)
        end
    else
        while playerValue < 21 do end
        while dealerValue < 17 do
            local card = dealCard(deck)
            table.insert(dealerHand, card)
            dealerValue = handValue(dealerHand)
        end
        if playerValue > 21 then
            result = 'bust'
        elseif dealerValue > 21 or playerValue > dealerValue then
            result = 'win'
            payout = math.floor(bet * Config.Casino.blackjackPayout)
        elseif playerValue == dealerValue then
            result = 'push'
            payout = bet
        end
    end

    if payout > 0 then
        addChips(src, payout)
    end

    TriggerClientEvent('casino:blackjackResult', src, {
        playerHand = playerHand,
        dealerHand = dealerHand,
        playerValue = playerValue,
        dealerValue = dealerValue,
        result = result,
        payout = payout,
    })

    if result == 'blackjack' or result == 'win' then
        Wrappers.Notify(src, Locale('casino.win'), 'success')
    elseif result == 'push' then
        Wrappers.Notify(src, Locale('casino.blackjack'), 'success')
    else
        Wrappers.Notify(src, Locale('casino.lose'), 'error')
    end
end)

RegisterNetEvent('casino:rouletteSpin', function(data)
    local src = source
    if type(data) ~= 'table' or type(data.bet) ~= 'number' or type(data.betType) ~= 'string' then
        return
    end
    if not checkRateLimit(src, 'rouletteSpin', 1) then
        Wrappers.Notify(src, Locale('error.rate_limit'), 'error')
        return
    end
    local bet = math.floor(data.bet)
    if bet < 1 then return end
    if not hasChips(src, bet) then
        Wrappers.Notify(src, Locale('casino.no_chips'), 'error')
        return
    end
    removeChips(src, bet)

    local spinIndex = math.random(#ROULETTE_NUMBERS)
    local resultNumber = ROULETTE_NUMBERS[spinIndex]
    local resultColor = resultNumber == 0 and 'green' or (isRed(resultNumber) and 'red' or 'black')
    local win = false
    local multiplier = 0

    if data.betType == 'single' and type(data.number) == 'number' then
        local num = math.floor(data.number)
        if num == resultNumber then
            win = true
            multiplier = Config.Casino.roulettePayouts.single
        end
    elseif data.betType == 'red' and resultColor == 'red' then
        win = true
        multiplier = Config.Casino.roulettePayouts.red
    elseif data.betType == 'black' and resultColor == 'black' then
        win = true
        multiplier = Config.Casino.roulettePayouts.black
    elseif data.betType == 'odd' then
        if resultNumber ~= 0 and resultNumber % 2 ~= 0 then
            win = true
            multiplier = Config.Casino.roulettePayouts.odd
        end
    elseif data.betType == 'even' then
        if resultNumber ~= 0 and resultNumber % 2 == 0 then
            win = true
            multiplier = Config.Casino.roulettePayouts.even
        end
    end

    local payout = 0
    if win and multiplier > 0 then
        payout = math.floor(bet * multiplier)
        addChips(src, payout)
    end

    TriggerClientEvent('casino:rouletteResult', src, {
        number = resultNumber,
        color = resultColor,
        win = win,
        payout = payout,
    })

    if win then
        Wrappers.Notify(src, Locale('casino.win'), 'success')
    else
        Wrappers.Notify(src, Locale('casino.lose'), 'error')
    end
end)

RegisterNetEvent('casino:slotSpin', function(data)
    local src = source
    if type(data) ~= 'table' or type(data.bet) ~= 'number' then
        return
    end
    if not checkRateLimit(src, 'slotSpin', 5) then
        Wrappers.Notify(src, Locale('error.rate_limit'), 'error')
        return
    end
    local bet = math.floor(data.bet)
    if bet < 1 then return end
    if not hasChips(src, bet) then
        Wrappers.Notify(src, Locale('casino.no_chips'), 'error')
        return
    end
    removeChips(src, bet)

    local reels = spinReels()
    local multiplier = getSlotMultiplier(reels)
    local payout = 0
    local win = false

    if multiplier > 0 then
        win = true
        payout = math.floor(bet * multiplier)
        addChips(src, payout)
    end

    TriggerClientEvent('casino:slotResult', src, {
        reels = reels,
        win = win,
        payout = payout,
    })

    if win then
        Wrappers.Notify(src, Locale('casino.win'), 'success')
    else
        Wrappers.Notify(src, Locale('casino.lose'), 'error')
    end
end)
