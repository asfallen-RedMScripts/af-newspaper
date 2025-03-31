local RSGCore = exports['rsg-core']:GetCoreObject()

-- Yeni bir gazete versiyonu oluşturma fonksiyonu
function CreateNewVersion()
    local latestVersion = exports.oxmysql:scalarSync('SELECT MAX(version) FROM newspaper')
    local newVersion = (latestVersion or 0) + 1
    return newVersion
end

RSGCore.Functions.CreateUseableItem("newspaper", function(source, item)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then
        return
    end

    local newspaperId = nil
    -- Artık item.info.newspaperId yerine item.info.gazeteTarih kullanılacak.
    local itemId = item.info and item.info.gazeteTarih
    if itemId then
        local trimmedItemId = tostring(itemId):match("^%s*(.-)%s*$")
       
        -- Lookup tablosunda ilgili item_id var mı kontrol ediyoruz
        exports.oxmysql:execute('SELECT newspaper_id FROM newspaper_lookup WHERE item_id = ?', {trimmedItemId}, function(result)
            if result and #result > 0 then
                newspaperId = result[1].newspaper_id
                exports.oxmysql:execute('SELECT * FROM newspaper WHERE id = ?', {newspaperId}, function(newsResult)
                    if newsResult and #newsResult > 0 then
                        TriggerClientEvent('af-newspaper:client:openNewspaper', source, newspaperId)
                    else
                        TriggerClientEvent('ox_lib:notify', source, {
                            title = 'Gazete',
                            description = 'Gazete verisi bulunamadı.',
                            type = 'error'
                        })
                    end
                end)
            else
       
                exports.oxmysql:execute('SELECT id FROM newspaper ORDER BY version DESC LIMIT 1', {}, function(latestResult)
                    if latestResult and #latestResult > 0 then
                        newspaperId = latestResult[1].id
                        exports.oxmysql:insert('INSERT INTO newspaper_lookup (item_id, newspaper_id) VALUES (?, ?)', {trimmedItemId, newspaperId}, function()
                            TriggerClientEvent('af-newspaper:client:openNewspaper', source, newspaperId)
                        end)
                    else
                        TriggerClientEvent('ox_lib:notify', source, {
                            title = 'Gazete',
                            description = 'Gazete verisi bulunamadı.',
                            type = 'error'
                        })
                    end
                end)
            end
        end)
    else
    
        exports.oxmysql:execute('SELECT id FROM newspaper ORDER BY version DESC LIMIT 1', {}, function(latestResult)
            if latestResult and #latestResult > 0 then
                newspaperId = latestResult[1].id
                -- Temel ID'yi oluştur: gün ve ay bilgisi nokta ayracıyla + sabit "1903"
local baseId = os.date("%d.%m.") .. "1903"  -- Örneğin: "22.08.1903"
-- Aynı formatta kaç kayıt var öğrenelim
exports.oxmysql:execute("SELECT COUNT(*) as count FROM newspaper_lookup WHERE item_id LIKE ?", {baseId .. "%"}, function(countResult)
    if countResult and countResult[1] and countResult[1].count then
        local count = tonumber(countResult[1].count)
        local newItemId = baseId .. "-" .. tostring(count + 1)  -- İlk kayıt "-1", sonraki "-2", "-3" şeklinde
        -- Devamında newItemId'yi kullanarak lookup kaydını ekleyip item'in metadata'sını güncelliyorsunuz.
        exports.oxmysql:insert('INSERT INTO newspaper_lookup (item_id, newspaper_id) VALUES (?, ?)', {newItemId, newspaperId}, function()
            local itemData = Player.Functions.GetItemBySlot(item.slot)
            if itemData then
                Player.Functions.RemoveItem(itemData.name, 1, itemData.slot)
                local newMeta = itemData.metadata or {}
                newMeta.gazeteTarih = newItemId
                Player.Functions.AddItem(itemData.name, 1, itemData.slot, newMeta)
            end
    
            TriggerClientEvent('af-newspaper:client:openNewspaper', source, newspaperId)
        end)
    else

        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Gazete',
            description = 'Yeni ID oluşturulamadı.',
            type = 'error'
        })
    end
end)
            else
                TriggerClientEvent('ox_lib:notify', source, {
                    title = 'Gazete',
                    description = 'Gazete verisi bulunamadı.',
                    type = 'error'
                })
            end
        end)
    end
end)




-- Gazete satın alma event'i
RegisterNetEvent('af-newspaper:buy', function()
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return end

    local newVersion = CreateNewVersion()
    -- Yeni gazete verisini ekle
    exports.oxmysql:insert(
        'INSERT INTO newspaper (title, body, date, image, publisher, version) VALUES (?, ?, ?, ?, ?, ?)',
        {'Başlık Yok', 'İçerik Yok', os.date('%d.%m.1903'), 'resim_yok.png', 'Yayıncı Yok', newVersion},
        function(insertId)
            -- Yeni bir item_id oluştur ve newspaper_lookup'a kaydet
            local newItemId = tostring(math.random(100000, 999999)) -- Rastgele bir item_id oluştur
            exports.oxmysql:insert('INSERT INTO newspaper_lookup (item_id, newspaper_id) VALUES (?, ?)', {newItemId, insertId}, function()
                -- Envantere yeni gazete ekle
                Player.Functions.AddItem('newspaper', 1, nil, { gazeteTarih = newItemId })
                TriggerClientEvent('inventory:client:ItemBox', source, RSGCore.Shared.Items['newspaper'], 'add')
                TriggerClientEvent('ox_lib:notify', source, {
                    title = 'Gazete',
                    description = 'Yeni gazete satın alındı!',
                    type = 'success'
                })
            end)
        end
    )
end)

--[[


RegisterNetEvent('af-newspaper:server:publishStory', function(data)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    if Player.PlayerData.job.name ~= 'reporter' then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Gazete',
            description = 'Sadece gazeteciler yeni haber ekleyebilir.',
            type = 'error'
        })
        return
    end

    local playerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    local currentDate = os.date('%d.%m.1903')
    local newVersion = CreateNewVersion()

    -- Yeni gazete verisini ekle
    exports.oxmysql:insert(
        'INSERT INTO newspaper (title, body, date, image, publisher, version) VALUES (?, ?, ?, ?, ?, ?)',
        {data.title, data.body, currentDate, data.image, playerName, newVersion},
        function(insertId)
            -- Yeni bir item_id oluştur ve newspaper_lookup'a kaydet
            local newItemId = tostring(math.random(100000, 999999))
            exports.oxmysql:insert('INSERT INTO newspaper_lookup (item_id, newspaper_id) VALUES (?, ?)', {newItemId, insertId}, function()
                -- Envantere ekleme kodları kaldırıldı; sadece DB güncellensin
                TriggerClientEvent('ox_lib:notify', src, {
                    title = 'Gazete',
                    description = 'Yeni gazete başarıyla yayınlandı!',
                    type = 'success'
                })
            end)
        end
    )
end)
]]

-- Haber yayınlama event'i envantere gazete veriyor.
RegisterNetEvent('af-newspaper:server:publishStory', function(data)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    if Player.PlayerData.job.name ~= 'reporter' then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Gazete',
            description = 'Sadece gazeteciler yeni haber ekleyebilir.',
            type = 'error'
        })
        return
    end

    local playerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    local currentDate = os.date('%d.%m.1903')
    local newVersion = CreateNewVersion()

    -- Yeni gazete verisini ekle
    exports.oxmysql:insert(
        'INSERT INTO newspaper (title, body, date, image, publisher, version) VALUES (?, ?, ?, ?, ?, ?)',
        {data.title, data.body, currentDate, data.image, playerName, newVersion},
        function(insertId)
            -- Yeni item ID'sini tarih tabanlı oluşturalım
            local baseId = os.date("%d.%m.") .. "1903"  -- Örneğin: "22.08.1903"
            -- Aynı formatta kaç kayıt var öğrenelim
            exports.oxmysql:execute("SELECT COUNT(*) as count FROM newspaper_lookup WHERE item_id LIKE ?", {baseId .. "%"}, function(countResult)
                if countResult and countResult[1] and countResult[1].count then
                    local count = tonumber(countResult[1].count)
                    local newItemId = baseId .. "-" .. tostring(count + 1)
                    -- Lookup kaydını oluştur
                    exports.oxmysql:insert('INSERT INTO newspaper_lookup (item_id, newspaper_id) VALUES (?, ?)', {newItemId, insertId}, function()
                        -- Yeni gazete item'ini envantere ekle, metadata olarak gazeteTarih alanını güncelleyelim
                        Player.Functions.AddItem('newspaper', 1, nil, { gazeteTarih = newItemId })
                        TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items['newspaper'], 'add')
                        TriggerClientEvent('ox_lib:notify', src, {
                            title = 'Gazete',
                            description = 'Yeni gazete başarıyla yayınlandı!',
                            type = 'success'
                        })
                    end)
                else
                    TriggerClientEvent('ox_lib:notify', src, {
                        title = 'Gazete',
                        description = 'Yeni ID oluşturulamadı.',
                        type = 'error'
                    })
                end
            end)
        end
    )
end)


-- Callback: Client tarafında getStories çağrısı yapıldığında
RSGCore.Functions.CreateCallback('af-newspaper:server:getStories', function(source, cb, newspaperId)
    exports.oxmysql:execute('SELECT * FROM newspaper WHERE id = ?', {newspaperId}, function(result)
        if result and #result > 0 then
            cb(result)
        else
            cb({}) -- Gazete verisi bulunamadı
        end
    end)
end)


RSGCore.Functions.CreateCallback('af-newspaper:server:getAllStories', function(source, cb)
    exports.oxmysql:execute('SELECT id, title, date, version FROM newspaper ORDER BY version DESC', {}, function(result)
        cb(result)
    end)
end)

RegisterCommand('reporterpanel', function(source, args, rawCommand)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return end

    if Player.PlayerData.job.name == 'reporter' then
        TriggerClientEvent('af-newspaper:client:toggleReporterPanel', source, true)
    else
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Gazete',
            description = 'Sadece gazeteciler bu paneli açabilir.',
            type = 'error'
        })
    end
end)



-- Sunucuda normal bir event oluşturuyoruz
RegisterNetEvent('af-newspaper:server:copyNewspaper', function(data)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local newspaperId = data.newspaperId
    local copyCount = tonumber(data.copyCount) or 1

    -- Her bir gazetenin ağırlığını alıyoruz
    local itemWeight = RSGCore.Shared.Items['newspaper'].weight or 100

    -- Oyuncunun envanterinde kalan boş ağırlığı alıyoruz
    local freeWeight = exports['rsg-inventory']:GetFreeWeight(src) or 0

    DebugPrint(("[DEBUG] freeWeight=%.2f, itemWeight=%.2f, copyCount=%d, requiredWeight=%.2f")
    :format(freeWeight, itemWeight, copyCount, (copyCount * itemWeight)))


    -- Eğer talep edilen toplam ağırlık, oyuncunun envanterindeki boş alandan büyükse işlemi iptal ediyoruz
    if (copyCount * itemWeight) > freeWeight then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Envanter',
            description = 'Bu kadar gazeteyi taşıyacak yerin yok!',
            type = 'error'
        })
        return
    end

    -- Gazete ID'sini doğrulayalım
    exports.oxmysql:execute('SELECT id FROM newspaper WHERE id = ?', {newspaperId}, function(result)
        if result and #result > 0 then
            local newspaperIdConfirmed = result[1].id
            exports.oxmysql:execute('SELECT * FROM newspaper WHERE id = ?', {newspaperIdConfirmed}, function(newsResult)
                if newsResult and #newsResult > 0 then
                    local baseId = os.date("%d.%m.") .. "1903"
                    for i = 1, copyCount do
                        local uniqueId = baseId .. "-" .. tostring(os.time() + i)
                        exports.oxmysql:insert(
                            'INSERT INTO newspaper_lookup (item_id, newspaper_id) VALUES (?, ?)',
                            { uniqueId, newspaperIdConfirmed }
                        )
                        Player.Functions.AddItem('newspaper', 1, nil, { gazeteTarih = uniqueId ,})
                    end
                    TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items['newspaper'], 'add')
                    TriggerClientEvent('ox_lib:notify', src, {
                        title = 'Gazete',
                        description = copyCount .. ' adet gazete envanterinize eklendi.',
                        type = 'success'
                    })
                else
                    TriggerClientEvent('ox_lib:notify', src, {
                        title = 'Gazete',
                        description = 'Gazete verisi bulunamadı.',
                        type = 'error'
                    })
                end
            end)
        else
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Gazete',
                description = 'Geçersiz gazete id\'si.',
                type = 'error'
            })
        end
    end)
end)
