local playerKeybinds = {}

Citizen.CreateThread(function()
    -- Register key mappings through FiveM API so they appear in ESC > Settings > KeyBindings
    for _, kb in ipairs(Config.Settings.registeredKeybinds) do
        if kb.command ~= 'windows up' and kb.command ~= 'windows down' then
            RegisterKeyMapping('+' .. kb.command:gsub(' ', '_'), kb.label, 'keyboard', kb.defaultKey)
        end
    end

    -- Register the windows toggle with two arguments
    RegisterKeyMapping('+windows_up', 'Roll Windows Up', 'keyboard', 'F9')
    RegisterKeyMapping('+windows_down', 'Roll Windows Down', 'keyboard', 'F9')
    RegisterKeyMapping('+door_menu', 'Toggle Door Menu', 'keyboard', 'F10')
    RegisterKeyMapping('+trunk_toggle', 'Toggle Trunk', 'keyboard', 'F11')
    RegisterKeyMapping('+frunk_toggle', 'Toggle Frunk', 'keyboard', 'F12')
end)

RegisterCommand('+windows_up', function() ExecuteCommand('windows up') end)
RegisterCommand('+windows_down', function() ExecuteCommand('windows down') end)
RegisterCommand('+door_menu', function() ExecuteCommand('door') end)
RegisterCommand('+trunk_toggle', function() ExecuteCommand('trunk') end)
RegisterCommand('+frunk_toggle', function() ExecuteCommand('frunk') end)

RegisterCommand('settings', function()
    OpenSettingsMenu()
end)

function OpenSettingsMenu()
    local items = {
        { title = 'View Keybinds', icon = 'fas fa-keyboard', onSelect = function() ShowKeybinds() end },
        { title = 'About Server', icon = 'fas fa-info-circle', onSelect = function()
            Wrappers.AlertDialog({ title = 'Server Information', content = 'Welcome to the server!\n\nUse /settings to open this menu anytime.', icon = 'fas fa-server', color = '#4CAF50' })
        end },
    }
    Wrappers.ContextMenu({ id = 'settings_menu', title = 'Settings', menuItems = items })
end

function ShowKeybinds()
    local items = {}
    for _, kb in ipairs(Config.Settings.registeredKeybinds) do
        table.insert(items, { title = kb.label, description = 'Command: /' .. kb.command .. ' | Default: ' .. kb.defaultKey })
    end
    table.insert(items, { title = 'Hint', description = 'Change keybinds via ESC > Settings > Key Bindings > FiveM', icon = 'fas fa-lightbulb' })
    Wrappers.ContextMenu({ id = 'settings_keybinds', title = 'Keybinds', menuItems = items })
end

-- Auto-prompt settings after player loads
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Citizen.Wait(5000)
    Wrappers.Notify('Type /settings to customize your keybinds', 'info')
end)

RegisterNetEvent('ox:playerLoaded', function()
    Citizen.Wait(5000)
    Wrappers.Notify('Type /settings to customize your keybinds', 'info')
end)
