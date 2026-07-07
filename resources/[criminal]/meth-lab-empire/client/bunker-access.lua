local QBox = exports['qbx-core']:GetCoreObject()
local bunkerTargets = {}
local isAtKeypad = false
local passcodeAttempts = {}

function getNearestBunker()
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local nearest = nil
    local nearestDist = 10.0
    local bunkers = exports['bunker-builder']:GetAllBunkers() or {}
    for id, bunker in pairs(bunkers) do
        local dist = #(pos - bunker.entrance.coords)
        if dist < nearestDist then
            nearestDist = dist
            nearest = { id = id, data = bunker }
        end
    end
    return nearest
end

Citizen.CreateThread(function()
    Citizen.Wait(2000)
    local bunkers = exports['bunker-builder']:GetAllBunkers() or {}
    for id, bunker in pairs(bunkers) do
        setupBunkerEntrance(id, bunker)
    end
end)

function setupBunkerEntrance(bunkerId, bunker)
    if bunkerTargets[bunkerId] then return end
    local opts = {
        {
            name = 'enter_bunker_' .. bunkerId,
            icon = Config.MethLab.targetOptions.enterBunker.icon,
            label = Config.MethLab.targetOptions.enterBunker.label,
            distance = Config.MethLab.targetOptions.enterBunker.distance,
            onSelect = function()
                attemptEnterBunker(bunkerId, bunker)
            end,
        }
    }
    if isAdmin() then
        table.insert(opts, {
            name = 'bunker_info_' .. bunkerId,
            icon = 'fas fa-info-circle',
            label = 'Bunker Info',
            distance = 3.0,
            onSelect = function()
                local info = ('[%s] Passcode: %s | Locked: %s | Type: %s'):format(
                    bunker.label, bunker.passcode or '2193',
                    bunker.locked and 'Yes' or 'No',
                    bunker.interiorType or 'standard'
                )
                notify(info, 'info')
            end,
        })
    end
    local zone = exports.ox_target:addBoxZone({
        coords = bunker.entrance.coords,
        size = vec3(2.0, 2.0, 2.0),
        rotation = 0,
        debug = false,
        options = opts,
    })
    bunkerTargets[bunkerId] = zone
end

function attemptEnterBunker(bunkerId, bunker)
    if not bunker.locked then
        enterBunkerInterior(bunkerId, bunker)
        return
    end
    if bunker.cidBypass and isCidOnDuty() then
        notify('CID access granted', 'success')
        enterBunkerInterior(bunkerId, bunker)
        return
    end
    showPasscodeKeypad(bunkerId, bunker)
end

function showPasscodeKeypad(bunkerId, bunker)
    isAtKeypad = true
    local hackOption = ''
    if hasItem('laptop') then
        hackOption = '\nYou have a laptop — type HACK to bypass security'
    end
    local input = lib.inputDialog(bunker.label .. ' — Enter Passcode', {
        { type = 'input', label = 'Passcode' .. hackOption, placeholder = 'Enter passcode or type HACK', name = 'code' }
    })
    isAtKeypad = false
    if not input then return end
    local entry = input.code
    if not entry then return end
    if string.upper(entry) == 'HACK' and hasItem('laptop') then
        TriggerServerEvent('methlab:attemptHack', bunkerId)
        return
    end
    if entry == bunker.passcode then
        notify('Access granted', 'success')
        enterBunkerInterior(bunkerId, bunker)
    else
        passcodeAttempts[bunkerId] = (passcodeAttempts[bunkerId] or 0) + 1
        local remaining = Config.MethLab.maxPasscodeAttempts - passcodeAttempts[bunkerId]
        if remaining <= 0 then
            notify('Too many failed attempts. Lockdown activated.', 'error')
            TriggerServerEvent('methlab:failedPasscodeAlert', bunkerId)
            passcodeAttempts[bunkerId] = 0
            Citizen.SetTimeout(Config.MethLab.passcodeCooldown * 1000, function()
                notify(bunker.label .. ' lockdown lifted', 'info')
            end)
        else
            notify('Wrong code. ' .. remaining .. ' attempts remaining', 'error')
        end
    end
end

RegisterNetEvent('methlab:hackResult', function(bunkerId, success)
    local bunkers = exports['bunker-builder']:GetAllBunkers() or {}
    local bunker = bunkers[bunkerId]
    if not bunker then return end
    if success then
        notify('Bypassed security! Access granted.', 'success')
        enterBunkerInterior(bunkerId, bunker)
    else
        notify('Hack failed! Security system alerted.', 'error')
    end
end)

function enterBunkerInterior(bunkerId, bunker)
    local ped = PlayerPedId()
    DoScreenFadeOut(500)
    Citizen.Wait(600)
    SetEntityCoords(ped, bunker.interior.coords.x, bunker.interior.coords.y, bunker.interior.coords.z)
    SetEntityHeading(ped, bunker.interior.heading)
    if bunker.interiorName and bunker.interiorName ~= '' then
        RequestIpl(bunker.interiorName)
    end
    Citizen.Wait(400)
    DoScreenFadeIn(500)
    TriggerEvent('methlab:enterBunker', bunkerId)
    notify('Entered ' .. bunker.label, 'success')
end

function exitBunkerInterior(bunkerId)
    local bunkers = exports['bunker-builder']:GetAllBunkers() or {}
    local bunker = bunkers[bunkerId]
    if not bunker then return end
    local ped = PlayerPedId()
    DoScreenFadeOut(500)
    Citizen.Wait(600)
    SetEntityCoords(ped, bunker.entrance.coords.x, bunker.entrance.coords.y, bunker.entrance.coords.z + 1.0)
    SetEntityHeading(ped, bunker.entrance.heading)
    Citizen.Wait(400)
    DoScreenFadeIn(500)
    TriggerEvent('methlab:exitBunker')
    notify('Exited ' .. bunker.label, 'info')
end

RegisterNetEvent('methlab:setupInteriorZones', function(bunkerId)
    Citizen.Wait(1000)
    local bunkers = exports['bunker-builder']:GetAllBunkers() or {}
    local bunker = bunkers[bunkerId]
    if not bunker then return end
    local interior = bunker.interior
    local pos = interior.coords

    exports.ox_target:addBoxZone({
        coords = pos,
        size = vec3(2.0, 2.0, 2.0),
        rotation = 0,
        debug = false,
        options = {
            {
                name = 'bunker_cook_station_' .. bunkerId,
                icon = Config.MethLab.targetOptions.useCookStation.icon,
                label = Config.MethLab.targetOptions.useCookStation.label,
                distance = Config.MethLab.targetOptions.useCookStation.distance,
                onSelect = function()
                    TriggerEvent('methlab:openCookingMenu', bunkerId)
                end,
            },
            {
                name = 'bunker_storage_' .. bunkerId,
                icon = Config.MethLab.targetOptions.chemicalStorage.icon,
                label = Config.MethLab.targetOptions.chemicalStorage.label,
                distance = Config.MethLab.targetOptions.chemicalStorage.distance,
                onSelect = function()
                    TriggerEvent('methlab:openStorage', bunkerId)
                end,
            },
            {
                name = 'bunker_terminal_' .. bunkerId,
                icon = Config.MethLab.targetOptions.bunkerTerminal.icon,
                label = Config.MethLab.targetOptions.bunkerTerminal.label,
                distance = Config.MethLab.targetOptions.bunkerTerminal.distance,
                onSelect = function()
                    TriggerEvent('methlab:openTerminal', bunkerId)
                end,
            },
            {
                name = 'exit_bunker_' .. bunkerId,
                icon = 'fas fa-door-closed',
                label = 'Exit Bunker',
                distance = 2.0,
                onSelect = function()
                    exitBunkerInterior(bunkerId)
                end,
            },
        }
    })
end)

RegisterNetEvent('methlab:openTerminal', function(bunkerId)
    QBox.Functions.TriggerCallback('methlab:getBunkerState', function(state)
        if not state then return end
        local items = {
            { title = 'Bunker Status', icon = 'fas fa-info-circle', description = 'Heat: ' .. (state.heat or 0) .. '% | Upgrades: ' .. (#(state.upgrades or {})), onSelect = function()
                notify('Heat Level: ' .. (state.heat or 0) .. '%', state.heat and state.heat > 60 and 'error' or 'info')
            end },
            { title = 'Manage Upgrades', icon = 'fas fa-tools', onSelect = function() showUpgradeMenu(bunkerId) end },
        }
        if isAdmin() then
            table.insert(items, {
                title = '[ADMIN] Reset Heat', icon = 'fas fa-undo', onSelect = function()
                    TriggerServerEvent('methlab:adminResetHeat', bunkerId)
                end
            })
        end
        Wrappers.ContextMenu({ id = 'bunker_terminal', title = 'Bunker Terminal', menuItems = items })
    end, bunkerId)
end)

function showUpgradeMenu(bunkerId)
    QBox.Functions.TriggerCallback('methlab:getBunkerState', function(state)
        local owned = state and state.upgrades or {}
        local items = {}
        for key, upgrade in pairs(Config.MethLab.upgrades) do
            local isOwned = false
            for _, o in ipairs(owned) do if o == key then isOwned = true break end end
            table.insert(items, {
                title = (isOwned and '✓ ' or '') .. upgrade.label,
                description = (isOwned and 'OWNED' or '$' .. upgrade.cost .. ' — ' .. upgrade.description),
                onSelect = function()
                    if isOwned then notify('Already owned', 'info') return end
                    Wrappers.ConfirmDialog({ title = 'Purchase ' .. upgrade.label .. '?', content = 'Cost: $' .. upgrade.cost }, function(confirmed)
                        if confirmed then
                            TriggerServerEvent('methlab:purchaseUpgrade', bunkerId, key)
                        end
                    end)
                end
            })
        end
        Wrappers.ContextMenu({ id = 'bunker_upgrades', title = 'Upgrades ($' .. Config.MethLab.upgrades.ventilation.cost .. ' - $' .. Config.MethLab.upgrades.escape_tunnel.cost .. ')', menuItems = items })
    end, bunkerId)
end
