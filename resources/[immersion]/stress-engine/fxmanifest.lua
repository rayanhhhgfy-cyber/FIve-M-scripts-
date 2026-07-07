fx_version 'cerulean'
game 'gta5'

description 'Stress Management Engine — Screen Shake, Aim Jitter & Relaxation'
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
    'player-status'
}

lua54 'yes'
