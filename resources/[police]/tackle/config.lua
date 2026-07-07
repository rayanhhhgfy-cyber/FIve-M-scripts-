Config = Config or {}

Config.Tackle = {
    Range = 2.5,
    Cooldown = 5000,
    StunDuration = 4000,
    RagdollDuration = 3000,
    AnimationDuration = 1500,
    Damage = 10,
    RequireDuty = true,
    MinRank = 0,
    AllowedJobs = { 'police', 'sheriff', 'statepolice' },
    TackleOnHit = true,
    TackleOnRun = true,
    MaxSpeedForTackle = 7.0,
    Keybind = 'f', -- custom keybind concept - actual uses context menu approach

    TargetOptions = {
        icon = 'fas fa-running',
        label = 'Tackle',
        group = 'police',
        distance = 2.5
    }
}
