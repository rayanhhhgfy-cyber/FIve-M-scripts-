local QBCore = exports['qbx_core']:GetCoreObject()

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        for _, loc in ipairs(Config.MorgueLocations) do
            local dist = #(coords - vector3(loc.coords.x, loc.coords.y, loc.coords.z))
            if dist < 2.0 then
                if loc.type == 'storage' then
                    exports['ox_target']:addLocalEntity(ped, {
                        {
                            name = 'morgue_storage_' .. loc.name,
                            label = 'Open Body Storage',
                            icon = 'fas fa-box',
                            distance = 2.0,
                            onSelect = function()
                                local bodies = lib.callback.await('morgue-extension:server:getStoredBodies', false)
                                local options = {}
                                for _, body in ipairs(bodies) do
                                    table.insert(options, {
                                        title = 'Slot ' .. body.slot .. ' — ' .. (body.data.name or 'Unknown'),
                                        description = 'Stored: ' .. os.date('%m/%d/%Y %H:%M', body.timestamp),
                                        icon = 'fas fa-skull',
                                        onSelect = function()
                                            local success = lib.callback.await('morgue-extension:server:removeBody', false, body.slot)
                                            if success then
                                                Wrappers.Notify({ type = 'success', description = 'Body removed' })
                                            end
                                        end
                                    })
                                end
                                if #options == 0 then
                                    table.insert(options, { title = 'No bodies stored', readOnly = true })
                                end
                                lib.registerContext({
                                    id = 'morgue_storage_menu',
                                    title = 'Cold Storage',
                                    options = options
                                })
                                lib.showContext('morgue_storage_menu')
                            end
                        }
                    })
                elseif loc.type == 'autopsy' then
                    exports['ox_target']:addLocalEntity(ped, {
                        {
                            name = 'morgue_autopsy_' .. loc.name,
                            label = 'Perform Autopsy',
                            icon = 'fas fa-microscope',
                            distance = 2.0,
                            onSelect = function()
                                local bodies = lib.callback.await('morgue-extension:server:getStoredBodies', false)
                                local bodyOptions = {}
                                for _, body in ipairs(bodies) do
                                    table.insert(bodyOptions, { value = body.slot, label = 'Slot ' .. body.slot .. ' — ' .. (body.data.name or 'Unknown') })
                                end
                                if #bodyOptions == 0 then
                                    Wrappers.Notify({ type = 'error', description = 'No bodies in storage' })
                                    return
                                end
                                local input = lib.inputDialog('Select Body for Autopsy', {
                                    { type = 'select', label = 'Body', options = bodyOptions }
                                })
                                if input then
                                    local progress = exports['ox_lib']:progressBar({
                                        duration = 15000,
                                        label = 'Performing autopsy...',
                                        useWhileDead = false,
                                        canCancel = true,
                                        disableMovement = true,
                                        disableCarMovement = true,
                                        disableMouse = false,
                                        disableCombat = true
                                    })
                                    if progress then
                                        local results, recordId = lib.callback.await('morgue-extension:server:performAutopsy', false, tonumber(input[1]))
                                        if results then
                                            local options = {}
                                            for resultType, resultData in pairs(results) do
                                                local resultConfig = Config.AutopsyResults[resultType]
                                                if resultConfig then
                                                    table.insert(options, {
                                                        title = resultConfig.label,
                                                        description = tostring(resultData),
                                                        icon = resultConfig.icon,
                                                        readOnly = true
                                                    })
                                                end
                                            end
                                            table.insert(options, { title = 'Record ID: ' .. recordId, readOnly = true })
                                            lib.registerContext({
                                                id = 'autopsy_results',
                                                title = 'Autopsy Report',
                                                options = options
                                            })
                                            lib.showContext('autopsy_results')
                                        end
                                    end
                                end
                            end
                        }
                    })
                elseif loc.type == 'evidence' then
                    exports['ox_target']:addLocalEntity(ped, {
                        {
                            name = 'morgue_evidence_' .. loc.name,
                            label = 'Evidence Locker',
                            icon = 'fas fa-fingerprint',
                            distance = 2.0,
                            onSelect = function()
                                TriggerServerEvent('morgue-extension:server:storeEvidence')
                            end
                        }
                    })
                end
            end
        end
    end
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[morgue-extension] Client morgue ready.^7')
end)
