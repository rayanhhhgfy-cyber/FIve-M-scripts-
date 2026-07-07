fx_version 'cerulean'
game 'gta5'
this_is_a_map 'yes'
author 'Fiv3Devs'
description 'Pillbox Hospital'
version '1.2.6'
lua54 'yes'

files {
    '5d_timecycle_mods_1.xml',
    'audio/*.dat151.rel',
}

data_file 'TIMECYCLEMOD_FILE' '5d_timecycle_mods_1.xml'
data_file 'AUDIO_GAMEDATA' 'audio/5d_hospital_shell_game.dat'

client_script 'ipl.lua'

dependencies {
    'fiv3devs_mapdata'
}
