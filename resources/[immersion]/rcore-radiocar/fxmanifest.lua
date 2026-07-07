fx_version 'cerulean'
game 'gta5'

description 'rcore_radiocar — Spatialized 3D Vehicle Stereos'
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
    'ox_lib',
    'qbx_core',
    'ox_target'
}

lua54 'yes'
