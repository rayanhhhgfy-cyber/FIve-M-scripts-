fx_version 'cerulean'; game 'gta5'; lua54 'yes'
name 'legal-system'; description 'Legal, Judicial & Political Systems (10 subsystems)'
author 'FiveM Scripts'; version '1.0.0'
shared_scripts { '@ox_lib/init.lua', '@resources/[shared]/locales/en.lua', 'config.lua' }
client_scripts { 'client/main.lua' }
server_scripts { '@oxmysql/lib/MySQL.lua', 'server/main.lua' }
dependencies { 'ox_lib', 'oxmysql', 'qbx_core', 'Renewed-Banking' }
