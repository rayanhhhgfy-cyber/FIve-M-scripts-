fx_version 'cerulean'
game 'gta5'
lua54 'yes'
name 'character-system'
description 'Multi-character selection, creation, and spawn location picker'
author 'FiveM Scripts'
version '1.0.0'
shared_scripts { '@ox_lib/init.lua', 'config.lua' }
client_scripts { 'client/main.lua' }
server_scripts { 'server/main.lua' }
ui_page 'client/html/index.html'
files {
    'client/html/index.html',
    'client/html/style.css',
    'client/html/script.js',
}
dependencies { 'ox_lib', 'oxmysql', 'qbx_core', 'ox_inventory' }
