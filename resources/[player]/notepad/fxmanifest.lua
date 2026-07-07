fx_version 'cerulean'
game 'gta5'

name 'notepad'
description 'In-game notepad for taking notes that save to DB'
author 'Server'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
}

client_script 'client/main.lua'
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

ui_page 'html/index.html'
files {
    'html/index.html',
    'html/style.css',
}

dependencies {
    'ox_lib',
    'qbx_core',
    'ox_inventory',
}
