fx_version 'cerulean'
game 'gta5'

description 'dpEmotes / rp-emotes — Animation Library with Props & Walking Styles'
version '1.0.0'
author 'Elite FiveM Architecture'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/emotes.lua'
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
