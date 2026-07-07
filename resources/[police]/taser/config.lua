Config = Config or {}

Config.Taser = {
    WeaponHash = 'WEAPON_STUNGUN',
    MaxRange = 15.0,
    StunDuration = 8000,
    RagdollDuration = 5000,
    Cooldown = 10000,
    ChargeTime = 1000,
    RequireDuty = true,
    MinRank = 0,
    AllowedJobs = { 'police', 'sheriff', 'statepolice' },
    AmpHighMultiplier = 2.0,
    AmpLowMultiplier = 0.5,
    DamageEnabled = true,
    DamageAmount = 5,

    Effects = {
        ScreenShake = true,
        ScreenShakeIntensity = 0.5,
        ScreenShakeDuration = 1000,
        FlashEffect = true,
        FlashDuration = 100,
        SoundEnabled = true,
        SoundName = 'Stungun_Shoot_01',
        SoundDict = 'WEAPON_STUNGUN_SOUNDS'
    },

    Arcs = {
        Enabled = true,
        Duration = 2000,
        Color = { r = 0, g = 100, b = 255 },
        Thickness = 0.5
    }
}
