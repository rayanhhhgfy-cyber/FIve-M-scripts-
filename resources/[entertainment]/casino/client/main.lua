local QBCore = exports['qbx-core']:GetCoreObject()

local function openChipShop()
    Wrappers.InputDialog({
        title = Locale('casino.buy_chips'),
        label = Locale('casino.buy_chips'),
        placeholder = Locale('casino.not_enough'),
        type = 'number',
    }, function(buyAmount)
        if not buyAmount or tonumber(buyAmount) <= 0 then return end
        TriggerServerEvent('casino:buyChips', { amount = tonumber(buyAmount) })
    end)
end

local function cashChips()
    Wrappers.InputDialog({
        title = Locale('casino.cash_chips'),
        label = Locale('casino.cash_chips'),
        placeholder = Locale('casino.not_enough'),
        type = 'number',
    }, function(cashAmount)
        if not cashAmount or tonumber(cashAmount) <= 0 then return end
        TriggerServerEvent('casino:cashChips', { amount = tonumber(cashAmount) })
    end)
end

local function playBlackjack()
    Wrappers.InputDialog({
        title = Locale('casino.blackjack') .. ' - ' .. Locale('casino.place_bet'),
        label = Locale('casino.bet'),
        placeholder = '100',
        type = 'number',
    }, function(bet)
        if not bet or tonumber(bet) <= 0 then return end
        TriggerServerEvent('casino:blackjackBet', { bet = tonumber(bet) })
    end)
end

local function playRoulette()
    local options = {
        {
            title = Locale('casino.roulette') .. ' - ' .. Locale('casino.bet'),
            description = '',
            onSelect = function()
                Wrappers.InputDialog({
                    title = Locale('casino.roulette'),
                    label = Locale('casino.bet'),
                    placeholder = '100',
                    type = 'number',
                }, function(bet)
                    if not bet or tonumber(bet) <= 0 then return end
                    local betAmount = tonumber(bet)
                    local betOptions = {
                        {
                            title = Locale('casino.roulette'),
                            description = '',
                            onSelect = function()
                                local typeOptions = {
                                    {
                                        title = 'Single Number',
                                        description = Locale('casino.roulette') .. ' x35',
                                        onSelect = function()
                                            Wrappers.InputDialog({
                                                title = Locale('casino.roulette'),
                                                label = 'Number (0-36)',
                                                placeholder = '7',
                                                type = 'number',
                                            }, function(num)
                                                if not num then return end
                                                local number = tonumber(num)
                                                if number < 0 or number > 36 then return end
                                                TriggerServerEvent('casino:rouletteSpin', { bet = betAmount, betType = 'single', number = number })
                                            end)
                                        end,
                                    },
                                    {
                                        title = 'Red',
                                        description = Locale('casino.roulette') .. ' x2',
                                        onSelect = function()
                                            TriggerServerEvent('casino:rouletteSpin', { bet = betAmount, betType = 'red' })
                                        end,
                                    },
                                    {
                                        title = 'Black',
                                        description = Locale('casino.roulette') .. ' x2',
                                        onSelect = function()
                                            TriggerServerEvent('casino:rouletteSpin', { bet = betAmount, betType = 'black' })
                                        end,
                                    },
                                    {
                                        title = 'Odd',
                                        description = Locale('casino.roulette') .. ' x2',
                                        onSelect = function()
                                            TriggerServerEvent('casino:rouletteSpin', { bet = betAmount, betType = 'odd' })
                                        end,
                                    },
                                    {
                                        title = 'Even',
                                        description = Locale('casino.roulette') .. ' x2',
                                        onSelect = function()
                                            TriggerServerEvent('casino:rouletteSpin', { bet = betAmount, betType = 'even' })
                                        end,
                                    },
                                }
                                Wrappers.ContextMenu({
                                    id = 'roulette_bet_type',
                                    title = Locale('casino.roulette'),
                                    options = typeOptions,
                                })
                            end,
                        },
                    }
                    Wrappers.ContextMenu({
                        id = 'roulette_main',
                        title = Locale('casino.roulette'),
                        options = betOptions,
                    })
                end)
            end,
        },
    }
    Wrappers.ContextMenu({
        id = 'roulette_menu',
        title = Locale('casino.roulette'),
        options = options,
    })
end

local function playSlots()
    Wrappers.InputDialog({
        title = Locale('casino.slots'),
        label = Locale('casino.place_bet'),
        placeholder = '10',
        type = 'number',
    }, function(bet)
        if not bet or tonumber(bet) <= 0 then return end
        Wrappers.ProgressBar({
            duration = 1500,
            label = Locale('casino.spin') .. '...',
            useWhileDead = false,
            canCancel = false,
            disable = { move = true, car = true, combat = true },
        }, function()
            TriggerServerEvent('casino:slotSpin', { bet = tonumber(bet) })
        end)
    end)
end

RegisterNetEvent('casino:blackjackResult', function(data)
    local resultText = ''
    local resultLabel = ''
    if data.result == 'blackjack' then
        resultLabel = Locale('casino.blackjack')
    elseif data.result == 'win' then
        resultLabel = Locale('casino.win')
    elseif data.result == 'bust' then
        resultLabel = Locale('casino.bust')
    elseif data.result == 'push' then
        resultLabel = 'Push'
    else
        resultLabel = Locale('casino.lose')
    end
    Wrappers.Notify(resultLabel .. ' | Payout: $' .. data.payout, data.payout > 0 and 'success' or 'error')
end)

RegisterNetEvent('casino:rouletteResult', function(data)
    Wrappers.Notify(
        Locale('casino.roulette') .. ': ' .. data.number .. ' (' .. data.color .. ') | '
        .. (data.win and (Locale('casino.win') .. ' $' .. data.payout) or Locale('casino.lose')),
        data.win and 'success' or 'error'
    )
end)

RegisterNetEvent('casino:slotResult', function(data)
    local reelStr = data.reels[1] .. ' | ' .. data.reels[2] .. ' | ' .. data.reels[3]
    if data.win then
        Wrappers.Notify(reelStr .. ' | ' .. Locale('casino.win') .. ' $' .. data.payout, 'success')
    else
        Wrappers.Notify(reelStr .. ' | ' .. Locale('casino.lose'), 'error')
    end
end)

CreateThread(function()
    exports.ox_target:addBoxZone({
        coords = Config.Casino.loc,
        size = vec3(2.0, 2.0, 2.0),
        rotation = 0,
        options = {
            {
                name = 'casino_cashier_buy',
                label = Locale('casino.buy_chips'),
                icon = 'fas fa-coins',
                onSelect = function()
                    openChipShop()
                end,
            },
            {
                name = 'casino_cashier_cash',
                label = Locale('casino.cash_chips'),
                icon = 'fas fa-money-bill-wave',
                onSelect = function()
                    cashChips()
                end,
            },
        },
    })

    exports.ox_target:addBoxZone({
        coords = Config.Casino.tables.blackjack.coords,
        size = vec3(1.5, 1.5, 1.5),
        rotation = 0,
        options = {
            {
                name = 'casino_blackjack',
                label = Config.Casino.tables.blackjack.label,
                icon = 'fas fa-hand-paper',
                onSelect = function()
                    playBlackjack()
                end,
            },
        },
    })

    exports.ox_target:addBoxZone({
        coords = Config.Casino.tables.roulette.coords,
        size = vec3(1.5, 1.5, 1.5),
        rotation = 0,
        options = {
            {
                name = 'casino_roulette',
                label = Config.Casino.tables.roulette.label,
                icon = 'fas fa-circle',
                onSelect = function()
                    playRoulette()
                end,
            },
        },
    })

    exports.ox_target:addBoxZone({
        coords = Config.Casino.tables.slots.coords,
        size = vec3(1.5, 1.5, 1.5),
        rotation = 0,
        options = {
            {
                name = 'casino_slots',
                label = Config.Casino.tables.slots.label,
                icon = 'fas fa-sync-alt',
                onSelect = function()
                    playSlots()
                end,
            },
        },
    })
end)
