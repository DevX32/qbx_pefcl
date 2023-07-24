local QBCore = exports['qbx-core']:GetCoreObject()
local currentJob = {}

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    QBCore.Functions.GetPlayerData(function(PlayerData) 
		currentJob = PlayerData.job
    end)
end)

RegisterNetEvent("QBCore:Client:OnPlayerUnload", function()
	TriggerServerEvent("qbx-pefcl:server:UnloadPlayer")
end)

RegisterNetEvent("pefcl:newDefaultAccountBalance", function(balance)
	TriggerServerEvent("qbx-pefcl:server:SyncMoney")
end)

RegisterNetEvent("QBCore:Client:OnJobUpdate", function(newJob)
	TriggerServerEvent("qbx-pefcl:server:OnJobUpdate", currentJob)
	currentJob = newJob
end)