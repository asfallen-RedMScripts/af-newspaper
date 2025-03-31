local RSGCore = exports['rsg-core']:GetCoreObject()

-- Gazete açma işlemi
RegisterNetEvent('af-newspaper:client:openNewspaper', function(newspaperId)
    local Player = RSGCore.Functions.GetPlayerData()
    local isReporter = Player.job.name == 'reporter'

    if not newspaperId then
        TriggerEvent('ox_lib:notify', {
            title = 'Gazete',
            description = 'Gazete geçersiz veya bozuk.',
            type = 'error'
        })
        return
    end

    -- Debug: Hangi newspaperId ile gazete açılmaya çalışılıyor
    DebugPrint("Gazete açılmaya çalışılıyor. NewspaperId: " .. newspaperId)

    RSGCore.Functions.TriggerCallback('af-newspaper:server:getStories', function(news)
        if not news or #news == 0 then
            TriggerEvent('ox_lib:notify', {
                title = 'Gazete',
                description = 'Gazete verisi bulunamadı.',
                type = 'error'
            })
            return
        end

        -- Debug: Hangi versiyonun gösterildiğini kontrol et
        DebugPrint("Gazete açıldı. Gösterilen Versiyon: " .. news[1].version)

        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'openNewspaper',
            stories = news,
            isReporter = isReporter,
            version = news[1].version
        })
    end, newspaperId)
end)

-- NUI'yi kapatma isteği
RegisterNUICallback('closeNewspaper', function(_, cb)
    SetNuiFocus(false, false)
    cb({})
    TriggerEvent('af-newspaper:client:closeNewspaper')
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
    RSGCore.Functions.TriggerCallback('af-newspaper:server:getAllStories', function(stories)
        cb(stories)
    end)
end)

RegisterNUICallback('openVersion', function(data, cb)
    TriggerEvent('af-newspaper:client:openNewspaper', data.newspaperId)
    cb({})
end)

RegisterNetEvent('af-newspaper:client:toggleReporterPanel', function(isReporter)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'toggleReporterPanel',
        isReporter = isReporter
    })
end)

-- Client tarafında: NUI'den gelen 'copyNewspaper' callback'ini yakalıyoruz
RegisterNUICallback('copyNewspaper', function(data, cb)
    -- Burada data parametresi JS tarafındaki fetch body’den geliyor
    -- Sunucuya event gönderip kopyalama işlemini orada yapacağız
    TriggerServerEvent('af-newspaper:server:copyNewspaper', data)
    cb({}) -- Boş response döndürmek yeterli
end)
