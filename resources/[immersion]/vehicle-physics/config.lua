Config = Config or {}

Config.Flip = {
    enabled = true,
    disableDefaultFlip = true,
    flipRange = 3.0,
    flipTime = 5000,
    flipForce = 5000.0
}

Config.VehicleClasses = {
    { class = 'compact', flipPlayers = 1, pushForce = 3.0, label = 'Compact' },
    { class = 'coupe', flipPlayers = 1, pushForce = 3.5, label = 'Coupe' },
    { class = 'sedan', flipPlayers = 1, pushForce = 4.0, label = 'Sedan' },
    { class = 'suv', flipPlayers = 2, pushForce = 5.0, label = 'SUV' },
    { class = 'offroad', flipPlayers = 2, pushForce = 5.5, label = 'Offroad' },
    { class = 'van', flipPlayers = 2, pushForce = 6.0, label = 'Van' },
    { class = 'truck', flipPlayers = 3, pushForce = 8.0, label = 'Truck' },
    { class = 'bus', flipPlayers = 4, pushForce = 10.0, label = 'Bus' },
    { class = 'industrial', flipPlayers = 4, pushForce = 12.0, label = 'Industrial' }
}

Config.ClassLookup = {
    [0] = 'compact', [1] = 'sedan', [2] = 'suv', [3] = 'coupe',
    [4] = 'industrial', [5] = 'industrial', [6] = 'industrial',
    [7] = 'coupe', [8] = 'motorcycle', [9] = 'offroad',
    [10] = 'offroad', [11] = 'sedan', [12] = 'van',
    [13] = 'cycle', [14] = 'boat', [15] = 'helicopter',
    [16] = 'plane', [17] = 'service', [18] = 'emergency',
    [19] = 'emergency', [20] = 'emergency', [21] = 'truck',
    [22] = 'truck', [23] = 'truck'
}

Config.Push = {
    enabled = true,
    pushRange = 3.0,
    pushForce = 50.0,
    canPushOnFoot = true,
    canPushInVehicle = false
}
