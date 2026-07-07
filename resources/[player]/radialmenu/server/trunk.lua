local QBox = exports['qbx_core']:GetCoreObject()
local trunkBusy = {}

function IsCloseToTarget(source, target)
    if not DoesPlayerExist(target) then return false end
    return #(GetEntityCoords(GetPlayerPed(source)) - GetEntityCoords(GetPlayerPed(target))) < 2.0
end

RegisterNetEvent('qb-radialmenu:trunk:server:Door', function(open, plate, door)
    TriggerClientEvent('qb-radialmenu:trunk:client:Door', -1, plate, door, open)
end)

RegisterNetEvent('qb-trunk:server:setTrunkBusy', function(plate, busy)
    trunkBusy[plate] = busy
end)

RegisterNetEvent('qb-trunk:server:KidnapTrunk', function(target, closestVehicle)
    local src = source
    if not IsCloseToTarget(src, target) then return end
    TriggerClientEvent('qb-trunk:client:KidnapGetIn', target, closestVehicle)
end)

lib.callback.register('qb-trunk:server:getTrunkBusy', function(_, plate)
    return trunkBusy[plate] and true or false
end)

QBox.Commands.Add('getintrunk', 'Get In Trunk', {}, false, function(source)
    TriggerClientEvent('qb-trunk:client:GetIn', source)
end)

QBox.Commands.Add('putintrunk', 'Put Player In Trunk', {}, false, function(source)
    TriggerClientEvent('qb-trunk:server:KidnapTrunk', source)
end)
