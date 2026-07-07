--[[
    Resource : fiv3devs_pillbox
    Author   : FiveVault
    Notice   : Dumped And Fixed By FiveVault
    Created  : 2026-06-05
    Website  : https://fivevault.net
    Discord  : discord.gg/fivevault
]]

fx_version 'cerulean'
game 'gta5'
this_is_a_map 'yes'
author 'Fiv3Devs'
description 'Pillbox Hospital'
version '1.2.6'
lua54 'yes'

ui_page 'script/nui/ascensore.html'

files {
	'5d_timecycle_mods_1.xml',
	'audio/*.dat151.rel',
	'stream/5d_pillbox_mri.ycd',
	'stream/5d_pillbox_xray.ycd',
	'script/nui/ascensore.html',
	'script/nui/ascensore.js',
	'script/nui/ascensore.css',
	'script/nui/ascensore.mp3'
}

client_script {
	'ipl.lua',
	'script/config.lua',
	'script/client-side/main.lua'
}

server_script 'script/server-side/server.lua'

data_file 'TIMECYCLEMOD_FILE' '5d_timecycle_mods_1.xml'
data_file 'AUDIO_GAMEDATA' 'audio/5d_hospital_shell_game.dat'


dependencies {
	'fiv3devs_mapdata'
}
