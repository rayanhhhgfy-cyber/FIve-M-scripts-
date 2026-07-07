Config = Config or {}

Config.MedicalBag = {
    itemName = 'medical_bag',
    slots = 20,
    weight = 20000,
    bagModel = 'prop_med_bag_01',
    deployTime = 2000,
    pickupTime = 1500,
    despawnTime = 300000,
    maxBags = 3,
    jobRestricted = true,
    jobName = 'ambulance'
}

Config.MedicalItems = {
    bandage = { label = 'Bandage', weight = 100 },
    medic_kit = { label = 'Medical Kit', weight = 500 },
    painkillers = { label = 'Painkillers', weight = 50 },
    morphine = { label = 'Morphine', weight = 50 },
    epinephrine = { label = 'Epinephrine', weight = 50 },
    iv_bag = { label = 'IV Bag', weight = 200 },
    defibrillator = { label = 'Defibrillator', weight = 1000 },
    suture_kit = { label = 'Suture Kit', weight = 300 },
    tourniquet = { label = 'Tourniquet', weight = 100 },
    antiseptic = { label = 'Antiseptic', weight = 150 },
    surgical_gloves = { label = 'Surgical Gloves', weight = 50 },
    scalpel = { label = 'Scalpel', weight = 100 }
}
