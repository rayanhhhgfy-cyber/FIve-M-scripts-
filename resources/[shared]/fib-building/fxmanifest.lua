fx_version 'cerulean'
game 'gta5'
lua54 'yes'
name 'fib-building'
description 'FIB Building — entrance, elevator, computer terminals'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx-core/shared/locale.lua',
    'config.lua'
}

server_scripts {
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}

ui_page 'html/elevator.html'

files {
    'html/elevator.html',
    'html/elevator.css',
    'html/elevator.js',
    'html/computer.html',
    'html/computer.css',
    'html/computer.js',
}

dependencies {
    'ox_lib',
    'qbx-core',
    'ox_target',
}
