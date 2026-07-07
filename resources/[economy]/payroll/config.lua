Config = Config or {}
Config.Payroll = Config.Payroll or {}

Config.Payroll = {
    GameDayInterval = 25,

    Jobs = {
        ['police'] = {
            { grade = 0, label = 'Cadet', salary = 800 },
            { grade = 1, label = 'Officer', salary = 1000 },
            { grade = 2, label = 'Sergeant', salary = 1200 },
            { grade = 3, label = 'Lieutenant', salary = 1400 },
            { grade = 4, label = 'Chief', salary = 1700 },
        },
        ['cid'] = {
            { grade = 0, label = 'Agent Trainee', salary = 1200 },
            { grade = 1, label = 'Agent', salary = 1400 },
            { grade = 2, label = 'Senior Agent', salary = 1600 },
            { grade = 3, label = 'Supervisor', salary = 1900 },
            { grade = 4, label = 'Director', salary = 2200 },
        },
        ['ambulance'] = {
            { grade = 0, label = 'Probationary EMT', salary = 700 },
            { grade = 1, label = 'EMT', salary = 900 },
            { grade = 2, label = 'Paramedic', salary = 1100 },
            { grade = 3, label = 'Chief', salary = 1300 },
        },
    },
}
