fx_version 'cerulean'
game 'gta5'

description 'Discord Log System — Comprehensive Webhook Logging'
version '1.0.0'
author 'Elite FiveM Architecture'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/logs.lua'
}

server_scripts {
    'server/main.lua'
}

dependencies {
    'ox_lib',
    'qbx_core'
}

lua54 'yes'
