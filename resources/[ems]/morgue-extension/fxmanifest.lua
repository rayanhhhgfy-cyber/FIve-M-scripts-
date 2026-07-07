fx_version 'cerulean'
game 'gta5'

description 'Morgue Interior Extension — Cold Storage & Autopsy Array'
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
    'ox_target',
    'ox_inventory',
    'ps-mdt'
}

lua54 'yes'
