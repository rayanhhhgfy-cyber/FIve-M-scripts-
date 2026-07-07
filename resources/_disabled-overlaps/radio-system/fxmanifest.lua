fx_version 'cerulean'
game 'gta5'
lua54 'yes'
name 'radio-system'
description 'Radio volume controls, transmit animation, and HUD overlay'
author 'FiveM Scripts'
version '1.0.0'
shared_scripts { '@ox_lib/init.lua', 'config.lua' }
client_scripts { 'client/main.lua' }
server_scripts { 'server/main.lua' }
dependencies { 'pma-voice', 'ox_lib', 'ox_inventory' }
