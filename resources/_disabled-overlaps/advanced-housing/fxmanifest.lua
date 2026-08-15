fx_version 'cerulean'
game 'gta5'
lua54 'yes'
name 'advanced-housing'
description 'Full housing system — customization, guest keys, alarms, garage'
author 'FiveM Scripts'
version '1.0.0'
shared_scripts { '@ox_lib/init.lua', 'config.lua' }
client_scripts { 'client/main.lua' }
server_scripts { 'server/main.lua' }
dependencies { 'ox_lib', 'oxmysql', 'qbx_core' }
