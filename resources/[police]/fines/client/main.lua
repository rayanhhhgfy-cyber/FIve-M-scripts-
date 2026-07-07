local QBox = exports['qbx-core']:GetCoreObject()
local playerData = {}

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    playerData = QBox.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    playerData.job = job
end)

local function isOnDuty()
    return playerData.job and playerData.job.type == 'leo' and playerData.job.onduty
end

Citizen.CreateThread(function()
    while not QBox.Functions.GetPlayerData().citizenid do
        Citizen.Wait(100)
    end
    playerData = QBox.Functions.GetPlayerData()

    exports.ox_target:addGlobalPlayer({
        options = {
            {
                name = 'fines_issue',
                icon = Config.Fines.TargetOptions.icon,
                label = Config.Fines.TargetOptions.label,
                group = Config.Fines.TargetOptions.group,
                distance = Config.Fines.TargetOptions.distance,
                canInteract = function()
                    if Config.Fines.RequireDuty and not isOnDuty() then return false end
                    return true
                end,
                onSelect = function(entity)
                    local playerId = NetworkGetPlayerIndexFromPed(entity)
                    if playerId and playerId ~= -1 then
                        TriggerEvent('fines:openMenu', GetPlayerServerId(playerId))
                    end
                end
            }
        }
    })
end)

RegisterNetEvent('fines:openMenu', function(targetId)
    if not isOnDuty() then
        Wrappers.Notify(Locale('police.not_on_duty'), 'error')
        return
    end
    local categoryItems = {}
    for catId, catData in pairs(Config.Fines.FinesCategories) do
        table.insert(categoryItems, {
            title = catData.label,
            menu = 'fines_' .. catId
        })
    end
    Wrappers.ContextMenu({
        id = 'fines_category_menu',
        title = Locale('police.select_fine_category'),
        menuItems = categoryItems
    })
    RegisterFineMenus(targetId)
end)

local function RegisterFineMenus(targetId)
    for catId, catData in pairs(Config.Fines.FinesCategories) do
        RegisterNetEvent('fines:' .. catId .. ':open', function()
            local fineItems = {}
            for _, fine in ipairs(catData.fines) do
                table.insert(fineItems, {
                    title = fine.label,
                    description = '$' .. fine.amount,
                    onSelect = function()
                        Wrappers.InputDialog({
                            title = fine.label .. ' - $' .. fine.amount,
                            inputs = {
                                { type = 'input', label = Locale('police.fine_reason'), name = 'reason', required = false }
                            }
                        }, function(values)
                            if values then
                                TriggerServerEvent('fines:server:issue', targetId, fine.id, fine.amount, fine.label, values.reason)
                            end
                        end)
                    end
                })
            end
            Wrappers.ContextMenu({
                id = 'fines_list_' .. catId,
                title = catData.label,
                menuItems = fineItems
            })
        end)
    end
end

RegisterNetEvent('fines:client:paymentResult', function(success, fineLabel, amount)
    if success then
        Wrappers.Notify(Locale('police.fine_issued', fineLabel, amount), 'success')
    else
        Wrappers.Notify(Locale('police.fine_failed'), 'error')
    end
end)
