Config = Config or {}

Config.Emotes = {
    enabled = true,
    maxEmotes = 100,
    emoteCommand = 'e',
    walkingCommand = 'walk',
    cancelCommand = 'cancel',
    syncCommand = 'sync',
    sharedEmoteDistance = 3.0,
    propAttachEnabled = true,
    walkingStylesEnabled = true,
    cancelEmoteOnVehicle = true,
    cancelEmoteOnCombat = true
}

Config.SharedEmotes = {
    hug = {
        label = 'Hug',
        animDict = 'anim@mp_player_intcelebrationmale@hug',
        animClip = 'hug',
        targetAnimDict = 'anim@mp_player_intcelebrationpaired@hug',
        targetAnimClip = 'hug',
        distance = 1.0
    },
    handshake = {
        label = 'Handshake',
        animDict = 'mp_ped_interaction',
        animClip = 'handshake_guy_a',
        targetAnimDict = 'mp_ped_interaction',
        targetAnimClip = 'handshake_guy_b',
        distance = 1.5
    },
    highfive = {
        label = 'High Five',
        animDict = 'mp_ped_interaction',
        animClip = 'highfive_guy_a',
        targetAnimDict = 'mp_ped_interaction',
        targetAnimClip = 'highfive_guy_b',
        distance = 1.5
    }
}
