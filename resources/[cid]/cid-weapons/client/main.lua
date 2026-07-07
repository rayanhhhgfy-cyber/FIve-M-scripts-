local QBox = exports['qbx-core']:GetCoreObject()
local playerData = {}

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    playerData = QBox.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    playerData.job = job
end)

Citizen.CreateThread(function()
    while not QBox.Functions.GetPlayerData().citizenid do Citizen.Wait(100) end
    playerData = QBox.Functions.GetPlayerData()

    -- CID HQ Secret Armory target
    local armory = Config.CIDWeapons.hqArmory
    exports.ox_target:addBoxZone({
        coords = armory.coords,
        size = vector3(armory.radius * 2, armory.radius * 2, 4.0),
        rotation = 0,
        debug = false,
        options = {
            {
                name = 'cid_secret_armory',
                icon = 'fas fa-shield-halved',
                label = armory.label,
                distance = Config.CIDWeapons.maxDistance,
                canInteract = function()
                    if not playerData.job then return false end
                    for _, j in ipairs(Config.CIDWeapons.allowedJobs) do
                        if playerData.job.name == j then
                            if Config.CIDWeapons.requireDuty and not playerData.job.onduty then return false end
                            return true
                        end
                    end
                    return false
                end,
                onSelect = function()
                    local items = {}
                    -- Group weapons by rank tier
                    local tiers = {}
                    for _, w in ipairs(Config.CIDWeapons.weapons) do
                        tiers[w.rank] = tiers[w.rank] or {}
                        table.insert(tiers[w.rank], w)
                    end
                    for rank = 0, 4 do
                        if tiers[rank] then
                            local label = 'Rank ' .. rank .. '+'
                            if rank == 0 then label = 'All Ranks' end
                            local tierItems = {}
                            for _, w in ipairs(tiers[rank]) do
                                table.insert(tierItems, {
                                    title = w.label .. ' (x' .. w.count .. ')',
                                    description = 'Requires Rank ' .. w.rank,
                                    onSelect = function()
                                        if playerData.job.grade.level >= w.rank then
                                            TriggerServerEvent('cidweapons:take', w.weapon)
                                        else
                                            Wrappers.Notify('Need rank ' .. w.rank, 'error')
                                        end
                                    end
                                })
                            end
                            table.insert(items, { title = label, icon = 'fas fa-star', menu = tierItems })
                        end
                    end
                    Wrappers.ContextMenu({ id = 'cid_secret_armory', title = 'CID Secret Armory', menuItems = items })
                end,
            },
        },
    })
end)
