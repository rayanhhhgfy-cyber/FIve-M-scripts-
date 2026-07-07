Config = Config or {}
Config.BunkerBuilder = Config.BunkerBuilder or {}

Config.BunkerBuilder = {
    adminGroups = { 'admin', 'superadmin', 'god' },

    rockPresets = {
        small = {
            label = 'Small Entrance',
            rocks = {
                { model = 'prop_rock_4_b', offset = vector3(-1.5, -1.0, -0.5), heading = 0.0, slideDir = vector3(-3.0, 0.0, 0.0) },
                { model = 'prop_rock_4_c', offset = vector3(1.5, 1.0, -0.5), heading = 45.0, slideDir = vector3(3.0, 0.0, 0.0) },
            }
        },
        medium = {
            label = 'Medium Entrance',
            rocks = {
                { model = 'prop_rock_4_b', offset = vector3(-2.5, -1.0, -0.5), heading = 0.0, slideDir = vector3(-4.0, 0.0, 0.0) },
                { model = 'prop_rock_4_c', offset = vector3(2.5, 1.0, -0.5), heading = 45.0, slideDir = vector3(4.0, 0.0, 0.0) },
                { model = 'prop_rock_3_b', offset = vector3(0.0, -2.0, -1.0), heading = 90.0, slideDir = vector3(0.0, -4.0, 0.0) },
            }
        },
        large = {
            label = 'Large Entrance',
            rocks = {
                { model = 'prop_rock_4_b', offset = vector3(-3.0, -1.5, -0.5), heading = 0.0, slideDir = vector3(-5.0, 0.0, 0.0) },
                { model = 'prop_rock_4_c', offset = vector3(3.0, 1.5, -0.5), heading = 45.0, slideDir = vector3(5.0, 0.0, 0.0) },
                { model = 'prop_rock_3_b', offset = vector3(0.0, -2.5, -1.0), heading = 90.0, slideDir = vector3(0.0, -5.0, 0.0) },
                { model = 'hei_heist_stn_rock_col_d', offset = vector3(-1.0, 2.0, -1.0), heading = 0.0, slideDir = vector3(0.0, 4.0, 0.0) },
            }
        },
    },

    interiors = {
        { name = 'hei_sm_15_planning_room', label = 'Planning Room 1' },
        { name = 'hei_sm_16_planning_room', label = 'Planning Room 2' },
        { name = 'sm_15_planning_room_02', label = 'Planning Room 3' },
        { name = 'gr_case13_bunker', label = 'Case 13 Bunker' },
        { name = 'v_abattoir', label = 'Abattoir Basement' },
        { name = 'hei_hangar_int', label = 'Hangar Interior' },
        { name = 'donmario_illegal_underground', label = 'DonMario Illegal Bunker' },
    },

    interiorTypes = {
        { name = 'bunker_meth_lab', label = 'Meth Lab Bunker' },
        { name = 'bunker_standard', label = 'Standard Bunker' },
    },

    maxPerAdmin = 10,

    defaultPasscode = '2193',
}
