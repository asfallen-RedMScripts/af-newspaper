function CreateNewVersion()
    local latestVersion = exports.oxmysql:scalarSync('SELECT MAX(version) FROM newspaper')
    local newVersion = (latestVersion or 0) + 1
    return newVersion
end

-- Ana gazete kullanma fonksiyonu
function UseNewspaper(source, item)
    local Player = Framework:GetPlayer(source)
    if not Player then return end

    local newspaperId = nil
    local itemId = nil
    
    -- VORP ve RSG-Core için metadata alma
    if Config.Framework == 'vorp' then
        itemId = item.metadata and item.metadata.gazeteTarih
        DebugPrint("VORP - Item metadata gazeteTarih: " .. tostring(itemId))
    else
        itemId = item.info and item.info.gazeteTarih
        DebugPrint("RSG-Core - Item info gazeteTarih: " .. tostring(itemId))
    end
    
    if itemId then
        local trimmedItemId = tostring(itemId):match("^%s*(.-)%s*$")
        DebugPrint("Aranacak item ID: " .. trimmedItemId)
       
        exports.oxmysql:execute('SELECT newspaper_id FROM newspaper_lookup WHERE item_id = ?', {trimmedItemId}, function(result)
            if result and #result > 0 then
                newspaperId = result[1].newspaper_id
                DebugPrint("Bulunan newspaper ID: " .. newspaperId)
                exports.oxmysql:execute('SELECT * FROM newspaper WHERE id = ?', {newspaperId}, function(newsResult)
                    if newsResult and #newsResult > 0 then
                        local job = Framework:GetPlayerJob(source)
                        local isReporter = (job == Config.JobName)
                        
                        if Config.Framework == 'vorp' then
                            TriggerClientEvent('af-newspaper:client:openNewspaper', source, newspaperId, isReporter)
                        else
                            TriggerClientEvent('af-newspaper:client:openNewspaper', source, newspaperId, isReporter)
                        end
                    else
                        Framework:Notify(source, 'Gazete', 'Gazete verisi bulunamadı.', 'error')
                    end
                end)
            else
                DebugPrint("Item ID bulunamadı, en son gazete gösterilecek: " .. trimmedItemId)
                exports.oxmysql:execute('SELECT id FROM newspaper ORDER BY version DESC LIMIT 1', {}, function(latestResult)
                    if latestResult and #latestResult > 0 then
                        newspaperId = latestResult[1].id
                        exports.oxmysql:insert('INSERT INTO newspaper_lookup (item_id, newspaper_id) VALUES (?, ?)', {trimmedItemId, newspaperId}, function()
                            local job = Framework:GetPlayerJob(source)
                            local isReporter = (job == Config.JobName)
                            
                            if Config.Framework == 'vorp' then
                                TriggerClientEvent('af-newspaper:client:openNewspaper', source, newspaperId, isReporter)
                            else
                                TriggerClientEvent('af-newspaper:client:openNewspaper', source, newspaperId, isReporter)
                            end
                        end)
                    else
                        Framework:Notify(source, 'Gazete', 'Gazete verisi bulunamadı.', 'error')
                    end
                end)
            end
        end)
    else
        DebugPrint("Item metadata'da gazeteTarih bulunamadı, yeni ID oluşturuluyor")
        exports.oxmysql:execute('SELECT id FROM newspaper ORDER BY version DESC LIMIT 1', {}, function(latestResult)
            if latestResult and #latestResult > 0 then
                newspaperId = latestResult[1].id
                local baseId = os.date("%d.%m.") .. "1903"
                
                exports.oxmysql:execute("SELECT COUNT(*) as count FROM newspaper_lookup WHERE item_id LIKE ?", {baseId .. "%"}, function(countResult)
                    if countResult and countResult[1] and countResult[1].count then
                        local count = tonumber(countResult[1].count)
                        local newItemId = baseId .. "-" .. tostring(count + 1)
                        
                        exports.oxmysql:insert('INSERT INTO newspaper_lookup (item_id, newspaper_id) VALUES (?, ?)', {newItemId, newspaperId}, function()
                            if Config.Framework == 'rsg-core' then
                                -- RSG-Core için item güncelleme
                                local Player = Framework.Core.Functions.GetPlayer(source)
                                if Player and item.slot then
                                    local itemData = Player.Functions.GetItemBySlot(item.slot)
                                    if itemData then
                                        Player.Functions.RemoveItem(itemData.name, 1, itemData.slot)
                                        local newMeta = itemData.metadata or {}
                                        newMeta.gazeteTarih = newItemId
                                        Player.Functions.AddItem(itemData.name, 1, itemData.slot, newMeta)
                                    end
                                end
                            elseif Config.Framework == 'vorp' then
                                -- VORP için metadata güncelleme
                                Framework:RemoveItem(source, Config.ItemName, 1)
                                Framework:AddItem(source, Config.ItemName, 1, {gazeteTarih = newItemId})
                            end
                            
                            local job = Framework:GetPlayerJob(source)
                            local isReporter = (job == Config.JobName)
                            
                            if Config.Framework == 'vorp' then
                                TriggerClientEvent('af-newspaper:client:openNewspaper', source, newspaperId, isReporter)
                            else
                                TriggerClientEvent('af-newspaper:client:openNewspaper', source, newspaperId, isReporter)
                            end
                        end)
                    else
                        Framework:Notify(source, 'Gazete', 'Yeni ID oluşturulamadı.', 'error')
                    end
                end)
            else
                Framework:Notify(source, 'Gazete', 'Gazete verisi bulunamadı.', 'error')
            end
        end)
    end
end

-- Useable item kaydı
if Config.Framework == 'rsg-core' then
    Framework.Core.Functions.CreateUseableItem(Config.ItemName, function(source, item)
        UseNewspaper(source, item)
    end)
elseif Config.Framework == 'vorp' then
    -- VORP için doğru event handler
    exports.vorp_inventory:registerUsableItem(Config.ItemName, function(data)
        local source = data.source
        local itemData = data.item
        local itemMetadata = data.item.metadata
        
        DebugPrint("VORP: Gazete kullanılıyor - Source: " .. source)
        DebugPrint("VORP: Item metadata: " .. json.encode(itemMetadata or {}))
        
        UseNewspaper(source, {
            metadata = itemMetadata, -- Doğru metadata geçişi
            item = itemData
        })
    end, "af-newspaper")
end

-- VORP için oyuncu job bilgisi alma eventi
if Config.Framework == 'vorp' then
    RegisterNetEvent('af-newspaper:server:getPlayerJob', function()
        local src = source
        local job = Framework:GetPlayerJob(src)
        TriggerClientEvent('af-newspaper:client:updatePlayerData', src, {
            job = {
                name = job or 'unemployed'
            }
        })
    end)
    
    RegisterNetEvent('af-newspaper:server:openVersion', function(newspaperId)
        local src = source
        local job = Framework:GetPlayerJob(src)
        local isReporter = (job == Config.JobName)
        TriggerClientEvent('af-newspaper:client:openNewspaper', src, newspaperId, isReporter)
    end)
end

-- Gazete satın alma
RegisterNetEvent('af-newspaper:buy', function()
    local source = source
    local newVersion = CreateNewVersion()
    
    exports.oxmysql:insert(
        'INSERT INTO newspaper (title, body, date, image, publisher, version) VALUES (?, ?, ?, ?, ?, ?)',
        {'Başlık Yok', 'İçerik Yok', os.date('%d.%m.1903'), 'resim_yok.png', 'Yayıncı Yok', newVersion},
        function(insertId)
            local newItemId = tostring(math.random(100000, 999999))
            exports.oxmysql:insert('INSERT INTO newspaper_lookup (item_id, newspaper_id) VALUES (?, ?)', {newItemId, insertId}, function()
                Framework:AddItem(source, Config.ItemName, 1, { gazeteTarih = newItemId })
                Framework:Notify(source, 'Gazete', 'Yeni gazete satın alındı!', 'success')
            end)
        end
    )
end)

-- Haber yayınlama
RegisterNetEvent('af-newspaper:server:publishStory', function(data)
    local src = source
    local job = Framework:GetPlayerJob(src)
    
    if job ~= Config.JobName then
        Framework:Notify(src, 'Gazete', 'Sadece gazeteciler yeni haber ekleyebilir.', 'error')
        return
    end

    local playerName = Framework:GetPlayerName(src)
    local currentDate = os.date('%d.%m.1903')
    local newVersion = CreateNewVersion()

    exports.oxmysql:insert(
        'INSERT INTO newspaper (title, body, date, image, publisher, version) VALUES (?, ?, ?, ?, ?, ?)',
        {data.title, data.body, currentDate, data.image, playerName, newVersion},
        function(insertId)
            local baseId = os.date("%d.%m.") .. "1903"
            
            exports.oxmysql:execute("SELECT COUNT(*) as count FROM newspaper_lookup WHERE item_id LIKE ?", {baseId .. "%"}, function(countResult)
                if countResult and countResult[1] and countResult[1].count then
                    local count = tonumber(countResult[1].count)
                    local newItemId = baseId .. "-" .. tostring(count + 1)
                    
                    exports.oxmysql:insert('INSERT INTO newspaper_lookup (item_id, newspaper_id) VALUES (?, ?)', {newItemId, insertId}, function()
                        Framework:AddItem(src, Config.ItemName, 1, { gazeteTarih = newItemId })
                        Framework:Notify(src, 'Gazete', 'Yeni gazete başarıyla yayınlandı!', 'success')
                    end)
                else
                    Framework:Notify(src, 'Gazete', 'Yeni ID oluşturulamadı.', 'error')
                end
            end)
        end
    )
end)

-- Callback ve Event sistemleri
if Config.Framework == 'rsg-core' then
    -- RSG-Core Callbacks
    Framework.Core.Functions.CreateCallback('af-newspaper:server:getStories', function(source, cb, newspaperId)
        exports.oxmysql:execute('SELECT * FROM newspaper WHERE id = ?', {newspaperId}, function(result)
            cb(result or {})
        end)
    end)

    Framework.Core.Functions.CreateCallback('af-newspaper:server:getAllStories', function(source, cb)
        exports.oxmysql:execute('SELECT id, title, date, version FROM newspaper ORDER BY version DESC', {}, function(result)
            cb(result)
        end)
    end)
else
    -- VORP Events
    RegisterNetEvent('af-newspaper:server:getStories', function(newspaperId)
        local src = source
        local job = Framework:GetPlayerJob(src)
        local isReporter = (job == Config.JobName)
        
        exports.oxmysql:execute('SELECT * FROM newspaper WHERE id = ?', {newspaperId}, function(result)
            TriggerClientEvent('af-newspaper:client:receiveStories', src, result or {}, isReporter)
        end)
    end)

    RegisterNetEvent('af-newspaper:server:getAllStories', function()
        local src = source
        exports.oxmysql:execute('SELECT id, title, date, version FROM newspaper ORDER BY version DESC', {}, function(result)
            TriggerClientEvent('af-newspaper:client:receiveAllStories', src, result)
        end)
    end)
end

-- Reporter panel komutu
RegisterCommand('reporterpanel', function(source, args, rawCommand)
    local job = Framework:GetPlayerJob(source)
    
    if job == Config.JobName then
        TriggerClientEvent('af-newspaper:client:toggleReporterPanel', source, true)
    else
        Framework:Notify(source, 'Gazete', 'Sadece gazeteciler bu paneli açabilir.', 'error')
    end
end)

-- Gazete kopyalama
RegisterNetEvent('af-newspaper:server:copyNewspaper', function(data)
    local src = source
    local newspaperId = data.newspaperId
    local copyCount = tonumber(data.copyCount) or 1

    -- Envanter kontrolü
    local canCarry = Framework:CanCarryItem(src, Config.ItemName, copyCount)
    if not canCarry then
        Framework:Notify(src, 'Envanter', 'Bu kadar gazeteyi taşıyacak yerin yok!', 'error')
        return
    end

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
                        Framework:AddItem(src, Config.ItemName, 1, { gazeteTarih = uniqueId })
                    end
                    Framework:Notify(src, 'Gazete', copyCount .. ' adet gazete envanterinize eklendi.', 'success')
                else
                    Framework:Notify(src, 'Gazete', 'Gazete verisi bulunamadı.', 'error')
                end
            end)
        else
            Framework:Notify(src, 'Gazete', 'Geçersiz gazete id\'si.', 'error')
        end
    end)
end)