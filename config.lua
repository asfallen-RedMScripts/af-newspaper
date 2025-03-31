Config = {}


Config.Debug = false 

function DebugPrint(message)
    if Config.Debug then
        print("[DEBUG] " .. message)
    end
end