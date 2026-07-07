fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'plate-scanner'
description 'Automatic License Plate Recognition System'
author 'FiveM Scripts'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@resources/[shared]/locales/en.lua',
    '@resources/[shared]/locales/ar.lua'
}

client_scripts {
    'config.lua',
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

dependencies {
    'ox_lib'
}
