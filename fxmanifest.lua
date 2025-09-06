fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

lua54 'yes'

ui_page 'nui/index.html'

author 'afoolasfallen'
description 'Af Newspaper  (RSG-Core & VORP)'
version '2.0'

shared_scripts {
    'config.lua',
    'framework.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}

files {
    'nui/old-paper-texture.png',
    'nui/newspaper.png',
    'nui/index.html',
    'nui/style.css',
    'nui/script.js',
}