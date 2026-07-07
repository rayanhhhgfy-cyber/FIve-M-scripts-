Logs = Logs or {}

function Logs.Send(webhook, title, message, color, fields, footer)
    local payload = {
        embeds = {{
            title = title or 'Log',
            description = message or '',
            color = color or Config.Embeds.color or 3066993,
            fields = fields or {},
            footer = { text = footer or Config.Embeds.footer or 'FiveM Server Logs' },
            timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')
        }}
    }
    local url = webhook or Config.Webhooks[Config.DefaultWebhook] or ''
    if url and url ~= '' then
        PerformHttpRequest(url, function(err, text, headers) end, 'POST', json.encode(payload), { ['Content-Type'] = 'application/json' })
    end
end

function Logs.Kill(killer, killerId, victim, victimId, weapon)
    Logs.Send(
        Config.Webhooks.kill,
        'Player Kill',
        string.format(Locales['log_kill'], killer, killerId, victim, victimId, weapon),
        Config.LogLevels.error
    )
end

function Logs.BankTransaction(citizenId, type, amount, reason)
    Logs.Send(
        Config.Webhooks.bank,
        'Bank Transaction',
        string.format(Locales['log_bank_transaction'], citizenId, type, amount, reason),
        Config.LogLevels.info
    )
end

function Logs.AdminAction(admin, action, target)
    Logs.Send(
        Config.Webhooks.admin,
        'Admin Action',
        string.format(Locales['log_admin'], admin, action, target),
        Config.LogLevels.warn
    )
end

function Logs.InventoryAction(player, item, amount, fromContainer, toContainer)
    Logs.Send(
        Config.Webhooks.inventory,
        'Inventory Action',
        string.format(Locales['log_inventory'], player, item, amount, fromContainer, toContainer),
        Config.LogLevels.info
    )
end

function Logs.PlayerJoin(name, id)
    Logs.Send(
        Config.Webhooks.joinleave,
        'Player Joined',
        string.format(Locales['log_join'], name, id),
        Config.LogLevels.success
    )
end

function Logs.PlayerLeave(name, id)
    Logs.Send(
        Config.Webhooks.joinleave,
        'Player Left',
        string.format(Locales['log_leave'], name, id),
        Config.LogLevels.warn
    )
end

function Logs.AntiCheat(playerId, reason, metadata)
    Logs.Send(
        Config.Webhooks.anticheat,
        'Anti-Cheat Trigger',
        string.format('**Player:** %s\n**Reason:** %s\n**Metadata:** %s', playerId, reason, json.encode(metadata or {})),
        Config.LogLevels.critical
    )
end

function Logs.VehicleAction(player, action, plate, vehicle)
    Logs.Send(
        Config.Webhooks.vehicle,
        'Vehicle Action',
        string.format('**Player:** %s\n**Action:** %s\n**Plate:** %s\n**Vehicle:** %s', player, action, plate, vehicle),
        Config.LogLevels.info
    )
end

function Logs.Custom(category, title, message, color, fields)
    local webhook = Config.Webhooks[category] or Config.Webhooks[Config.DefaultWebhook]
    Logs.Send(webhook, title, message, color, fields)
end
