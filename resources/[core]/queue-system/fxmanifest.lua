fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'queue-system'
description 'Player queue with priority slots and admin pull command'
author 'FiveM Scripts'
version '1.0.0'

server_scripts {
    'config.lua',
    'server/main.lua'
}

dependencies {
    'ox_lib',
    'qbx_core'
}
