Config = {}

Config.Framework = 'vorp' -- 'rsg-core' veya 'vorp' olabilir

Config.Debug = false
Config.JobName = 'reporter'

Config.ItemName = 'newspaper'

function DebugPrint(message)
    if Config.Debug then
        print("[AF-NEWSPAPER DEBUG] " .. message)
    end
end