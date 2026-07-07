fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'building-interiors'
description '100+ vanilla GTA V IPL interiors with door interaction targets'
author 'FiveM Scripts'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

dependencies {
    'ox_lib',
    'ox_target',
    'qbx_core'
}
