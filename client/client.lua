local waitingForStories = false
local waitingForAllStories = false

-- Gazete açma işlemi
RegisterNetEvent('af-newspaper:client:openNewspaper', function(newspaperId, isReporter)
    if not newspaperId then
        Framework:Notify('Gazete', 'Gazete geçersiz veya bozuk.', 'error')
        return
    end

    DebugPrint("Gazete açılmaya çalışılıyor. NewspaperId: " .. newspaperId)

    if Config.Framework == 'rsg-core' then
        local Player = Framework:GetPlayerData()
        local isReporter = Player.job and Player.job.name == Config.JobName
        
        Framework:TriggerCallback('af-newspaper:server:getStories', function(news)
            if not news or #news == 0 then
                Framework:Notify('Gazete', 'Gazete verisi bulunamadı.', 'error')
                return
            end

            DebugPrint("Gazete açıldı. Gösterilen Versiyon: " .. news[1].version)

            SetNuiFocus(true, true)
            SendNUIMessage({
                action = 'openNewspaper',
                stories = news,
                isReporter = isReporter,
                version = news[1].version,
                framework = Config.Framework
            })
        end, newspaperId)
    elseif Config.Framework == 'vorp' then
        waitingForStories = true
        TriggerServerEvent('af-newspaper:server:getStories', newspaperId)
    end
end)

-- VORP için event handler'lar
if Config.Framework == 'vorp' then
    RegisterNetEvent('af-newspaper:client:receiveStories', function(news, isReporter)
        if not waitingForStories then return end
        waitingForStories = false

        if not news or #news == 0 then
            Framework:Notify('Gazete', 'Gazete verisi bulunamadı.', 'error')
            return
        end

        DebugPrint("Gazete açıldı. Gösterilen Versiyon: " .. news[1].version)

        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'openNewspaper',
            stories = news,
            isReporter = isReporter,
            version = news[1].version,
            framework = Config.Framework
        })
    end)

    RegisterNetEvent('af-newspaper:client:receiveAllStories', function(stories)
        if not waitingForAllStories then return end
        waitingForAllStories = false
        
        SendNUIMessage({
            action = 'receiveAllStories',
            stories = stories
        })
    end)
end

-- NUI Callbacks
RegisterNUICallback('closeNewspaper', function(_, cb)
    SetNuiFocus(false, false)
    cb({})
end)

RegisterNUICallback('requestCloseNUI', function(_, cb)
    SetNuiFocus(false, false)
    cb({})
end)

RegisterNUICallback('publishStory', function(data, cb)
    TriggerServerEvent('af-newspaper:server:publishStory', data)
    cb({})
end)

RegisterNUICallback('getAllStories', function(_, cb)
    if Config.Framework == 'rsg-core' then
        Framework:TriggerCallback('af-newspaper:server:getAllStories', function(stories)
            cb(stories)
        end)
    elseif Config.Framework == 'vorp' then
        waitingForAllStories = true
        TriggerServerEvent('af-newspaper:server:getAllStories')
        cb({}) -- VORP event bazlı, sonuç event ile gelecek
    end
end)

RegisterNUICallback('openVersion', function(data, cb)
    if Config.Framework == 'vorp' then
        -- VORP için server'dan job kontrolü yapılacak
        TriggerServerEvent('af-newspaper:server:openVersion', data.newspaperId)
    else
        TriggerEvent('af-newspaper:client:openNewspaper', data.newspaperId)
    end
    cb({})
end)

RegisterNetEvent('af-newspaper:client:toggleReporterPanel', function(isReporter)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'toggleReporterPanel',
        isReporter = isReporter,
        framework = Config.Framework
    })
end)

RegisterNUICallback('copyNewspaper', function(data, cb)
    TriggerServerEvent('af-newspaper:server:copyNewspaper', data)
    cb({})
end)