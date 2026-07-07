Config = Config or {}

Config.PolyZone = {
    debugMode = false,
    drawDistance = 100.0,
    updateInterval = 500,
    useGrid = true,
    gridCellSize = 10.0,
    maxZonesPerPlayer = 50
}

Config.Defaults = {
    box = {
        heading = 0,
        minZ = 0,
        maxZ = 100,
        debugPoly = false
    },
    circle = {
        radius = 5.0,
        debugPoly = false
    },
    poly = {
        minZ = 0,
        maxZ = 100,
        debugPoly = false
    }
}
