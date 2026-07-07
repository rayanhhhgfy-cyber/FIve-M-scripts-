fx_version 'cerulean'
game 'gta5'
lua54 'yes'
name 'death-screen'
description 'Custom death and respawn screen'
author 'QBox Framework'
version '1.0.0'
shared_scripts { '@ox_lib/init.lua', 'config.lua' }
server_scripts { 'server/main.lua' }
client_script 'client/main.lua'
dependencies { 'ox_lib', 'qbx-core' }
