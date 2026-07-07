fx_version 'cerulean'
game 'gta5'
lua54 'yes'
name 'bolo-system'
description 'Be On LookOut — vehicle, person, and warrant BOLOs for police'
author 'FiveM Scripts'
version '1.0.0'
shared_scripts { '@ox_lib/init.lua', 'config.lua' }
client_scripts { 'client/main.lua' }
server_scripts { '@oxmysql/lib/MySQL.lua', 'server/main.lua' }
dependencies { 'ox_lib', 'oxmysql', 'qbx_core' }
