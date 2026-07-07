fx_version 'cerulean'
game 'gta5'

description 'Entity Cleaner — Algorithmic Abandoned Entity Deletion'
version '1.0.0'
author 'Elite FiveM Architecture'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

server_scripts {
    'server/main.lua'
}

dependencies {
    'ox_lib'
}

lua54 'yes'
