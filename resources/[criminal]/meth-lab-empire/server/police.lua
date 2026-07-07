local QBox = exports['qbx_core']:GetCoreObject()

RegisterNetEvent('methlab:executeRaid', function(bunkerId)
    local src = source
    local bunker = exports['bunker-builder']:GetBunker(bunkerId)
    if not bunker then return end

    local players = QBox.Functions.GetPlayers()
    local insidePlayers = {}
    for _, id in ipairs(players) do
        local p = QBox.Functions.GetPlayer(id)
        if p then
            local pos = GetEntityCoords(GetPlayerPed(id))
            local dist = #(pos - bunker.interior.coords)
            if dist < 10.0 then
                table.insert(insidePlayers, id)
            end
        end
    end

    if #insidePlayers == 0 then
        notifyPoliceRaid(bunkerId, bunker, 'No one inside')
        return
    end

    local state = MySQL.single.await('SELECT upgrades_json FROM meth_lab_state WHERE bunker_id = ?', { bunkerId })
    local upgrades = state and json.decode(state.upgrades_json) or {}

    for _, id in ipairs(insidePlayers) do
        local p = QBox.Functions.GetPlayer(id)
        if p then
            local hasTunnel = false
            for _, u in ipairs(upgrades) do if u == 'escape_tunnel' then hasTunnel = true break end end
            local hasCompartment = false
            for _, u in ipairs(upgrades) do if u == 'hidden_compartment' then hasCompartment = true break end end

            local escaped = false
            if hasTunnel then
                local escapeCoords = getEscapeCoords(bunker)
                SetEntityCoords(GetPlayerPed(id), escapeCoords.x, escapeCoords.y, escapeCoords.z)
                TriggerClientEvent('ox_lib:notify', id, { type = 'success', description = 'Escaped through tunnel!' })
                escaped = true
            end

            if not escaped then
                local methOnPlayer = 0
                local methItems = { 'meth_blue_sky', 'meth_crystal', 'meth_street' }
                for _, item in ipairs(methItems) do
                    local count = QBox.Functions.GetItemCount(p, item)
                    if count and count > 0 then
                        methOnPlayer = methOnPlayer + count
                        p.Functions.RemoveItem(item, count)
                    end
                end

                if hasCompartment and math.random() <= Config.MethLab.raid.hideCompartmentChance then
                    local saved = math.ceil(methOnPlayer * 0.6)
                    p.Functions.AddItem('meth_street', saved)
                    TriggerClientEvent('ox_lib:notify', id, { type = 'success', description = 'Hidden compartment saved ' .. saved .. ' product!' })
                else
                    local fine = Config.MethLab.raid.evidenceFoundFine
                    p.Functions.RemoveMoney('cash', fine)
                    TriggerClientEvent('ox_lib:notify', id, { type = 'error', description = 'RAIDED! Lost all product. Fined $' .. fine })
                end
            end
        end
    end

    notifyPoliceRaid(bunkerId, bunker, 'Raid executed')
    addHeatToBunker(bunkerId, -30)
end)

function notifyPoliceRaid(bunkerId, bunker, status)
    local players = QBox.Functions.GetPlayers()
    for _, id in ipairs(players) do
        local p = QBox.Functions.GetPlayer(id)
        if p and p.PlayerData.job.onduty and isCidJob(p.PlayerData.job.name) then
            TriggerClientEvent('ox_lib:notify', id, {
                type = 'info',
                description = 'Raid at ' .. bunker.label .. ': ' .. status
            })
            TriggerClientEvent('methlab:raidAlert', id, bunker.entrance.coords, bunker.label)
        end
    end
    exports['discord-logs']:LogCustom('SYSTEM', 'Meth Lab', 'Raid executed at ' .. bunker.label)
end

function getEscapeCoords(bunker)
    local base = bunker.entrance.coords
    local angle = math.random() * 2 * math.pi
    local dist = math.random(50, Config.MethLab.raid.escapeTunnelRange)
    return vector3(base.x + math.cos(angle) * dist, base.y + math.sin(angle) * dist, base.z)
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5000)
        local rows = MySQL.query.await('SELECT bunker_id, heat FROM meth_lab_state WHERE heat >= ?', { Config.MethLab.heat.thresholds.dangerous.max })
        for _, row in ipairs(rows or {}) do
            if row.heat >= Config.MethLab.heat.thresholds.critical.max then
                local bunker = exports['bunker-builder']:GetBunker(row.bunker_id)
                if bunker then
                    local players = QBox.Functions.GetPlayers()
                    for _, id in ipairs(players) do
                        local p = QBox.Functions.GetPlayer(id)
                        if p then
                            local pos = GetEntityCoords(GetPlayerPed(id))
                            local dist = #(pos - bunker.interior.coords)
                            if dist < 15.0 then
                                TriggerClientEvent('methlab:raidWarning', id, row.bunker_id)
                            end
                        end
                    end
                end
            end
        end
    end
end)
