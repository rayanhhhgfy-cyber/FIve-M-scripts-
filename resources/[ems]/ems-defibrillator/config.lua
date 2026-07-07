Config = Config or {}

Config.Defibrillator = {
    itemName = 'defibrillator',
    useTime = 8000,
    successRate = 0.85,
    cprTime = 15000,
    cprSuccessRate = 0.40,
    chargeTime = 3000,
    cooldown = 5000,
    maxDistance = 2.0,
    requireMedicJob = true,
    medicJobName = 'ambulance'
}

Config.Animations = {
    defibrillator = {
        dict = 'mini_cpr',
        clip = 'cpr_pumpchest',
        prop = 'prop_defib_01',
        propBone = 28422
    },
    cpr = {
        dict = 'mini_cpr',
        clip = 'cpr_pumpchest'
    },
    charge = {
        dict = 'anim@amb@medic@standing@timeofdeath@base',
        clip = 'base'
    }
}

Config.Sounds = {
    defib_charge = { name = 'defib_charge', volume = 0.7, distance = 10.0 },
    defib_shock = { name = 'defib_shock', volume = 1.0, distance = 15.0 },
    cpr_compress = { name = 'cpr_compress', volume = 0.5, distance = 5.0 },
    revive_success = { name = 'revive_success', volume = 0.7, distance = 10.0 }
}
