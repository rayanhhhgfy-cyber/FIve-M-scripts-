fx_version 'cerulean'
game 'gta5'
lua54 'yes'
name 'banking-plus'
description 'Advanced banking — transfers, credit, loans, ATMs, investments'
author 'FiveM Scripts'
version '1.0.0'
shared_scripts { '@ox_lib/init.lua', 'config.lua' }
client_scripts { 'client/main.lua' }
server_scripts { 'server/main.lua' }
dependencies { 'ox_lib', 'oxmysql', 'qbx_core', 'Renewed-Banking' }
