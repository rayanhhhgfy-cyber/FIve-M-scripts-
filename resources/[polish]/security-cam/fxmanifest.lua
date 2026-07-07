fx_version 'cerulean'
game 'gta5'
lua54 'yes'
name 'security-cam'
description 'Security camera network system'
author 'QBox Framework'
version '1.0.0'
shared_scripts { '@ox_lib/init.lua', '@qbx-core/shared/locale.lua', 'config.lua' }
server_scripts { 'server/main.lua' }
client_script 'client/main.lua'
dependencies { 'ox_lib', 'qbx-core', 'ox_target' }
