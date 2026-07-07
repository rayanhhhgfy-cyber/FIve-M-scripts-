local activeBlips = {}
local currentData = {}

local function clearBlips()
    for src, blip in pairs(activeBlips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end
    activeBlips = {}
end

local function updateBlips(data)
    for src, _ in pairs(activeBlips) do
        if not data[src] then
            if DoesBlipExist(activeBlips[src]) then RemoveBlip(activeBlips[src]) end
            activeBlips[src] = nil
        end
    end
    for src, info in pairs(data) do
        if info.onduty then
            local jobKey = info.job or 'police'
            local blipCfg = Config.DutyBlips.blips[jobKey] or {}
            if activeBlips[src] then
                local coords = vector3(info.coords.x, info.coords.y, info.coords.z)
                SetBlipCoords(activeBlips[src], coords.x, coords.y, coords.z)
                if Config.DutyBlips.showLabel then
                    local label = Config.DutyBlips.labelFormat
                    label = label:gsub('{name}', info.name):gsub('{job}', info.job)
                    BeginTextCommandSetBlipName('STRING')
                    AddTextComponentSubstringPlayerName(label)
                    EndTextCommandSetBlipName(activeBlips[src])
                end
            else
                local coords = vector3(info.coords.x, info.coords.y, info.coords.z)
                local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
                SetBlipSprite(blip, blipCfg.sprite or Config.DutyBlips.defaultSprite)
                SetBlipColour(blip, blipCfg.color or Config.DutyBlips.defaultColor)
                SetBlipScale(blip, blipCfg.scale or 0.7)
                SetBlipAsShortRange(blip, not Config.DutyBlips.showOnRadar)
                if Config.DutyBlips.showLabel then
                    local label = Config.DutyBlips.labelFormat
                    label = label:gsub('{name}', info.name):gsub('{job}', info.job)
                    BeginTextCommandSetBlipName('STRING')
                    AddTextComponentSubstringPlayerName(label)
                    EndTextCommandSetBlipName(blip)
                end
                activeBlips[src] = blip
            end
        end
    end
    currentData = data
end

RegisterNetEvent('duty-blips:client:update', function(data)
    updateBlips(data or {})
end)

AddEventHandler('onResourceStop', function(resName)
    if resName == GetCurrentResourceName() then
        clearBlips()
    end
end)
