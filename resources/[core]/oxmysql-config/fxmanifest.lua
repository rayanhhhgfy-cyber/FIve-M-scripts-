fx_version 'cerulean'
game 'gta5'

description 'oxmysql Core Configuration & Pool Indexing'
version '1.0.0'
author 'Elite FiveM Architecture'

shared_scripts {
    '@ox_lib/init.lua'
}

server_scripts {
    'config.lua',
    'server/main.lua'
}

dependencies {
    'oxmysql',
    'ox_lib',
    'database'
}

lua54 'yes'
