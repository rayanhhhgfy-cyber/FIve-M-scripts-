Config = Config or {}

Config.Job = 'delivery'
Config.VehicleModel = 'boxville'
Config.Spawn = vec3(920.0, -1150.0, 25.0)
Config.Depot = vec3(920.0, -1150.0, 25.0)
Config.PaymentPerPackage = 75
Config.BonusTime = 480
Config.BonusAmount = 200

Config.DeliveryLocations = {
    vec3(-30.0, -1050.0, 28.0),
    vec3(180.0, -750.0, 30.0),
    vec3(450.0, -450.0, 26.0),
    vec3(750.0, -100.0, 28.0),
    vec3(350.0, 200.0, 28.0),
    vec3(-150.0, 350.0, 26.0),
    vec3(-450.0, 50.0, 26.0),
    vec3(-250.0, -650.0, 28.0),
}

Config.DeliveryTime = 3000
Config.PackageCollectTime = 2000
