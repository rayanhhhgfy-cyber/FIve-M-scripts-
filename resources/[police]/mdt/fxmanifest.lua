fx_version 'cerulean'
game 'gta5'
lua54 'yes'
name 'mdt'
description 'Mobile Data Terminal — in-vehicle computer for plates, warrants, reports'
author 'FiveM Scripts'
version '1.0.0'
shared_scripts { '@ox_lib/init.lua', 'config.lua' }
client_script 'client/main.lua'
server_scripts { 'server/main.lua' }
dependencies { 'ox_lib', 'qbx_core' }
