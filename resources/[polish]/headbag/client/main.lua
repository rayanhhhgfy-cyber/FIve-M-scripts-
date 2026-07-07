local QBox = exports['qbx-core']:GetCoreObject()
local bagActive = false

RegisterNetEvent('headbag:applyBag', function()
    bagActive = true
    DoScreenFadeOut(500)
    Wait(500)
    SetPedComponentEnabled(PlayerPedId(), 1, 140, 0, 0)
    DoScreenFadeIn(500)
    CreateThread(function()
        while bagActive do
            Wait(50)
            SetPedMinGroundTimeForStungun(PlayerPedId(), 100000)
            DisableControlAction(0, 75, true)
            SetTextFont(4)
            SetTextScale(0.5, 0.5)
            SetTextColour(255, 255, 255, 255)
            SetTextCentre(true)
            SetTextEntry('STRING')
            AddTextComponentString(Locale('headbag.applied'))
            DrawText(0.5, 0.5)
        end
    end)
end)

RegisterNetEvent('headbag:removeBag', function()
    bagActive = false
    DoScreenFadeOut(500)
    Wait(500)
    SetPedComponentEnabled(PlayerPedId(), 1, 0, 0, 0)
    DoScreenFadeIn(500)
end)

RegisterNetEvent('headbag:applied', function()
    Wrappers.Notify(Locale('headbag.applied'), 'success')
end)

exports.ox_target:addGlobalPlayer({
    {
        name = 'headbag_apply',
        label = Locale('headbag.apply'),
        icon = 'fas fa-mask',
        canInteract = function(entity)
            local item = QBox.Functions.GetPlayerData().items
            for _, v in ipairs(item or {}) do
                if v.name == Config.Headbag.item then return true end
            end
            return false
        end,
        onSelect = function(data)
            TriggerServerEvent('headbag:apply', GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity)))
        end,
    },
})
