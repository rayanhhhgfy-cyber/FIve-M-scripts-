fx_version 'cerulean'
game 'gta5'

author 'Economy Systems'
description 'ATM Card — require mastercard to use ATMs with NUI banking menu'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/script.js',
    'web/style.css',
}

dependencies {
    'ox_lib',
    'qbx_core',
    'ox_target',
    'Renewed-Banking',
}
