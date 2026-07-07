local QBox = exports['qbx-core']:GetCoreObject()
local vpnConnected = false
local currentServer = nil
local vpnActive = false

local function hasVPN() return QBox.Functions.HasItem(Config.VPN.ItemName) end

RegisterNetEvent('vpn:toggle', function()
    if not hasVPN() then Wrappers.Notify(Locale('phone.no_vpn'), 'error') return end
    local serverItems = {}
    for sId, sData in pairs(Config.VPN.Servers) do
        table.insert(serverItems, { title = sData.label .. ' (' .. sData.latency .. 'ms)', description = sData.anonymous and Locale('phone.anonymous') or Locale('phone.standard'), onSelect = function()
            TriggerEvent('vpn:connect', sId)
        end})
    end
    if vpnConnected then
        table.insert(serverItems, { title = Locale('phone.disconnect_vpn'), onSelect = function() TriggerEvent('vpn:disconnect') end })
    end
    Wrappers.ContextMenu({ id = 'vpn_menu', title = Config.VPN.AppName, menuItems = serverItems })
end)

RegisterNetEvent('vpn:connect', function(serverId)
    local sData = Config.VPN.Servers[serverId]
    if not sData then return end
    Wrappers.ProgressBar({ label = Locale('phone.connecting_vpn', sData.label), duration = 3000, useWhileDead = false, canCancel = true }, function(cancelled)
        if cancelled then return end
        vpnConnected = true
        currentServer = serverId
        vpnActive = true
        TriggerServerEvent('vpn:server:connected', serverId)
        Wrappers.Notify(Locale('phone.vpn_connected', sData.label), 'success')
    end)
end)

RegisterNetEvent('vpn:disconnect', function()
    if not vpnConnected then return end
    vpnConnected = false
    currentServer = nil
    vpnActive = false
    TriggerServerEvent('vpn:server:disconnected')
    Wrappers.Notify(Locale('phone.vpn_disconnected'), 'info')
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if Config.VPN.UI.ShowStatus and vpnActive then
            local server = Config.VPN.Servers[currentServer]
            if server then
                SetTextFont(4); SetTextScale(0.35, 0.35)
                SetTextColour(Config.VPN.UI.ColorConnected.r, Config.VPN.UI.ColorConnected.g, Config.VPN.UI.ColorConnected.b, 255)
                SetTextEntry('STRING')
                AddTextComponentString(Locale('phone.vpn_status', server.label))
                DrawText(0.01, 0.01)
            end
        end
        Citizen.Wait(0)
    end
end)
