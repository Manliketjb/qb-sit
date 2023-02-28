local QBCore = exports['qb-core']:GetCoreObject()
local debugProps, sitting, lastPos, currentSitCoords, currentScenario, occupied = {}
local disableControls = false
local currentObj = nil

exports('sitting', function()
    return sitting
end)

Citizen.CreateThread(function()
	local waitT = 1
	while true do
		Citizen.Wait(waitT)
		if sitting then
			waitT = 1
			local playerPed = PlayerPedId()
			helpText(Config.GetUpText)
			if Config.setting then		
				if not IsPedUsingScenario(playerPed, currentScenario) then
					wakeup()
				end
			end
			if IsControlPressed(0, Config.GetUpKey) and IsInputDisabled(0) and IsPedOnFoot(playerPed) then
				wakeup()		
			end
		else 
			waitT = 500
		end
	end
end)

Citizen.CreateThread(function()
	local Sitables = {}

	for k, v in pairs(Config.Interactables) do
		--local model = GetHashKey(v)
		--Sitables[#Sitables + 1] = model
		--Citizen.Wait(100)
		exports['qb-target']:AddTargetModel(k, {
			options = {
				{
					event = "qb-Sit:Sit",
					icon = "fas fa-chair",
					label = "Use",
					entity = entity
				},
			},
			job = {"all"},
			distance = Config.MaxDistance
		})
	end
end)

RegisterNetEvent("qb-Sit:Sit", function(data)
	local playerPed = PlayerPedId()

	if Config.setting then
		if sitting and not IsPedUsingScenario(playerPed, currentScenario) then
			wakeup()
		end
	end

	if disableControls then
		DisableControlAction(1, 37, true)
	end

	local object, distance = data.entity, #(GetEntityCoords(playerPed) - GetEntityCoords(data.entity))

	if distance and distance < Config.MaxDistance then
		local hash = GetEntityModel(object)

		for k, v in pairs(Config.Interactables) do
			if GetHashKey(k) == hash then
				sit(object, k, v)
				break
			end
		end
	end
end)


function wakeup()
	local playerPed = PlayerPedId()
	local pos = GetEntityCoords(playerPed)

	if Config.setting then
		TaskStartScenarioAtPosition(playerPed, currentScenario, 0.0, 0.0, 0.0, 180.0, 2, true, false)
		while IsPedUsingScenario(playerPed, currentScenario) do
			Citizen.Wait(100)
		end
		ClearPedTasks(playerPed)
	else
		TriggerEvent('animations:client:EmoteCommandStart', {"c"})
	end


	FreezeEntityPosition(playerPed, false)
	FreezeEntityPosition(currentObj, false)
	TriggerServerEvent('qb-sit:leavePlace', currentSitCoords)
	currentSitCoords, currentScenario = nil, nil
	sitting = false
	disableControls = false
end

function sit(object, modelName, data)
	if not HasEntityClearLosToEntity(PlayerPedId(), object, 17) then
		return
	end
	disableControls = true
	currentObj = object
	FreezeEntityPosition(object, true)

	PlaceObjectOnGroundProperly(object)
	local pos = GetEntityCoords(object)
	local playerPos = GetEntityCoords(PlayerPedId())
	local objectCoords = pos.x .. pos.y .. pos.z

	QBCore.Functions.TriggerCallback('qb-sit:getPlace', function(occupied)
		if occupied then
			QBCore.Functions.Notify('Chair is being used.', 'error')
		else
			local playerPed = PlayerPedId()
			lastPos, currentSitCoords = GetEntityCoords(playerPed), objectCoords

			TriggerServerEvent('qb-sit:takePlace', objectCoords)
			
			currentScenario = data.scenario
			if Config.setting then
				TaskStartScenarioAtPosition(playerPed, currentScenario, pos.x, pos.y, pos.z + (playerPos.z - pos.z)/2, GetEntityHeading(object) + 180.0, 0, true, false)
				Citizen.Wait(2500)
				if GetEntitySpeed(playerPed) > 0 then
					ClearPedTasks(playerPed)
					TaskStartScenarioAtPosition(playerPed, currentScenario, pos.x, pos.y, pos.z + (playerPos.z - pos.z)/2, GetEntityHeading(object) + 180.0, 0, true, true)
				end
			else
				local c = GetEntityCoords(object)
				local h = GetEntityHeading(object)
				local forward = GetEntityForwardVector(object)
				local x, y, z = table.unpack(c - forward * 0.5)
				local r = GetEntityRotation(object, 5)
				SetEntityCoords(playerPed, x, y, z - 1.03)
				SetEntityHeading(playerPed, r.x + 65)
				Citizen.Wait(1500)
				TriggerEvent('animations:client:EmoteCommandStart', {Config.dpemote})
			end
			sitting = true
		end
	end, objectCoords)
end

helpText = function(msg)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandDisplayHelp(0, false, false, -1)
end