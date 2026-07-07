Config = Config or {}

Config.Grapple = {
    ItemName = 'grappling_hook',
    ItemLabel = 'Grappling Hook',
    ThrowTime = 1500,
    ReelSpeed = 15.0,
    MaxRange = 50.0,
    BreakForce = 100.0,
    RopeTexture = 'rope_polyurethane',
    RopeLength = 50.0,
    AllowSwing = true,
    AllowClimb = true,
    AllowDescend = true,
    RequireDuty = false,
    MinRank = 0,
    AllowedJobs = { 'police', 'sheriff', 'statepolice' },
    RopeColor = { r = 50, g = 50, b = 50 },

    Cooldown = {
        throw = 3000,
        climb = 500,
    }
}
