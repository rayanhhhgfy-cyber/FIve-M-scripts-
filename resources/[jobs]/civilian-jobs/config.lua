Config = Config or {}
Config.CivilianJobs = {
    busDriver = {
        jobName = 'busdriver',
        routes = {
            { id = 'route_1', name = 'Downtown Loop', stops = {
                vector3(440.0, -980.0, 30.0), vector3(300.0, -800.0, 30.0), vector3(150.0, -1050.0, 30.0), vector3(-200.0, -1000.0, 30.0), vector3(-500.0, -900.0, 30.0),
            }, pay = 150 },
            { id = 'route_2', name = 'Beach Run', stops = {
                vector3(-1800.0, -1200.0, 13.0), vector3(-1600.0, -1100.0, 14.0), vector3(-1400.0, -1000.0, 14.0), vector3(-1200.0, -900.0, 14.0),
            }, pay = 200 },
            { id = 'route_3', name = 'Sandy Shores Express', stops = {
                vector3(1502.0, 3921.0, 31.0), vector3(1800.0, 3800.0, 33.0), vector3(2000.0, 3700.0, 32.0),
            }, pay = 250 },
        },
        busModel = 'bus',
        vehicleSpawn = vector3(450.0, -1020.0, 28.0),
    },
    garbageCollector = {
        jobName = 'garbage',
        payPerStop = 50,
        stops = {
            vector3(250.0, -800.0, 30.0), vector3(300.0, -900.0, 30.0), vector3(200.0, -1000.0, 30.0),
            vector3(100.0, -1100.0, 29.0), vector3(0.0, -1200.0, 29.0), vector3(-100.0, -1300.0, 29.0),
            vector3(-200.0, -1400.0, 30.0), vector3(-300.0, -1500.0, 30.0), vector3(-400.0, -1600.0, 30.0),
        },
        truckModel = 'trash',
        vehicleSpawn = vector3(-320.0, -1550.0, 27.0),
    },
    mailCarrier = {
        jobName = 'mail',
        payPerDelivery = 75,
        routes = {
            { id = 'mail_1', name = 'Downtown Mail', deliveries = {
                vector3(250.0, -800.0, 30.0), vector3(300.0, -900.0, 30.0), vector3(200.0, -1000.0, 30.0),
            }},
            { id = 'mail_2', name = 'Vinewood Mail', deliveries = {
                vector3(600.0, 100.0, 90.0), vector3(700.0, 200.0, 90.0), vector3(800.0, 300.0, 90.0),
            }},
        },
        vanModel = 'boxville',
        vehicleSpawn = vector3(100.0, -1200.0, 29.0),
    },
    towTruck = {
        jobName = 'tow',
        callPrice = 100,
        payPerTow = 200,
        truckModel = 'flatbed',
        vehicleSpawn = vector3(400.0, -1650.0, 29.0),
        callRadius = 5000.0,
    },
}
