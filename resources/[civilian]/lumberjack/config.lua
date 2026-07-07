Config = Config or {}

Config.JobName = 'lumberjack'
Config.AxeItem = 'lumberjack_axe'
Config.ChainsawItem = 'lumberjack_chainsaw'
Config.ChopTime = 8000
Config.ProcessTime = 5000
Config.TreeRespawnTime = 300000
Config.MaxWoodCarry = 20
Config.SellPricePerPlank = 15

Config.TreeLocations = {
    vector3(-530.0, 5370.0, 74.0),
    vector3(-480.0, 5430.0, 78.0),
    vector3(-560.0, 5450.0, 80.0),
    vector3(-620.0, 5390.0, 76.0),
    vector3(-500.0, 5510.0, 82.0),
    vector3(-440.0, 5460.0, 80.0),
    vector3(-580.0, 5310.0, 72.0),
    vector3(-650.0, 5350.0, 74.0),
    vector3(-510.0, 5580.0, 84.0),
    vector3(-460.0, 5310.0, 70.0)
}

Config.WoodTypes = {
    oak = { label = 'Oak Wood', respawnTime = 300000, weight = 1 },
    pine = { label = 'Pine Wood', respawnTime = 240000, weight = 1 },
    maple = { label = 'Maple Wood', respawnTime = 360000, weight = 1 }
}

Config.TreeModels = {
    'prop_tree_f_ci_v_01',
    'prop_tree_f_ficus_05',
    'prop_tree_f_ficus_07',
    'prop_tree_ficus_03',
    'prop_tree_oak_01'
}

Config.SawmillLocation = vector3(-550.0, 5330.0, 73.0)
Config.SawmillHeading = 0.0

Config.SellLocation = vector3(-560.0, 5320.0, 73.0)
Config.SellHeading = 180.0

Config.PlanksItem = 'wood_planks'

Config.DiscordWebhook = ''
