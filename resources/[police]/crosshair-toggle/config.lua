Config = Config or {}

Config.Crosshair = {
    ToggleKey = 'F2',
    RequireDuty = true,
    RequireJob = true,
    AllowedJobs = { 'police', 'sheriff', 'statepolice' },
    CrosshairStyle = 'dot',
    CrosshairColor = { r = 255, g = 0, b = 0, a = 200 },
    CrosshairSize = 2.0,
    ShowOnAim = true,
    ShowOnHip = false,
    AlwaysVisible = false,
    HideInVehicle = true,

    Styles = {
        dot = { label = 'Dot', size = 2.0 },
        cross = { label = 'Cross', size = 3.0 },
        circle = { label = 'Circle', size = 4.0 },
        default = { label = 'Default (GTA)', size = 0.0 }
    }
}
