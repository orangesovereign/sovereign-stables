fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

author 'Sovereign County RP'
name 'sovereign_spikes'
description 'THROWAWAY tech-prep spikes for sovereign_stables (horse appearance + orbital camera). Not for production. Delete after sign-off.'
version '0.0.0'
lua54 'yes'

-- No dependencies on purpose: pure native tests so nothing else can interfere.
client_scripts {
    'shared.lua',
    'appearance.lua',
    'camera.lua',
}
