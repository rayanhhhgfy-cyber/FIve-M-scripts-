Config = Config or {}
Config.Admin = {
    groups = { 'admin', 'superadmin', 'god' },
    commands = {
        noclip = { label = 'Noclip', desc = 'Toggle noclip' },
        godmode = { label = 'Godmode', desc = 'Toggle godmode' },
        invisible = { label = 'Invisible', desc = 'Toggle invisibility' },
        freeze = { label = 'Freeze', desc = 'Freeze/unfreeze player' },
        revive = { label = 'Revive', desc = 'Revive self or target' },
        teleport = { label = 'Teleport', desc = 'Teleport to coordinates or player' },
        spawn = { label = 'Spawn Vehicle', desc = 'Spawn a vehicle by model' },
        ban = { label = 'Ban', desc = 'Ban a player' },
        kick = { label = 'Kick', desc = 'Kick a player' },
    },
}
