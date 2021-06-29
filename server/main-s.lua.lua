ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

local rentedBikes = {}

RegisterNetEvent('fgs-bikes:rental')
AddEventHandler('fgs-bikes:rental', function(label, value, price)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    if xPlayer then
        if doesPlayerHaveEnoughMoney(_src, price) then 
            if canRentBike(_src) then
                xPlayer.removeMoney(price)
                table.insert(rentedBikes, { id = _src, bike = value })
                TriggerClientEvent('mythic_notify:client:SendAlert', _src, {type = 'success', text = string.format('Zapůjčil/a jste si %s za %s$.', value, price) })
                TriggerClientEvent('fgs-bikes:spawnCar', _src, value)
                bikesLog(string.format('**%s (%s)**', GetPlayerName(_src), xPlayer.getIdentifier()), string.format('Zapůjčil/a: **%s**\nSpawn kód: **%s**\n Za: **%s$**', value, value, price))
            else 
                TriggerClientEvent('mythic_notify:client:SendAlert', _src, { type = 'Error', text = 'Nemůžeš si půjčit další kolo!' })
            end
        else 
            TriggerClientEvent('mythic_notify:client:SendAlert', _src, { type = 'Error', text = 'Nemáš dostatek peněz!' })
        end
    end
end)

AddEventHandler('playerDropped', function (source)
    if rentedBikes[source] then
        rentedBikes[source] = nil
    end
end)

-- Functions doesPlayerHaveEnoughMoney and isPlayerNearBikeRental is from fivem-dev.cz for secure scripts and learn FiveM programming.
-- Thanks to Strin for posting. ❤
-- https://fivem-dev.cz/index.php?/topic/1592-z%C3%A1klady-lua-skriptov%C3%A1n%C3%AD-ve-fivem/
function canRentBike(id)
    if rentedBikes[id] then
        return false
    else
        return true
    end
end

function doesPlayerHaveEnoughMoney(id, price)
    local xPlayer = ESX.GetPlayerFromId(id)
    if (xPlayer.getMoney() - price) < 0 then
        return false
    end
    return true
end

function isPlayerNearBikeRental(id)
    if Config.OneSync then
        local ped = GetPlayerPed(id)
        local coords = GetEntityCoords(ped)
        local distanceToShop = 100

        for k,v in pairs(Config.Zones) do
            local distance = #(coords - vector3(v.Pos.x, v.Pos.y, v.Pos.z))
            if distance < distanceToShop then
                distanceToShop = distance
            end
            if distanceToShop > 10 then
                return false
            end
        end
    end
    return true
end

function bikesLog(title, msg)
    local connect = {
        {
            ["color"] = 9699539,
            ["title"] = title,
            ["description"] = msg,
            ["footer"] = {
                ["text"] = 'fgs_bikes | ' .. os.date('%H:%M - %d. %m. %Y', os.time()),
                ["icon_url"] = Config.Webhook.Icon,
            },
        }
    }
    PerformHttpRequest(Config.Webhook.Link, function(err, text, headers) end, 'POST', json.encode({username = 'BIKES', embeds = connect}), { ['Content-Type'] = 'application/json' })
end
