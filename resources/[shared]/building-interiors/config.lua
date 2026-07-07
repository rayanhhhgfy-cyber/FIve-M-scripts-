Config = Config or {}
Config.BuildingInteriors = Config.BuildingInteriors or {}

Config.BuildingInteriors = {
    maxDistance = 3.0,

    interiors = {
        -- === DEL PERRO / VESPUCCI AREA ===
        {
            id = 'del_perro_apt1',
            label = 'Del Perro Apartment #1',
            entrance = vector3(-1578.0, -570.0, 108.0),
            interior = vector3(-786.0, 315.0, 217.0),
            ipl = 'apa_v_mp_h_01_a',
            headingIn = 180.0,
            headingOut = 0.0,
        },
        {
            id = 'del_perro_apt2',
            label = 'Del Perro Apartment #2',
            entrance = vector3(-1579.0, -575.0, 108.0),
            interior = vector3(-786.0, 315.0, 217.0),
            ipl = 'apa_v_mp_h_01_a',
            headingIn = 180.0,
            headingOut = 0.0,
        },
        -- === MIRROR PARK ===
        {
            id = 'mirror_park_apt1',
            label = 'Mirror Park Apartment #1',
            entrance = vector3(300.0, -1000.0, -100.0),
            interior = vector3(-174.0, 497.0, 137.0),
            ipl = 'apa_v_mp_h_01_a',
            headingIn = 0.0,
            headingOut = 180.0,
        },
        {
            id = 'mirror_park_apt2',
            label = 'Mirror Park Apartment #2',
            entrance = vector3(305.0, -995.0, -100.0),
            interior = vector3(-174.0, 497.0, 137.0),
            ipl = 'apa_v_mp_h_01_a',
            headingIn = 0.0,
            headingOut = 180.0,
        },
        -- === POPULAR STREET ===
        {
            id = 'popular_st_apt',
            label = 'Popular Street Apartment',
            entrance = vector3(-899.0, -440.0, 80.0),
            interior = vector3(-145.0, -485.0, 44.0),
            ipl = 'apa_v_mp_h_01_c',
            headingIn = 0.0,
            headingOut = 180.0,
        },
        -- === PILLBOX HILL ===
        {
            id = 'pillbox_hill_apt',
            label = 'Pillbox Hill Apartment',
            entrance = vector3(-385.0, -135.0, 60.0),
            interior = vector3(-145.0, -485.0, 44.0),
            ipl = 'apa_v_mp_h_01_c',
            headingIn = 180.0,
            headingOut = 0.0,
        },
        -- === TEXTILE CITY ===
        {
            id = 'textile_city_apt',
            label = 'Textile City Apartment',
            entrance = vector3(-670.0, 30.0, 55.0),
            interior = vector3(-145.0, -485.0, 44.0),
            ipl = 'apa_v_mp_h_01_c',
            headingIn = 0.0,
            headingOut = 180.0,
        },
        -- === FAMILY HOUSES ===
        {
            id = 'family_house_1',
            label = 'Family House #1',
            entrance = vector3(-828.0, 180.0, 70.0),
            interior = vector3(10.0, -540.0, 30.0),
            ipl = 'v_fib01',
            headingIn = 0.0,
            headingOut = 180.0,
        },
        {
            id = 'family_house_2',
            label = 'Family House #2',
            entrance = vector3(-835.0, 175.0, 70.0),
            interior = vector3(10.0, -540.0, 30.0),
            ipl = 'v_fib01',
            headingIn = 0.0,
            headingOut = 180.0,
        },
        -- === HAWICK AREA ===
        {
            id = 'hawick_apt1',
            label = 'Hawick Apartment',
            entrance = vector3(-695.0, 330.0, 85.0),
            interior = vector3(-786.0, 315.0, 217.0),
            ipl = 'apa_v_mp_h_01_a',
            headingIn = 180.0,
            headingOut = 0.0,
        },
        -- === MORNINGSIDE ===
        {
            id = 'morningside_house',
            label = 'Morningside House',
            entrance = vector3(-1350.0, -590.0, 30.0),
            interior = vector3(-30.0, -600.0, 30.0),
            ipl = 'v_carshowroom',
            headingIn = 0.0,
            headingOut = 180.0,
        },
        -- === LITTLE SEOUL ===
        {
            id = 'little_seoul_apt',
            label = 'Little Seoul Apartment',
            entrance = vector3(-590.0, -600.0, 35.0),
            interior = vector3(-786.0, 315.0, 217.0),
            ipl = 'apa_v_mp_h_01_a',
            headingIn = 0.0,
            headingOut = 180.0,
        },
        -- === AIRPORT ===
        {
            id = 'airport_hangar',
            label = 'LSIA Hangar',
            entrance = vector3(-1330.0, -3050.0, 14.0),
            interior = vector3(1000.0, -3000.0, -40.0),
            ipl = 'hei_hangar_int',
            headingIn = 0.0,
            headingOut = 180.0,
        },
        -- === PALETO BAY ===
        {
            id = 'paleto_bay_house',
            label = 'Paleto Bay House',
            entrance = vector3(-100.0, 6600.0, 30.0),
            interior = vector3(132.0, -130.0, 58.0),
            ipl = 'hei_sm_16_planning_room',
            headingIn = 180.0,
            headingOut = 0.0,
        },
        -- === SANDY SHORES ===
        {
            id = 'sandy_shores_trailer',
            label = 'Sandy Shores Trailer',
            entrance = vector3(1400.0, 3700.0, 35.0),
            interior = vector3(134.0, -132.0, 58.0),
            ipl = 'sm_15_planning_room_02',
            headingIn = 270.0,
            headingOut = 90.0,
        },
        -- === GRAPESEED ===
        {
            id = 'grapeseed_barn',
            label = 'Grapeseed Barn',
            entrance = vector3(1700.0, 4800.0, 42.0),
            interior = vector3(-140.0, -132.0, 58.0),
            ipl = 'v_abattoir',
            headingIn = 90.0,
            headingOut = 270.0,
        },
        -- === CHUMASH ===
        {
            id = 'chumash_house',
            label = 'Chumash Beach House',
            entrance = vector3(-3200.0, 1050.0, 15.0),
            interior = vector3(128.0, -130.0, 58.0),
            ipl = 'hei_sm_15_planning_room',
            headingIn = 90.0,
            headingOut = 270.0,
        },
        -- === RANCHO ===
        {
            id = 'rancho_apt',
            label = 'Rancho Apartment',
            entrance = vector3(500.0, -1900.0, 26.0),
            interior = vector3(-145.0, -485.0, 44.0),
            ipl = 'apa_v_mp_h_01_c',
            headingIn = 0.0,
            headingOut = 180.0,
        },
        -- === LA MESA ===
        {
            id = 'la_mesa_house',
            label = 'La Mesa House',
            entrance = vector3(850.0, -1850.0, 30.0),
            interior = vector3(10.0, -540.0, 30.0),
            ipl = 'gabz_mrpd',
            headingIn = 0.0,
            headingOut = 180.0,
        },
        -- === EAST VINEWOOD ===
        {
            id = 'east_vinewood_apt',
            label = 'East Vinewood Apartment',
            entrance = vector3(-450.0, 120.0, 70.0),
            interior = vector3(-786.0, 315.0, 217.0),
            ipl = 'apa_v_mp_h_01_a',
            headingIn = 180.0,
            headingOut = 0.0,
        },
        -- === MURRIETA HEIGHTS ===
        {
            id = 'murrieta_heights_house',
            label = 'Murrieta Heights House',
            entrance = vector3(-1150.0, -1600.0, 4.0),
            interior = vector3(-30.0, -600.0, 30.0),
            ipl = 'v_carshowroom',
            headingIn = 0.0,
            headingOut = 180.0,
        },
        -- === VINEWOOD HILLS ===
        {
            id = 'vinewood_hills_mansion',
            label = 'Vinewood Hills Mansion',
            entrance = vector3(-575.0, 550.0, 120.0),
            interior = vector3(-145.0, -485.0, 44.0),
            ipl = 'apa_v_mp_h_01_c',
            headingIn = 0.0,
            headingOut = 180.0,
        },
        -- === RICHMAN ===
        {
            id = 'richman_mansion',
            label = 'Richman Mansion',
            entrance = vector3(-1400.0, 200.0, 100.0),
            interior = vector3(-786.0, 315.0, 217.0),
            ipl = 'apa_v_mp_h_01_a',
            headingIn = 180.0,
            headingOut = 0.0,
        },
        -- === DAVIS ===
        {
            id = 'davis_apt',
            label = 'Davis Apartment',
            entrance = vector3(55.0, -1950.0, 20.0),
            interior = vector3(-145.0, -485.0, 44.0),
            ipl = 'apa_v_mp_h_01_c',
            headingIn = 0.0,
            headingOut = 180.0,
        },
        -- === STRAWBERRY ===
        {
            id = 'strawberry_apt',
            label = 'Strawberry Apartment',
            entrance = vector3(-30.0, -1450.0, 30.0),
            interior = vector3(-145.0, -485.0, 44.0),
            ipl = 'apa_v_mp_h_01_c',
            headingIn = 0.0,
            headingOut = 180.0,
        },
        -- === BURTON ===
        {
            id = 'burton_apt',
            label = 'Burton Apartment',
            entrance = vector3(-350.0, -350.0, 50.0),
            interior = vector3(-786.0, 315.0, 217.0),
            ipl = 'apa_v_mp_h_01_a',
            headingIn = 180.0,
            headingOut = 0.0,
        },
        -- === ROCKFORD HILLS ===
        {
            id = 'rockford_hills_apt',
            label = 'Rockford Hills Apartment',
            entrance = vector3(-900.0, -150.0, 75.0),
            interior = vector3(-786.0, 315.0, 217.0),
            ipl = 'apa_v_mp_h_01_a',
            headingIn = 180.0,
            headingOut = 0.0,
        },
        -- === MISSION ROW ===
        {
            id = 'mission_row_apt',
            label = 'Mission Row Apartment',
            entrance = vector3(235.0, -850.0, 30.0),
            interior = vector3(-145.0, -485.0, 44.0),
            ipl = 'apa_v_mp_h_01_c',
            headingIn = 180.0,
            headingOut = 0.0,
        },
        -- === CYPRESS FLATS ===
        {
            id = 'cypress_flats_apt',
            label = 'Cypress Flats Apartment',
            entrance = vector3(100.0, -2000.0, 20.0),
            interior = vector3(-145.0, -485.0, 44.0),
            ipl = 'apa_v_mp_h_01_c',
            headingIn = 0.0,
            headingOut = 180.0,
        },
        -- === Elysian Island ===
        {
            id = 'elysian_island_warehouse',
            label = 'Elysian Island Warehouse',
            entrance = vector3(370.0, -3000.0, -2.0),
            interior = vector3(-140.0, -132.0, 58.0),
            ipl = 'v_abattoir',
            headingIn = 0.0,
            headingOut = 180.0,
        },
    },
}
