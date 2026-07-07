Emotes = Emotes or {}

Emotes.List = {
    ['drink'] = { label = 'Drink', dict = 'amb@world_human_drinking@beer@male@idle_a', clip = 'idle_a', prop = 'prop_amb_beer_bottle', propBone = 28422 },
    ['smoke'] = { label = 'Smoke', dict = 'amb@world_human_smoking@male@male_d_a', clip = 'male_d_a', prop = 'prop_amb_ciggy_01', propBone = 28422 },
    ['cigar'] = { label = 'Cigar', dict = 'amb@world_human_smoking@male@male_d_a', clip = 'male_b', prop = 'prop_cigar_01', propBone = 28422 },
    ['phone'] = { label = 'Phone', dict = 'cellphone@str@@str_walk', clip = 'cellphone_call_listen_base', prop = 'prop_npc_phone_02', propBone = 28422 },
    ['sitting'] = { label = 'Sit', dict = 'amb@prop_human_seat_chair@male@idle_d', clip = 'idle_d', flag = 1 },
    ['leaning'] = { label = 'Lean', dict = 'amb@world_human_lean_male_foot_up@idle_a', clip = 'idle_a' },
    ['crossarms'] = { label = 'Cross Arms', dict = 'amb@world_human_cross_arm@idle_a', clip = 'idle_a' },
    ['surrender'] = { label = 'Surrender', dict = 'mp_arresting', clip = 'idle', flag = 1 },
    ['handsup'] = { label = 'Hands Up', dict = 'mp_arresting', clip = 'idle', flag = 1 },
    ['kneel'] = { label = 'Kneel', dict = 'amb@medic@standing@timeofdeath@idle_a', clip = 'idle_a', flag = 1 },
    ['pushup'] = { label = 'Push-Up', dict = 'amb@world_human_push_ups@male@idle_a', clip = 'idle_a', flag = 1 },
    ['situp'] = { label = 'Sit-Up', dict = 'amb@world_human_sit_ups@male@idle_a', clip = 'idle_a', flag = 1 },
    ['yoga'] = { label = 'Yoga', dict = 'amb@world_human_yoga@male@base', clip = 'base_a', flag = 1 },
    ['meditate'] = { label = 'Meditate', dict = 'amb@world_human_meditation@male@base', clip = 'base', flag = 1 },
    ['dance'] = { label = 'Dance', dict = 'anim@amb@nightclub@dancers@solomun_entries@', clip = 'mi_dance_crowd_02_ld' },
    ['dance2'] = { label = 'Dance 2', dict = 'anim@amb@nightclub@dancers@solomun_entries@', clip = 'mi_dance_crowd_03_ld' },
    ['dance3'] = { label = 'Dance 3', dict = 'anim@amb@nightclub@dancers@solomun_entries@', clip = 'mi_dance_crowd_04_ld' },
    ['dj'] = { label = 'DJ', dict = 'anim@amb@nightclub@djs@dixon@', clip = 'dixon_dance_a', prop = 'prop_v_bmike_01', propBone = 28422 },
    ['airguitar'] = { label = 'Air Guitar', dict = 'anim@mp_air_guitar', clip = 'idle_a' },
    ['airplane'] = { label = 'Airplane', dict = 'anim@mp_airplane', clip = 'idle_a' },
    ['flex'] = { label = 'Flex', dict = 'amb@world_human_muscle_free_weights@male@bicep_curl_a', clip = 'bicep_curl_a' },
    ['selfie'] = { label = 'Selfie', dict = 'cellphone@selfie@str', clip = 'cellphone_selfie_idle_a', prop = 'prop_npc_phone_02', propBone = 60390 },
    ['book'] = { label = 'Read', dict = 'amb@world_human_seat_reading@female_a@idle_a', clip = 'idle_a', prop = 'prop_novel_01', propBone = 28422 },
    ['binoculars'] = { label = 'Binoculars', dict = 'amb@world_human_binoculars@male@idle_a', clip = 'idle_a', prop = 'prop_binoc_01', propBone = 28422 },
    ['camera'] = { label = 'Camera', dict = 'amb@world_human_paparazzi@male@idle_a', clip = 'idle_a', prop = 'prop_papr_01', propBone = 28422 },
    ['fishing'] = { label = 'Fishing', dict = 'amb@world_human_fishing@male@idle_a', clip = 'idle_a', prop = 'prop_fishing_rod_01', propBone = 60390 },
    ['gardening'] = { label = 'Gardening', dict = 'amb@world_human_gardener_plant@male@idle_a', clip = 'idle_a', prop = 'prop_plant_01', propBone = 28422 },
    ['cleaning'] = { label = 'Clean', dict = 'amb@world_human_janitor@male@idle_a', clip = 'idle_a', prop = 'prop_mop_01', propBone = 28422 },
    ['weld'] = { label = 'Weld', dict = 'amb@world_human_welding@male@idle_a', clip = 'idle_a', prop = 'prop_weld_torch', propBone = 28422 }
}

Emotes.WalkingStyles = {
    ['default'] = { label = 'Default', style = nil },
    ['brave'] = { label = 'Brave', style = 'move_m@brave' },
    ['confident'] = { label = 'Confident', style = 'move_m@confident' },
    ['business'] = { label = 'Business', style = 'move_m@business@a' },
    ['casual'] = { label = 'Casual', style = 'move_m@casual@a' },
    ['drunk'] = { label = 'Drunk', style = 'move_m@drunk@verydrunk' },
    ['fat'] = { label = 'Fat', style = 'move_m@fat@a' },
    ['gangster'] = { label = 'Gangster', style = 'move_m@gangster@generic' },
    ['hurry'] = { label = 'Hurry', style = 'move_m@hurry@a' },
    ['injured'] = { label = 'Injured', style = 'move_m@injured' },
    ['quick'] = { label = 'Quick', style = 'move_m@quick' },
    ['sad'] = { label = 'Sad', style = 'move_m@sad@a' },
    ['tough'] = { label = 'Tough', style = 'move_m@tough_guy@a' },
    ['scared'] = { label = 'Scared', style = 'move_m@scared' },
    ['swagger'] = { label = 'Swagger', style = 'move_m@swagger' },
    ['woman'] = { label = 'Feminine', style = 'move_f@feminine@a' },
    ['maneater'] = { label = 'Man Eater', style = 'move_f@maneater' },
    ['chichi'] = { label = 'Chi Chi', style = 'move_f@chichi' },
    ['heels'] = { label = 'Heels', style = 'move_f@heels@c' },
    ['proud'] = { label = 'Proud', style = 'move_f@proud' }
}

Emotes.Shared = {
    ['hug'] = {
        label = 'Hug',
        dict = 'anim@mp_player_intcelebrationmale@hug',
        clip = 'hug',
        targetDict = 'anim@mp_player_intcelebrationpaired@hug',
        targetClip = 'hug'
    },
    ['handshake'] = {
        label = 'Handshake',
        dict = 'mp_ped_interaction',
        clip = 'handshake_guy_a',
        targetDict = 'mp_ped_interaction',
        targetClip = 'handshake_guy_b'
    },
    ['highfive'] = {
        label = 'High Five',
        dict = 'mp_ped_interaction',
        clip = 'highfive_guy_a',
        targetDict = 'mp_ped_interaction',
        targetClip = 'highfive_guy_b'
    }
}
