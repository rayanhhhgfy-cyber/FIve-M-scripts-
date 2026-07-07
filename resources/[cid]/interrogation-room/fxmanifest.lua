fx_version 'cerulean'
game 'gta5'
lua54 'yes'
name 'interrogation-room'
description 'CID Interrogation Room — record sessions, present evidence, confession system'
author 'FiveM Scripts'
version '1.0.0'
shared_scripts { '@ox_lib/init.lua', 'config.lua' }
client_script 'client/main.lua'
server_script 'server/main.lua'
dependencies { 'ox_lib', 'ox_target', 'qbx_core' }
