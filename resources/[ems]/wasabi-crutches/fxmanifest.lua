fx_version 'cerulean'
game 'gta5'

description 'wasabi_crutches — Immobilization System with Custom Walking'
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
    'ox_inventory',
    'ox_target'
}

lua54 'yes'
