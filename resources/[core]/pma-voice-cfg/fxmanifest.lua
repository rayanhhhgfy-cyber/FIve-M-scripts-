fx_version 'cerulean'
game 'gta5'

description 'pma-voice Grid-based 3D Proximity, Radio & Megaphone Configuration'
version '1.0.0'
author 'Elite FiveM Architecture'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

server_scripts {
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}

dependencies {
    'pma-voice',
    'ox_lib'
}

lua54 'yes'
