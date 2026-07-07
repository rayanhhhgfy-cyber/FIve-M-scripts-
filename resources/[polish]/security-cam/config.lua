Config = Config or {}
Config.SecurityCam = {
    cameras = {
        { id = 1, label = 'Bank Entrance', coords = vector3(235.45, 216.67, 106.29), rot = vector3(0.0, 0.0, 140.0), fov = 90.0 },
        { id = 2, label = 'Bank Vault', coords = vector3(255.67, 223.45, 106.29), rot = vector3(0.0, 0.0, 180.0), fov = 70.0 },
        { id = 3, label = 'Jewelry Store', coords = vector3(-634.56, -236.45, 38.06), rot = vector3(0.0, 0.0, 0.0), fov = 90.0 },
        { id = 4, label = '24/7 Convenience', coords = vector3(24.56, -1346.78, 29.50), rot = vector3(0.0, 0.0, 30.0), fov = 90.0 },
    },
    monitorModels = { -1667308485, -1417809388 },
    maxDistance = 2.0,
    switchDelay = 500,
    groups = { 'police', 'sheriff' },
}
