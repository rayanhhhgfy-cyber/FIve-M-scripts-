fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'cid-garage'
description 'CID Vehicle Garage — Intercept & Armored Division'
author 'FiveM Scripts'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@resources/[shared]/locales/en.lua',
}

client_scripts {
    'config.lua',
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

dependencies {
    'ox_lib',
    'ox_target'
}
