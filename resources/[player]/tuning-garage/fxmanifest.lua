fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'tuning-garage'
description 'Full vehicle tuning — visual mods, performance, colors, neon'
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
    'qbx_core',
    'Renewed-Banking'
}
