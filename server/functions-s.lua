function notify(playerId, text)
    if not playerId or not text then
        return
    end
    
    local xPlayer = ESX.GetPlayerFromId(playerId)

    if xPlayer then
        xPlayer.showNotification(text)
    end
end

function isNear(playerId)
    if not playerId then
        return
    end

    local playerPed = GetPlayerPed(playerId)
    local playerCoords = GetEntityCoords(playerPed)

    for _, zoneData in pairs(Zones) do
        if zoneData.Enable then
            local dist = #(playerCoords - zoneData.Pos)

            if dist < 10 then
                return true
            end
        end
    end

    return false
end

function canRentBike(playerId)
    if not playerId then
        return
    end

    if not rentedBikes[playerId] then
        return true
    end
    return false
end

function spawnVehicle(playerId, bikeName)
    if not playerId or not bikeName then
        return
    end

    if type(bikeName) == 'string' then
        bikeName = GetHashKey(bikeName)
    end

    local playerPed = GetPlayerPed(playerId)
    local playerCoords = GetEntityCoords(playerPed)
    local playerHeading = GetEntityHeading(playerPed)

    local bike = Citizen.InvokeNative(
        GetHashKey("CREATE_AUTOMOBILE"),
        bikeName,
        playerCoords.x, playerCoords.y, playerCoords.z,
        playerHeading
    )

    while not DoesEntityExist(bike) do
        Wait(20)
    end

    TriggerClientEvent('fgs_bikes:spawnedBike', playerId, bike)

    rentedBikes[playerId] = bike
end

function bikesLog(title, msg)
    local connect = {
        {
            ["color"] = 9699539,
            ["title"] = title,
            ["description"] = msg,
            ["footer"] = {
                ["text"] = 'fgs_bikes | ' .. os.date('%H:%M - %d. %m. %Y', os.time()),
                ["icon_url"] = Webhook.Icon,
            },
        }
    }

    PerformHttpRequest(
        Webhook.Link,
        function(err, _, _)
            if err == 0 then
                print(
                    'Webhook not set up properly...'
                )
            else
                print(
                    'WEDBHOOK ERROR: ' .. err
                )
            end
        end,
        'POST',
        json.encode(
            {
                username = 'BIKE RENTAL SYSTEM',
                embeds = connect
            }
        ),
        {
            ['Content-Type'] = 'application/json'
        }
    )
end
