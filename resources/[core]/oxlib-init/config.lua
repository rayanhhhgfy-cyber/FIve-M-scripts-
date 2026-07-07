Config = Config or {}

Config.ProgressBar = {
    duration = 3000,
    label = 'Processing...',
    useWhileDead = false,
    canCancel = true,
    disableMovement = true,
    disableCarMovement = true,
    disableMouse = false,
    disableCombat = true,
    anim = {
        dict = 'anim@heists@money_grab@duffel',
        clip = 'walk'
    },
    prop = nil
}

Config.ContextMenu = {
    position = 'top-right',
    canClose = true,
    onBack = nil,
    onClose = nil
}

Config.InputDialog = {
    title = 'Input',
    options = {}
}

Config.SkillCheck = {
    difficulty = { 'easy', 'easy', 'medium' },
    inputs = { 'w', 'a', 's', 'd' },
    time = 5000
}

Config.Notify = {
    position = 'top-right',
    duration = 3000,
    style = {
        backgroundColor = '#141414',
        color = '#ffffff',
        ['border-radius'] = '6px'
    }
}

Config.TextUI = {
    position = 'bottom-center',
    icon = 'circle-info',
    style = {
        borderRadius = 6,
        backgroundColor = '#141414',
        color = '#ffffff'
    }
}

Config.AlertDialog = {
    title = 'Alert',
    content = '',
    centered = true,
    cancel = true,
    size = 'md',
    labels = {
        confirm = 'Confirm',
        cancel = 'Cancel'
    }
}
