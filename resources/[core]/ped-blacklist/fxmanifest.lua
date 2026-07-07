fx_version 'cerulean'
game 'gta5'

description 'Ped Blacklist — Server-side Model Interceptor'
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
    'qbx_core'
}

lua54 'yes'
