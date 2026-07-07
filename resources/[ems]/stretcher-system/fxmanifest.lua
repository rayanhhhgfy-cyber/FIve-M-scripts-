fx_version 'cerulean'
game 'gta5'

name 'stretcher-system'
description 'Deployable EMS stretcher with patient transport, push, and vehicle loading'
author 'Server'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_script 'client/main.lua'

server_script 'server/main.lua'

dependencies {
    'ox_lib',
    'ox_target',
    'qbx_core',
}
