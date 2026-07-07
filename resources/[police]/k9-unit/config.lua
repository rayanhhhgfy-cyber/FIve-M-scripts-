Config = Config or {}
Config.K9 = Config.K9 or {}

Config.K9 = {
    dogModel = 'a_c_shepherd',
    followDistance = 2.5,
    runSpeed = 8.0,
    walkSpeed = 2.5,
    barkInterval = 8000,
    searchRadius = 30.0,
    biteDamage = 15,
    biteCooldown = 3000,
    trackBreadcrumbInterval = 2000,
    maxBreadcrumbs = 50,
    breadcrumbLifetime = 120,
    animations = {
        idle = { dict = 'creatures@rottweiler@amb@world_dog_barking@base', clip = 'base' },
        bark = { dict = 'creatures@rottweiler@amb@world_dog_barking@idle_a', clip = 'idle_a' },
        run = { dict = 'creatures@rottweiler@amb@world_dog_barking@base', clip = 'base' },
    },
    alertSound = {
        dict = 'amb_creatures_dog',
        ref = 'WOOF',
    }
}
