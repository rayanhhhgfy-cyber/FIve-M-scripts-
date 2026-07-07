fx_version 'cerulean'; game 'gta5'; lua54 'yes'
name 'immersion-polish'; description 'Social Immersion, Physics Carry & Global Polish Systems'
author 'FiveM Scripts'; version '1.0.0'
shared_scripts { '@ox_lib/init.lua', '@resources/[shared]/locales/en.lua', 'config.lua' }
client_scripts { 'client/main.lua' }
server_scripts { '@oxmysql/lib/MySQL.lua', 'server/main.lua' }
dependencies { 'ox_lib', 'oxmysql', 'qbx_core', 'ox_inventory' }
