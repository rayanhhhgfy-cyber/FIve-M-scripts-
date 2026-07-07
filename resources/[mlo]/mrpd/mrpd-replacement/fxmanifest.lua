fx_version 'cerulean'
game 'gta5'
version '1.0.0'
lua54 'yes'
author 'NTeam'
description 'NTeam MRPD Replacement'
this_is_a_map 'yes'

files {
    'nteam_mrpd_game.dat151.rel',
    'data/gtxd.meta',
    'nteam_mrpd_mix.dat15.rel'
}

data_file 'AUDIO_GAMEDATA' 'nteam_mrpd_game.dat'
data_file 'AUDIO_DYNAMIXDATA' 'nteam_mrpd_mix.dat'
data_file 'GTXD_PARENTING_DATA' 'data/gtxd.meta'

escrow_ignore {
    'stream/UN/**'
}

dependency '/assetpacks'
