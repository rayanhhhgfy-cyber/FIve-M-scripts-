fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'secret-bunkers'
description 'Underground bunkers with rock-reveal entrance — armory, vehicles, drones'
author 'FiveM Scripts'
version '2.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/script.js',
}

dependencies {
    'ox_lib',
    'oxmysql',
    'ox_target',
    'qbx_core'
}
