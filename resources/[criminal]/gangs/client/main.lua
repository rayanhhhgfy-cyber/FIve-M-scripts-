local QBox = exports['qbx-core']:GetCoreObject()
local ox_target = exports.ox_target
local ox_lib = exports.ox_lib

local currentGang = nil
local currentGrade = 0

local function hasPermission(perm)
    if not currentGang then return false end
    local perms = Config.Hierarchy[currentGrade + 1].permissions
    if perms[1] == 'all' then return true end
    for _, p in ipairs(perms) do
        if p == perm then return true end
    end
    return false
end

local function openGangMenu()
    local options = {}
    if not currentGang then
        options[#options + 1] = {
            title = 'Create Gang',
            description = 'Cost: $' .. Config.GangCreation.cost,
            onSelect = function()
                TriggerServerEvent('gangs:server:createGang')
            end
        }
        options[#options + 1] = {
            title = 'Join Gang',
            description = 'Enter gang name',
            onSelect = function()
                local input = ox_lib:inputDialog('Join Gang', { { type = 'input', label = 'Gang Name', required = true } })
                if input then
                    TriggerServerEvent('gangs:server:requestJoin', input[1])
                end
            end
        }
    else
        options[#options + 1] = {
            title = 'Gang Info',
            description = 'View gang details',
            onSelect = function()
                TriggerServerEvent('gangs:server:getGangInfo')
            end
        }
        if hasPermission('stash_browse') then
            options[#options + 1] = {
                title = 'Gang Stash',
                description = 'Access gang storage',
                onSelect = function()
                    TriggerServerEvent('gangs:server:openStash')
                end
            }
        end
        if hasPermission('invite') then
            options[#options + 1] = {
                title = 'Invite Player',
                description = 'Invite a nearby player',
                onSelect = function()
                    TriggerServerEvent('gangs:server:inviteNearest')
                end
            }
        end
        if hasPermission('kick') then
            options[#options + 1] = {
                title = 'Kick Member',
                description = 'Remove a gang member',
                onSelect = function()
                    TriggerServerEvent('gangs:server:getMembers')
                    Citizen.Wait(100)
                end
            }
        end
        options[#options + 1] = {
            title = 'Leave Gang',
            description = 'Leave your current gang',
            onSelect = function()
                TriggerServerEvent('gangs:server:leaveGang')
            end
        }
    end
    ox_lib:registerContext({
        id = 'gang_menu',
        title = 'Gang Menu',
        options = options
    })
    ox_lib:showContext('gang_menu')
end

local function openStashUI()
    local stashData = {
        id = 'gang_stash_' .. currentGang,
        label = 'Gang Stash',
        slots = Config.Stash.slots,
        weight = Config.Stash.weight
    }
    TriggerServerEvent('gangs:server:validateStashAccess', stashData)
end

local function setupNPC()
    ox_target:removeZone('gang_recruiter')
    ox_target:addBoxZone({
        name = 'gang_recruiter',
        coords = Config.GangCreation.npcCoords,
        size = vec3(1.5, 1.5, 1.0),
        rotation = 0,
        debug = false,
        options = {
            {
                name = 'gang_menu',
                label = Config.GangCreation.npcLabel,
                icon = 'fas fa-users',
                onSelect = function()
                    openGangMenu()
                end
            }
        }
    })
end

local function setupGangHQs()
    for _, hq in ipairs(Config.GangHQs) do
        local blip = AddBlipForCoord(hq.coords)
        SetBlipSprite(blip, Config.Blip.sprite)
        SetBlipColour(blip, Config.Blip.color)
        SetBlipScale(blip, Config.Blip.scale)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(Config.Blip.label .. ' - ' .. hq.label)
        EndTextCommandSetBlipName(blip)
    end
end

Citizen.CreateThread(function()
    setupNPC()
    setupGangHQs()
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    TriggerServerEvent('gangs:server:getPlayerGang')
    setupNPC()
end)

RegisterNetEvent('gangs:client:setGang', function(gang, grade)
    currentGang = gang
    currentGrade = grade
end)

RegisterNetEvent('gangs:client:receiveInfo', function(info)
    ox_lib:notify({
        title = 'Gang Info',
        description = info,
        type = 'inform'
    })
end)

RegisterNetEvent('gangs:client:showMembers', function(members)
    local options = {}
    for _, member in ipairs(members) do
        options[#options + 1] = {
            title = member.name .. ' (' .. Config.Hierarchy[member.grade + 1].label .. ')',
            onSelect = function()
                local action = ox_lib:inputDialog('Action for ' .. member.name, {
                    { type = 'select', label = 'Action', options = { { value = 'kick', label = 'Kick' }, { value = 'promote', label = 'Promote' }, { value = 'demote', label = 'Demote' } } }
                })
                if action then
                    TriggerServerEvent('gangs:server:memberAction', member.citizenid, action[1])
                end
            end
        }
    end
    ox_lib:registerContext({
        id = 'gang_members',
        title = 'Gang Members',
        options = options
    })
    ox_lib:showContext('gang_members')
end)

RegisterNetEvent('gangs:client:openStash', function(stashData)
    ox_lib:openStash(stashData)
end)

RegisterNetEvent('gangs:client:invitePrompt', function(inviter)
    local alert = ox_lib:alertDialog({
        title = 'Gang Invite',
        content = inviter .. ' has invited you to join their gang',
        buttons = { { label = 'Accept', type = 'confirm' }, { label = 'Decline', type = 'cancel' } }
    })
    if alert == 'confirm' then
        TriggerServerEvent('gangs:server:acceptInvite')
    end
end)
