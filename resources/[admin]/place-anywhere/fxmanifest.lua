fx_version 'cerulean'
game 'gta5'
lua54 'yes'
name 'place-anywhere'
description 'God admin object placement tool'
author 'FiveM Scripts'
version '1.0.0'
shared_scripts { '@ox_lib/init.lua', 'config.lua' }
client_scripts { 'client/main.lua' }
server_scripts { '@oxmysql/lib/MySQL.lua', 'server/main.lua' }
dependencies { 'ox_lib', 'oxmysql', 'qbx_core', 'ox_target' }
