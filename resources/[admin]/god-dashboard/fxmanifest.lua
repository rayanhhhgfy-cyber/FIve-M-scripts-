fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'god-dashboard'
description 'Unified god admin dashboard — bunkers, objects, doors, vehicles, server, commands'
author 'FiveM Scripts'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/preview.lua',
    'client/bunkers.lua',
    'client/objects.lua',
    'client/doors.lua',
    'client/vehicles.lua',
    'client/commands.lua',
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
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
    'qbx_core',
    'ox_target',
    'bunker-builder',
    'passcode-doors',
    'place-anywhere',
}
