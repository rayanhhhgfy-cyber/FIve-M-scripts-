local QBCore = exports['qbx_core']:GetCoreObject()
local isInMenu = false

function OpenCharacterSelection()
    if isInMenu then return end
    isInMenu = true
    local characters = lib.callback.await('multi-character:server:getCharacters', false)
    local spawnLocations = lib.callback.await('multi-character:server:getSpawnLocations', false)
    local maxSlots = lib.callback.await('multi-character:server:getMaxSlots', false)
    local menuOptions = {}
    for _, char in ipairs(characters) do
        local charData = json.decode(char.charinfo)
        local jobData = json.decode(char.job)
        local label = string.format('%s %s | %s | $%s',
            char.firstname, char.lastname,
            jobData.label or 'Unemployed',
            char.money and json.decode(char.money).cash or 0)
        table.insert(menuOptions, {
            title = label,
            description = string.format('Slot %d | CitizenID: %s', char.slot, char.citizenid),
            icon = 'fas fa-user',
            onSelect = function()
                TriggerServerEvent('multi-character:server:selectCharacter', char.citizenid)
                isInMenu = false
            end
        })
    end
    if #characters < maxSlots then
        table.insert(menuOptions, {
            title = 'Create New Character',
            description = string.format('Available slots: %d/%d', maxSlots - #characters, maxSlots),
            icon = 'fas fa-plus',
            onSelect = function()
                local input = lib.inputDialog('Create Character', {
                    { type = 'input', label = 'First Name', placeholder = 'John', required = true, min = 2, max = 50 },
                    { type = 'input', label = 'Last Name', placeholder = 'Doe', required = true, min = 2, max = 50 },
                    { type = 'select', label = 'Gender', options = { { value = 0, label = 'Male' }, { value = 1, label = 'Female' } }, default = 0 },
                    { type = 'input', label = 'Date of Birth', placeholder = '1990-01-01', default = '1990-01-01' },
                    { type = 'select', label = 'Nationality', options = { { value = 'American', label = 'American' }, { value = 'British', label = 'British' }, { value = 'Other', label = 'Other' } }, default = 'American' }
                })
                if input then
                    local success, msg = lib.callback.await('multi-character:server:createCharacter', false, {
                        firstname = input[1],
                        lastname = input[2],
                        gender = input[3],
                        birthdate = input[4],
                        nationality = input[5]
                    })
                    if not success then
                        Wrappers.Notify({ type = 'error', description = msg })
                    end
                end
                isInMenu = false
            end
        })
    end
    if Config.Character.allowDelete then
        for i, char in ipairs(characters) do
            table.insert(menuOptions, {
                title = string.format('Delete %s %s', char.firstname, char.lastname),
                description = 'WARNING: This cannot be undone!',
                icon = 'fas fa-trash',
                arrow = false,
                onSelect = function()
                    if Config.Character.requireDeleteConfirm then
                        local alert = lib.alertDialog({
                            header = 'Delete Character',
                            content = string.format('Delete %s %s? This cannot be undone.', char.firstname, char.lastname),
                            centered = true,
                            cancel = true,
                            labels = { confirm = 'Delete', cancel = 'Cancel' }
                        })
                        if alert ~= 'confirm' then return end
                    end
                    local success, msg = lib.callback.await('multi-character:server:deleteCharacter', false, char.slot)
                    Wrappers.Notify({ type = success and 'success' or 'error', description = msg })
                end
            })
        end
    end
    lib.registerContext({
        id = 'char_select_menu',
        title = 'Select Character',
        options = menuOptions
    })
    lib.showContext('char_select_menu')
end

RegisterNetEvent('qbx_spawn:client:openMenu', function()
    OpenCharacterSelection()
end)

RegisterNetEvent('multi-character:client:openSelection', function()
    OpenCharacterSelection()
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[multi-character] Character selection ready.^7')
end)

exports('OpenCharacterSelection', OpenCharacterSelection)
