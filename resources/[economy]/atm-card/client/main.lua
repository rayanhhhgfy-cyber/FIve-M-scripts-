local atmMenuOpen = false

--- Create ATM target zones from Renewed-Banking config
Citizen.CreateThread(function()
    local atmLocations = exports['Renewed-Banking'] and Config.ATMLocations
    if not atmLocations then
        -- Fallback: use built-in ATM coords
        atmLocations = {
            vec3(150.0, -1040.0, 29.0),
            vec3(-25.0, -725.0, 32.0),
            vec3(315.0, -280.0, 54.0),
            vec3(-300.0, -830.0, 32.0),
            vec3(-1200.0, -890.0, 14.0),
            vec3(-1400.0, -600.0, 30.0),
            vec3(240.0, 220.0, 106.0),
            vec3(1100.0, -750.0, 58.0),
            vec3(380.0, 330.0, 103.0),
            vec3(-820.0, -700.0, 28.0),
            vec3(1200.0, -470.0, 66.0),
            vec3(1300.0, -700.0, 65.0),
        }
    end

    for i, coords in ipairs(atmLocations) do
        local pos = type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords
        exports.ox_target:addSphereZone({
            coords = pos,
            radius = 0.8,
            debug = false,
            options = {
                {
                    name = 'atm_card_use_' .. i,
                    icon = 'fas fa-credit-card',
                    label = 'Use ATM',
                    distance = Config.ATM.InteractionDistance,
                    onSelect = function()
                        openATMMenu()
                    end,
                }
            }
        })
    end
end)

function openATMMenu()
    -- Check for bank card
    if exports.ox_inventory:Search('count', Config.ATM.RequiredItem) < 1 then
        Wrappers.Notify('You need your bank card. Visit City Hall.', 'error')
        return
    end

    -- Get accounts
    local accounts = lib.callback.await('atm-card:server:getAccounts', false)
    if not accounts or #accounts == 0 then
        Wrappers.Notify('No bank account found', 'error')
        return
    end

    SendNUIMessage({
        action = 'open',
        accounts = accounts,
        maxWithdraw = Config.ATM.MaxWithdraw,
        maxDeposit = Config.ATM.MaxDeposit,
        atmFee = Config.ATM.WithdrawFee,
    })

    SetNuiFocus(true, true)
    atmMenuOpen = true
end

RegisterNUICallback('deposit', function(data, cb)
    local success, newBalance = lib.callback.await('atm-card:server:deposit', false, data.accountId, data.amount)
    if success then
        local accounts = lib.callback.await('atm-card:server:getAccounts', false)
        cb({ success = true, accounts = accounts })
    else
        cb({ success = false })
    end
end)

RegisterNUICallback('withdraw', function(data, cb)
    local success, newBalance = lib.callback.await('atm-card:server:withdraw', false, data.accountId, data.amount)
    if success then
        local accounts = lib.callback.await('atm-card:server:getAccounts', false)
        cb({ success = true, accounts = accounts })
    else
        cb({ success = false })
    end
end)

RegisterNUICallback('close', function(_, cb)
    SetNuiFocus(false, false)
    atmMenuOpen = false
    cb({})
end)

RegisterNUICallback('escape', function(_, cb)
    SetNuiFocus(false, false)
    atmMenuOpen = false
    cb({})
end)
