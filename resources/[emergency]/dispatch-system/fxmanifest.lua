fx_version 'cerulean'
game 'gta5'
lua54 'yes'
name 'dispatch-system'
description 'Human-driven 911 dispatch — citizens call, dispatchers assign, officers respond'
author 'FiveM Scripts'
version '1.0.0'
ui_page 'web/index.html'
shared_scripts { '@ox_lib/init.lua', 'config.lua' }
client_scripts { 'client/main.lua' }
server_scripts { '@oxmysql/lib/MySQL.lua', 'server/main.lua' }
files { 'web/index.html', 'web/style.css', 'web/script.js' }
dependencies { 'ox_lib', 'oxmysql', 'ox_target', 'qbx_core', 'pma-voice' }
