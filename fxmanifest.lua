fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

lua54 'yes'

ui_page 'nui/index.html'

author 'afoolasfallen'
description 'OutWest Newspaper System'
version '1.0'


client_scripts {
    'client.lua',
    'config.lua'
}

server_scripts {
    'server.lua',
    'config.lua'
}
files {

    'nui/old-paper-texture.png',
    'nui/newspaper.png',
    'nui/index.html',
    'nui/style.css',
    'nui/script.js',
}
