ESX = nil
local nearestCoords
local timeToWait = 500
local nearRental = false

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Wait(1)
    end
    Blips()
end)

-- Thread to marker is from Squizer's documentation.
-- Thanks to Squizer for posting. ❤
-- https://docs.squizer.cz/snippets/optimalization
Citizen.CreateThread(function()
    while true do
        Wait(500)
        if nearestCoords then
            local ped = PlayerPedId()
            local pedCoords = GetEntityCoords(ped)
            if #(pedCoords - nearestCoords) > Config.DrawDistance then
                nearestCoords = nil
                timeToWait = 500
            else
                Wait(500)
            end
        else
            Wait(500)
        end
    end
end)

Citizen.CreateThread(function ()
    while true do
        Wait(timeToWait)

        for k,v in pairs(Config.Zones) do
            local coords = GetEntityCoords(PlayerPedId())
            local dist = #(coords - vector3(v.Pos.x, v.Pos.y, v.Pos.z))
            if (v.Enable and dist < Config.DrawDistance) then
                if not nearestCoords then
                    timeToWait = 0
                    nearestCoords = vector3(v.Pos.x, v.Pos.y, v.Pos.z)
                end
                DrawMarker(v.Marker.Type, v.Pos.x, v.Pos.y, v.Pos.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, v.Marker.Size.x, v.Marker.Size.y, v.Marker.Size.z, v.Marker.Color.r, v.Marker.Color.g, v.Marker.Color.b, 100, false, false, 2, true, false, false, false)
                nearRental = true
                if dist < 1 then
                    DrawText3D(v.Pos.x, v.Pos.y, v.Pos.z + 0.75, '[E] Pujcovna kol')
                    if IsControlJustPressed(0, 38) then
                        openBikeMenu(v.Bikes)
                    end
                else
                    if dist > 1 then
                        nearRental = false
                        ESX.UI.Menu.Close('default', GetCurrentResourceName(), 'fgs_bikemenu')
                    end
                end
            end
        end
    end
end)

function DrawText3D(x,y,z, text)
	local onScreen, _x, _y = World3dToScreen2d(x, y, z)
	local p = GetGameplayCamCoords()
	local distance = #(vector3(p.x, p.y, p.z) - vector3(x, y, z))
	local scale = (1 / distance) * 2
	local fov = (1 / GetGameplayCamFov()) * 100
	local scale = scale * fov
	if onScreen then
		SetTextScale(0.35, 0.35)
		SetTextFont(4)
		SetTextProportional(1)
		SetTextColour(255, 255, 255, 215)
		SetTextEntry("STRING")
		SetTextCentre(1)
		AddTextComponentString(text)
		DrawText(_x,_y)
		local factor = (string.len(text)) / 370
		DrawRect(_x,_y+0.0135, 0.025+ factor, 0.03, 0, 0, 0, 150)
	end
end

function Blips()
    for k,v in pairs(Config.Zones) do
        if v.EnableBlip then
            Citizen.CreateThread(function()
                blip = AddBlipForCoord(v.Pos.x, v.Pos.y, v.Pos.z)
                SetBlipSprite(blip, 494)
                SetBlipColour(blip, 26)
                SetBlipScale(blip, 0.6)
                SetBlipAsShortRange(blip, true)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString("Pujcovna kol")
                EndTextCommandSetBlipName(blip)
            end)
        end
    end
end

function openBikeMenu(Items)
    local elements = {}

    for i=1, #Items do
        local item = Items[i] 
        table.insert(elements, {label = string.format('<span style="color:red;">%s</span> - <span style="color:green;">%s$</span>', item.label, item.price), value = item.value, price = item.price})
    end

    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'fgs_bikemenu',
    {   
        title = 'Půjčovna kol',
        align = 'right',
        elements = elements
    },
    function (data, menu)
        TriggerServerEvent('fgs-bikes:rental', data.current.label, data.current.value, data.current.price)
    end, function(data, menu)    
        menu.close()
    end)
end

RegisterNetEvent('fgs-bikes:spawnCar')
AddEventHandler('fgs-bikes:spawnCar', function(spawnName)
    if nearRental then
        local ped = PlayerPedId()
        SpawnVehicle(spawnName, GetEntityCoords(ped), GetEntityHeading(ped), ped)
    end
end)

function SpawnVehicle(modelName, coords, heading, ped)
	local model = (type(modelName) == 'number' and modelName or GetHashKey(modelName))

	Citizen.CreateThread(function()
		if not HasModelLoaded(model) then
            RequestModel(model)
    
            while not HasModelLoaded(model) do
                Wait(1)
            end
        end

		local vehicle = CreateVehicle(model, coords.x, coords.y, coords.z, heading, true, false)
		local id = NetworkGetNetworkIdFromEntity(vehicle)

		SetNetworkIdCanMigrate(id, true)
		SetEntityAsMissionEntity(vehicle, true, false)
		SetVehicleHasBeenOwnedByPlayer(vehicle, true)
		SetVehicleNeedsToBeHotwired(vehicle, false)
		SetModelAsNoLongerNeeded(model)
        SetPedIntoVehicle(ped, vehicle, -1)

		RequestCollisionAtCoord(coords.x, coords.y, coords.z)

		while not HasCollisionLoadedAroundEntity(vehicle) do
			RequestCollisionAtCoord(coords.x, coords.y, coords.z)
			Wait(1)
		end

		SetVehRadioStation(vehicle, 'OFF')
	end)
end

AddEventHandler('onResourceStop', function(resName)
    if GetCurrentResourceName() == resName then
        ESX.UI.Menu.Close('default', GetCurrentResourceName(), 'fgs_bikemenu')
    end
end)