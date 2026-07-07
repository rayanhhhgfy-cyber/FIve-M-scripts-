fx_version 'cerulean'
game 'gta5'

description 'txAdmin Integration & Hooks - Server Command & Control'
version '1.0.0'
author 'Elite FiveM Architecture'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/init.lua',
    '../../[shared]/locales/en.lua'
}

server_scripts {
    'config.lua',
    'server/main.lua'
}

client_scripts {
    'config.lua',
    'client/main.lua'
}

dependencies {
    'ox_lib',
    'qbx_core',
    'oxmysql'
}

lua54 'yes'
