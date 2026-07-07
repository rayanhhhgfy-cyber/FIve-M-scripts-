Config = Config or {}

Config.Shields = {
    ItemName = 'police_shield',
    ItemLabel = 'Ballistic Shield',
    ObjectModel = 'prop_riot_shield',
    Bone = 24818,
    Offset = vector3(0.0, 0.15, 0.0),
    Rotation = vector3(0.0, 0.0, 0.0),
    DeployTime = 2000,
    StoreTime = 1500,
    Health = 500,
    BlockChance = 85,
    SpeedReduction = 0.5,
    DisableWeapons = true,
    RequireDuty = true,
    MinRank = 2,
    AllowedJobs = { 'police', 'sheriff', 'statepolice' },
    MaxCarry = 1,

    Animations = {
        Deploy = {
            dict = 'misscommon@generic_menu',
            clip = 'give_item',
            flags = 1,
            duration = 2000
        },
        Carry = {
            dict = 'combat@gestures@gang@var_e',
            clip = '0f',
            flags = 50
        },
        Store = {
            dict = 'misscommon@generic_menu',
            clip = 'give_item',
            flags = 1,
            duration = 1500
        }
    }
}
