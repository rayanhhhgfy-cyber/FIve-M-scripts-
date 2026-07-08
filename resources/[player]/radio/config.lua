Config = Config or {}

Config.RadioItem = 'radio'

Config.RestrictedChannels = {
    [1] = {
        police = true,
        ambulance = true
    },
    [2] = {
        police = true,
        ambulance = true
    },
    [3] = {
        police = true,
        ambulance = true
    },
    [4] = {
        police = true,
        ambulance = true
    },
    [5] = {
        police = true,
        ambulance = true
    },
    [6] = {
        police = true,
        ambulance = true
    },
    [7] = {
        police = true,
        ambulance = true
    },
    [8] = {
        police = true,
        ambulance = true
    },
    [9] = {
        police = true,
        ambulance = true
    },
    [10] = {
        police = true,
        ambulance = true
    }
}

Config.MaxFrequency = 500

Config.ChannelLabels = {
    [1] = 'LSPD Main',
    [2] = 'LSPD Secondary',
    [3] = 'LSPD Tactical',
    [4] = 'CID Main',
    [5] = 'CID Tactical',
    [6] = 'EMS Main',
    [7] = 'EMS Secondary',
    [8] = 'EMS Tactical',
    [9] = 'LSPD Air',
    [10] = 'LSPD Events',
}

Config.JobChannels = {
    police = { 1, 2, 3, 9, 10 },
    cid = { 4, 5 },
    ambulance = { 6, 7, 8 },
}