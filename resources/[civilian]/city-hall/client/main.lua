local interiorLoaded = false
local cityHallNPC = nil
local insideCityHall = false

--- Load the city hall interior IPL
local function loadInterior()
    if interiorLoaded then return end
    RequestIpl(Config.CityHall.Interior.ipl)
    interiorLoaded = true
end

--- Spawn the NPC at the city hall desk
local function spawnNPC()
    if cityHallNPC and DoesEntityExist(cityHallNPC) then return end

    local model = Config.CityHall.NPC.model
    RequestModel(model)
    local attempts = 0
    while not HasModelLoaded(model) and attempts < 100 do
        Wait(10)
        attempts = attempts + 1
    end

    if not HasModelLoaded(model) then return end

    local coords = Config.CityHall.NPC.coords
    cityHallNPC = CreatePed(4, model, coords.x, coords.y, coords.z, Config.CityHall.NPC.heading, false, false)
    SetEntityInvincible(cityHallNPC, true)
    SetPedFleeAttributes(cityHallNPC, 0, true)
    SetBlockingOfNonTemporaryEvents(cityHallNPC, true)
    FreezeEntityPosition(cityHallNPC, true)
    SetPedCanRagdoll(cityHallNPC, false)
end

--- Enter city hall
local function enterCityHall()
    DoScreenFadeOut(300)
    Wait(500)

    loadInterior()
    SetNewWaypoint(Config.CityHall.Interior.coords.x, Config.CityHall.Interior.coords.y)

    SetEntityCoords(PlayerPedId(), Config.CityHall.Interior.coords.x, Config.CityHall.Interior.coords.y, Config.CityHall.Interior.coords.z)
    SetEntityHeading(PlayerPedId(), Config.CityHall.Interior.heading)

    Wait(500)
    DoScreenFadeIn(300)

    insideCityHall = true

    spawnNPC()
    setupExitZone()
    setupNPCTarget()
end

--- Exit city hall
local function exitCityHall()
    DoScreenFadeOut(300)
    Wait(500)

    SetEntityCoords(PlayerPedId(), Config.CityHall.Exterior.coords.x, Config.CityHall.Exterior.coords.y, Config.CityHall.Exterior.coords.z)
    SetEntityHeading(PlayerPedId(), Config.CityHall.Exterior.heading)

    Wait(500)
    DoScreenFadeIn(300)

    insideCityHall = false
end

--- Setup exit target zone
local function setupExitZone()
    exports.ox_target:removeZone('cityhall_exit')
    exports.ox_target:addSphereZone({
        coords = Config.CityHall.Exit.coords,
        radius = 1.5,
        debug = false,
        options = {
            {
                name = 'cityhall_exit',
                icon = 'fas fa-door-open',
                label = 'Exit City Hall',
                distance = 2.5,
                onSelect = function()
                    exitCityHall()
                end,
            }
        }
    })
end

--- Setup NPC target options
local function setupNPCTarget()
    exports.ox_target:removeZone('cityhall_npc')

    local npcCoords = Config.CityHall.NPC.coords
    exports.ox_target:addSphereZone({
        coords = npcCoords,
        radius = 2.5,
        debug = false,
        options = {
            {
                name = 'cityhall_npc_id',
                icon = 'fas fa-id-card',
                label = 'Request ID Card ($' .. Config.CityHall.Prices.idCard .. ')',
                distance = 2.5,
                onSelect = function()
                    lib.callback('cityhall:server:requestID', false, function(success, msg)
                        Wrappers.Notify(msg, success and 'success' or 'error')
                    end)
                end,
            },
            {
                name = 'cityhall_npc_card',
                icon = 'fas fa-credit-card',
                label = 'Request Bank Card ($' .. Config.CityHall.Prices.bankCard .. ')',
                distance = 2.5,
                onSelect = function()
                    lib.callback('cityhall:server:requestBankCard', false, function(success, msg)
                        Wrappers.Notify(msg, success and 'success' or 'error')
                    end)
                end,
            },
            {
                name = 'cityhall_npc_info',
                icon = 'fas fa-info-circle',
                label = 'Check Citizen Record',
                distance = 2.5,
                onSelect = function()
                    local player = QBox.Functions.GetPlayerData()
                    local name = (player.charinfo.firstname or 'N/A') .. ' ' .. (player.charinfo.lastname or '')
                    Wrappers.AlertDialog({
                        title = 'Citizen Record',
                        content = string.format(
                            'Name: %s\nCID: %s\nDOB: %s\nIssued: N/A',
                            name,
                            player.citizenid or 'N/A',
                            (player.charinfo.birthdate or 'N/A')
                        ),
                        icon = 'fas fa-id-card',
                        color = '#667eea',
                    })
                end,
            },
        }
    })
end

--- Exterior entrance target
Citizen.CreateThread(function()
    Wait(1000)
    exports.ox_target:addSphereZone({
        coords = Config.CityHall.Exterior.coords,
        radius = 1.5,
        debug = false,
        options = {
            {
                name = 'cityhall_enter',
                icon = 'fas fa-building',
                label = 'Enter City Hall',
                distance = 3.0,
                onSelect = function()
                    enterCityHall()
                end,
            },
        }
    })
end)

--- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    if cityHallNPC and DoesEntityExist(cityHallNPC) then
        DeleteEntity(cityHallNPC)
    end
    if interiorLoaded then
        RemoveIpl(Config.CityHall.Interior.ipl)
    end
end)
