fx_version 'cerulean'
game 'gta5'
lua54 'yes'
name 'traffic-stop'
description 'Traffic Stop — approach, license check, warnings, tickets'
author 'FiveM Scripts'
version '1.0.0'
shared_scripts { '@ox_lib/init.lua', 'config.lua' }
client_script 'client/main.lua'
server_scripts { 'server/main.lua' }
dependencies { 'ox_lib', 'ox_target', 'qbx_core' }
