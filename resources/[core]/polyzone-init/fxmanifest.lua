fx_version 'cerulean'
game 'gta5'

description 'PolyZone Core Spatial Calculation Module'
version '1.0.0'
author 'Elite FiveM Architecture'

shared_scripts {
    '@ox_lib/init.lua',
    '@polyzone/lib.lua',
    'config.lua'
}

server_scripts {
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}

dependencies {
    'polyzone',
    'ox_lib'
}

lua54 'yes'
