fx_version 'cerulean'
game 'gta5'
lua54 'yes'
name 'taxi-system'
description 'Taxi & ride-sharing — NPC dispatch, iPhone app integration, driving quality tips'
author 'FiveM Scripts'
version '2.0.0'
shared_scripts { '@ox_lib/init.lua', 'config.lua' }
client_scripts { 'client/main.lua' }
server_scripts { 'server/main.lua' }
dependencies { 'ox_lib', 'oxmysql', 'qbx_core', 'iphone' }
