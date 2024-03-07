local currentJob = {}

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    currentJob = QBX.PlayerData.job
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
	TriggerServerEvent('qbx_pefcl:server:UnloadPlayer')
end)

RegisterNetEvent('pefcl:newDefaultAccountBalance', function(balance)
	TriggerServerEvent('qbx_pefcl:server:SyncMoney')
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(newJob)
	TriggerServerEvent('qbx_pefcl:server:OnJobUpdate', currentJob)
	currentJob = newJob
end)
