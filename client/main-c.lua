isInVehicle = false
isMenuOpen = false
isShow = false

do
    if USE_BASEEVENTS then
        RegisterNetEvent('baseevents:leftVehicle', function()
            isInVehicle = false
        end)

        RegisterNetEvent('baseevents:enteredVehicle', function()
            isInVehicle = true
        end)
    else
        CreateThread(function()
            while true do
                Wait(500)

                local playerPed = PlayerPedId()
                isInVehicle = IsPedInAnyVehicle(playerPed, false)
            end
        end)
    end
end

RegisterNetEvent('fgs_bikes:spawnedBike', function(netId)
    local bikeId = NetToVeh(netId)
    local playerPed = PlayerPedId()

    SetPedIntoVehicle(playerPed, bikeId, -1)
end)

CreateThread(function ()
    for _,v in pairs(Zones) do
        if v.EnableBlip then
            local blip = AddBlipForCoord(v.Pos.x, v.Pos.y, v.Pos.z)
            SetBlipSprite(blip, 494)
            SetBlipColour(blip, 26)
            SetBlipScale(blip, 0.6)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString("Půjčovna kol")
            EndTextCommandSetBlipName(blip)
        end
    end

    while true do
        Wait(0)

        local letSleep = true
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        for _, v in pairs(Zones) do
            local dist = #(playerCoords - v.Pos)

            if (v.Enable and dist < 10) then
                letSleep = false

                DrawMarker(
                    v.Marker.Type,
                    v.Pos.x, v.Pos.y, v.Pos.z,
                    0.0, 0.0, 0.0, 0, 0.0, 0.0,
                    v.Marker.Size.x, v.Marker.Size.y, v.Marker.Size.z,
                    v.Marker.Color.r, v.Marker.Color.g, v.Marker.Color.b, 100,
                    false, false, 2, true,
                    false, false, false
                )

                if dist < 1 then
                    if not isShow then
                        lib.showTextUI('[E] - Půjčovna kol', {
                            position = "left-center",
                            icon = "bicycle",
                        })

                        isShow = true
                    end

                    if IsControlJustPressed(0, 38) then
                        openBikeMenu(v.Bikes)
                    end
                end

                if isShow and dist > 1 then
                    lib.hideTextUI()

                    isShow = false
                end

                if isMenuOpen then
                    if dist > 1 then
                        ESX.UI.Menu.Close('default', GetCurrentResourceName(), 'fgs_bikemenu')
                    end
                end
            end
        end

        if letSleep then
            Wait(1000)
        end
    end
end)

function openBikeMenu(Items)
    local elements = {}

    if not isInVehicle then
        for i=1, #Items do
            local item = Items[i]

            table.insert(
                elements,
                {
                    label = string.format('%s - %s$', item.label, item.price),
                    value = item.value,
                    price = item.price + 100
                }
            )
        end
    else
        table.insert(
            elements,
            {
                label = 'Vrátit kolo',
                value = 'return'
            }
        )
    end

    if #elements > 0 then
        isMenuOpen = true
        ESX.UI.Menu.Open(
            'default',
            GetCurrentResourceName(),
            'fgs_bikemenu',
            {
                title = 'Půjčovna kol (záloha 100$)',
                align = 'right',
                elements = elements
            },
            function(data, menu)
                menu.close()
                isMenuOpen = false

                if data.current.value == 'return' then
                    TriggerServerEvent('fgs-bikes:returnBike')
                else
                    TriggerServerEvent('fgs-bikes:rental', data.current.label, data.current.value, data.current.price)
                end
            end,
            function(_, menu)
                menu.close()
                isMenuOpen = false
            end
        )
    end
end

AddEventHandler('onResourceStop', function(resName)
    if GetCurrentResourceName() == resName then
        if isMenuOpen then
            ESX.UI.Menu.Close('default', GetCurrentResourceName(), 'fgs_bikemenu')
        end
    end
end)