Framework = {}
Framework.Core = nil
Framework.Type = Config.Framework

-- CLIENT SIDE
if IsDuplicityVersion() == false then
    Framework.PlayerData = {}

    -- Framework başlatma
    CreateThread(function()
        if Config.Framework == 'rsg-core' then
            Framework.Core = exports['rsg-core']:GetCoreObject()
        elseif Config.Framework == 'vorp' then
            while not exports.vorp_core:GetCore() do
                Wait(100)
            end
            Framework.VorpCore = exports.vorp_core:GetCore()
            
            -- VORP character load event
            AddEventHandler('vorp:SelectedCharacter', function(user)
                Framework.PlayerData = {
                    job = {
                        name = user.job or 'unemployed'
                    }
                }
            end)
        end
    end)

    -- Oyuncu verisi alma
    function Framework:GetPlayerData()
        if self.Type == 'rsg-core' then
            return self.Core.Functions.GetPlayerData()
        elseif self.Type == 'vorp' then
            -- VORP için server'dan job bilgisini al
            if not self.PlayerData.job then
                TriggerServerEvent('af-newspaper:server:getPlayerJob')
                Wait(100)
            end
            return self.PlayerData
        end
    end

    -- VORP için player data güncelleme eventi
    if Config.Framework == 'vorp' then
        RegisterNetEvent('af-newspaper:client:updatePlayerData')
        AddEventHandler('af-newspaper:client:updatePlayerData', function(data)
            Framework.PlayerData = data
        end)
    end

    -- Notification gösterme
    function Framework:Notify(title, message, type)
        if self.Type == 'rsg-core' then
            TriggerEvent('ox_lib:notify', {
                title = title,
                description = message,
                type = type
            })
        elseif self.Type == 'vorp' then
            TriggerEvent("vorp:TipBottom", message, 4000)
        end
    end

    -- Callback sistemi
    function Framework:TriggerCallback(name, cb, ...)
        if self.Type == 'rsg-core' then
            self.Core.Functions.TriggerCallback(name, cb, ...)
        elseif self.Type == 'vorp' then
            -- VORP event bazlı sistem kullanıyor
            TriggerServerEvent(name, ...)
        end
    end

-- SERVER SIDE
else
    -- Framework başlatma
    if Config.Framework == 'rsg-core' then
        Framework.Core = exports['rsg-core']:GetCoreObject()
    elseif Config.Framework == 'vorp' then
        Framework.VorpCore = exports.vorp_core:GetCore()
    end

    -- Oyuncu bilgisi alma
    function Framework:GetPlayer(source)
        if self.Type == 'rsg-core' then
            return self.Core.Functions.GetPlayer(source)
        elseif self.Type == 'vorp' then
            local User = self.VorpCore.getUser(source)
            if User then
                return User.getUsedCharacter
            end
        end
        return nil
    end

    -- Oyuncu job bilgisi alma
    function Framework:GetPlayerJob(source)
        if self.Type == 'rsg-core' then
            local Player = self.Core.Functions.GetPlayer(source)
            if Player then
                return Player.PlayerData.job.name
            end
        elseif self.Type == 'vorp' then
            local User = self.VorpCore.getUser(source)
            if User then
                local Character = User.getUsedCharacter
                return Character.job
            end
        end
        return nil
    end

    -- Oyuncu ismi alma
    function Framework:GetPlayerName(source)
        if self.Type == 'rsg-core' then
            local Player = self.Core.Functions.GetPlayer(source)
            if Player then
                return Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
            end
        elseif self.Type == 'vorp' then
            local User = self.VorpCore.getUser(source)
            if User then
                local Character = User.getUsedCharacter
                return Character.firstname .. ' ' .. Character.lastname
            end
        end
        return "Bilinmeyen"
    end

    -- Item ekleme
    function Framework:AddItem(source, item, count, metadata)
        if self.Type == 'rsg-core' then
            local Player = self.Core.Functions.GetPlayer(source)
            if Player then
                Player.Functions.AddItem(item, count, nil, metadata)
                TriggerClientEvent('inventory:client:ItemBox', source, self.Core.Shared.Items[item], 'add')
            end
        elseif self.Type == 'vorp' then
            -- VORP için metadata desteği
            local metadataTable = nil
            if metadata and metadata.gazeteTarih then
                metadataTable = {
                    description = "Tarih: " .. metadata.gazeteTarih,
                    gazeteTarih = metadata.gazeteTarih
                }
            end
            exports.vorp_inventory:addItem(source, item, count, metadataTable)
        end
    end

    -- Item silme
    function Framework:RemoveItem(source, item, count)
        if self.Type == 'rsg-core' then
            local Player = self.Core.Functions.GetPlayer(source)
            if Player then
                Player.Functions.RemoveItem(item, count)
            end
        elseif self.Type == 'vorp' then
            exports.vorp_inventory:subItem(source, item, count)
        end
    end

    -- Envanter ağırlık kontrolü
    function Framework:CanCarryItem(source, item, count)
        if self.Type == 'rsg-core' then
            local Player = self.Core.Functions.GetPlayer(source)
            if Player then
                local weight = self.Core.Shared.Items[item] and self.Core.Shared.Items[item].weight or 100
                local totalWeight = weight * count
                local freeWeight = exports['rsg-inventory']:GetFreeWeight(source) or 0
                return freeWeight >= totalWeight
            end
        elseif self.Type == 'vorp' then
            return exports.vorp_inventory:canCarryItem(source, item, count)
        end
        return false
    end

    -- Notification gönderme
    function Framework:Notify(source, title, message, type)
        if self.Type == 'rsg-core' then
            TriggerClientEvent('ox_lib:notify', source, {
                title = title,
                description = message,
                type = type
            })
        elseif self.Type == 'vorp' then
            TriggerClientEvent("vorp:TipBottom", source, message, 4000)
        end
    end

    -- Callback oluşturma (sadece RSG-Core için)
    function Framework:CreateCallback(name, cb)
        if self.Type == 'rsg-core' then
            self.Core.Functions.CreateCallback(name, cb)
        end
    end
end