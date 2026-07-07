fx_version 'cerulean'
game 'gta5'

description 'InteractSound — Server-authoritative Context Sound Player'
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
    'ox_lib'
}

lua54 'yes'
