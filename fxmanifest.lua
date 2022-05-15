fx_version 'adamant'
game 'gta5'

description 'ESX Community Service'
lua54 'yes'
version '1.1.1'

shared_script {'@es_extended/imports.lua', '@ox_lib/init.lua'}

server_scripts {
	'@mysql-async/lib/MySQL.lua',
	'@es_extended/locale.lua',
	'locales/br.lua',
	'locales/en.lua',
	'locales/fr.lua',
	'config.lua',
	'server/main.lua'
}

client_scripts {
	'@es_extended/locale.lua',
	'locales/br.lua',
	'locales/en.lua',
	'locales/fr.lua',
	'config.lua',
	'client/main.lua'
}

dependency 'es_extended'

