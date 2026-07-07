Config = Config or {}

Config.AdvancedTow = {
    TowingVehicles = { 'towtruck', 'towtruck2', 'flatbed' },
    MaxTowDistance = 50.0,
    AttachTime = 5000,
    DetachTime = 3000,
    TowSpeed = 30.0,
    JobName = 'tow',
    RequireJob = false,
    PaymentPerMeter = 2,
    MinPayment = 100,
    MaxPayment = 500,
    RopeModel = 'rope_polyurethane',

    AttachControls = { { key = 'E', label = 'Attach/Detach Vehicle' } },
    TargetOptions = {
        attach = { icon = 'fas fa-link', label = 'Attach Vehicle', distance = 3.0 },
        detach = { icon = 'fas fa-unlink', label = 'Detach Vehicle', distance = 3.0 }
    }
}
