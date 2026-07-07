Config = Config or {}

Config.Fines = {
    RequireDuty = true,
    MinRank = 0,
    AllowedJobs = { 'police', 'sheriff', 'statepolice' },
    PaymentTime = 5000,
    Cooldown = 3000,

    FinesCategories = {
        Traffic = {
            label = 'Traffic Violations',
            fines = {
                { id = 'speeding_10', label = 'Speeding (1-10 over)', amount = 150 },
                { id = 'speeding_20', label = 'Speeding (11-20 over)', amount = 300 },
                { id = 'speeding_30', label = 'Speeding (21-30 over)', amount = 500 },
                { id = 'speeding_40', label = 'Speeding (31+ over)', amount = 800 },
                { id = 'reckless', label = 'Reckless Driving', amount = 1000 },
                { id = 'running_red', label = 'Running Red Light', amount = 250 },
                { id = 'illegal_u_turn', label = 'Illegal U-Turn', amount = 200 },
                { id = 'wrong_way', label = 'Wrong Way', amount = 350 },
                { id = 'no_seatbelt', label = 'No Seatbelt', amount = 100 },
                { id = 'using_phone', label = 'Using Phone While Driving', amount = 200 },
                { id = 'illegal_parking', label = 'Illegal Parking', amount = 100 },
                { id = 'blocking_intersection', label = 'Blocking Intersection', amount = 150 },
                { id = 'following_too_close', label = 'Following Too Close', amount = 250 },
                { id = 'illegal_pass', label = 'Illegal Passing', amount = 300 },
                { id = 'no_headlights', label = 'No Headlights (Night)', amount = 100 },
                { id = 'expired_registration', label = 'Expired Registration', amount = 200 }
            }
        },
        Vehicle = {
            label = 'Vehicle Violations',
            fines = {
                { id = 'no_license', label = 'No Driver License', amount = 500 },
                { id = 'expired_license', label = 'Expired License', amount = 250 },
                { id = 'no_insurance', label = 'No Insurance', amount = 600 },
                { id = 'stolen_vehicle', label = 'Driving Stolen Vehicle', amount = 2000 },
                { id = 'altered_plates', label = 'Altered Plates', amount = 1000 },
                { id = 'modified_exhaust', label = 'Illegal Exhaust', amount = 300 },
                { id = 'tinted_windows', label = 'Illegal Tint', amount = 200 },
                { id = 'unsafe_vehicle', label = 'Unsafe Vehicle', amount = 250 }
            }
        },
        Public = {
            label = 'Public Order',
            fines = {
                { id = 'disturbance', label = 'Public Disturbance', amount = 200 },
                { id = 'public_intox', label = 'Public Intoxication', amount = 300 },
                { id = 'loitering', label = 'Loitering', amount = 100 },
                { id = 'trespassing', label = 'Trespassing', amount = 400 },
                { id = 'vandalism', label = 'Vandalism', amount = 500 },
                { id = 'littering', label = 'Littering', amount = 100 },
                { id = 'public_urination', label = 'Public Urination', amount = 250 },
                { id = 'open_container', label = 'Open Container (Public)', amount = 150 },
                { id = 'disorderly', label = 'Disorderly Conduct', amount = 350 },
                { id = 'resisting_arrest', label = 'Resisting Arrest', amount = 750 }
            }
        },
        Criminal = {
            label = 'Criminal Offenses',
            fines = {
                { id = 'possession_weed', label = 'Possession of Marijuana', amount = 500 },
                { id = 'possession_cocaine', label = 'Possession of Cocaine', amount = 1500 },
                { id = 'possession_weapon', label = 'Concealed Weapon', amount = 1000 },
                { id = 'brandishing', label = 'Brandishing Weapon', amount = 750 },
                { id = 'assault', label = 'Assault', amount = 2000 },
                { id = 'battery', label = 'Battery', amount = 2500 },
                { id = 'theft', label = 'Petty Theft', amount = 1500 },
                { id = 'bribery', label = 'Attempted Bribery', amount = 3000 }
            }
        }
    },

    TargetOptions = {
        icon = 'fas fa-file-invoice-dollar',
        label = 'Issue Fine',
        group = 'police',
        distance = 2.5
    }
}
