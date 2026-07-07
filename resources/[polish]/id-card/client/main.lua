local QBCore = exports['qbx_core']:GetCoreObject()

local function displayIDCard(data)
    local lines = {
        ('%s: %s %s'):format(Locale('id_card.name'), data.firstName, data.lastName),
        ('%s: %s'):format(Locale('id_card.dob'), data.dob),
        ('%s: %s'):format(Locale('id_card.sex'), data.sex),
        ('%s: %s'):format(Locale('id_card.citizenid'), data.citizenid),
        ('%s: %s'):format(Locale('id_card.nationality'), data.nationality),
        ('%s: %s'):format(Locale('id_card.issued'), data.issued),
    }
    Wrappers.TextUI(table.concat(lines, '\n'))
    Wait(Config.IDCard.showDuration * 1000)
    Wrappers.HideTextUI()
end

RegisterNetEvent('idcard:client:display', function(data)
    displayIDCard(data)
end)

RegisterNetEvent('idcard:client:request', function(requester)
    local result = exports['ox_lib']:alertDialog({
        title = Locale('id_card.title'),
        content = Locale('id_card.show'),
        labels = { confirm = 'Yes', cancel = 'No' },
    })
    TriggerServerEvent('idcard:respond', requester, result)
end)

CreateThread(function()
    exports['ox_target']:addGlobalPlayer({
        {
            name = Locale('id_card.show'),
            icon = 'fas fa-id-card',
            onSelect = function(data)
                TriggerServerEvent('idcard:show')
            end,
        },
        {
            name = Locale('id_card.check'),
            icon = 'fas fa-search',
            onSelect = function(data)
                local closest, dist = Wrappers.GetClosestPlayer(GetEntityCoords(PlayerPedId()), Config.IDCard.maxHoldDistance)
                if not closest then return Wrappers.Notify(Locale('id_card.no_player'), 'error') end
                local target = GetPlayerServerId(closest)
                TriggerServerEvent('idcard:request', target)
            end,
        },
    })
end)
