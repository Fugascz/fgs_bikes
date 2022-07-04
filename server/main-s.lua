rentedBikes = {}

AddEventHandler('playerDropped', function()
    local _src = source

    if rentedBikes[_src] then
        rentedBikes[_src] = nil
    end
end)

RegisterNetEvent('fgs-bikes:rental', function(label, value, price)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)

    if xPlayer then
        if isNear(_src) then
            if (xPlayer.getMoney() - price) >= price then
                if canRentBike(_src) then
                    xPlayer.removeMoney(price)
                    spawnVehicle(_src, value)

                    notify(_src, string.format('Zapůjčil/a jste si %s za %s$.', label, price))

                    bikesLog(
                        string.format('**%s (%s)**', GetPlayerName(_src), xPlayer.getIdentifier()),
                        string.format('Zapůjčil/a: **%s**\nSpawn kód: **%s**\n Za: **%s$**', value, value, price)
                    )
                else
                    notify(_src, 'Nemůžeš si půjčit další kolo!')
                end
            else
                notify(_src, 'Nemáš dostatek peněz!')
            end
        end
    end
end)

RegisterNetEvent('fgs-bikes:returnBike', function()
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)

    if rentedBikes[_src] then
        local playerPed = GetPlayerPed(_src)
        local playerVehicle = GetVehiclePedIsIn(playerPed, false)
        local rentedBike = rentedBikes[_src]

        if playerVehicle == rentedBike then
            DeleteEntity(rentedBike)
            rentedBikes[_src] = nil

            xPlayer.addAccountMoney('money', 100)

            notify(_src, 'Vrátil/a jsi zapůjčené kolo. Záloha ti byla vrácena')
        else
            notify(_src, 'Nesedíš na zapůjčeném kole..')
        end
    else
        notify(_src, 'Nemáš zapůjčené žádné kolo!')
    end
end)
