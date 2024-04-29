local Config = require 'shared.qbx_pefcl'

addCash = function(src, amount)
	exports.ox_inventory:addCash(src, amount)
end

removeCash = function(src, amount)
	exports.ox_inventory:removeCash(src, amount)
end

getCash = function(src)
	return exports.ox_inventory:getCash(src) or 0
end

loadPlayer = function(src, citizenid, name)
	exports.pefcl:loadPlayer(src, {
		source = src,
		identifier = citizenid,
		name = name
	})
end

UniqueAccounts = function(player)
	local citizenid = player.PlayerData.citizenid
	local playerSrc = player.PlayerData.source
	local PlayerJob = player.PlayerData.job
	if Config.BusinessAccounts[PlayerJob.name] then
		if not exports.pefcl:getUniqueAccount(playerSrc, PlayerJob.name).data then
			local data = {
				name = tostring(Config.BusinessAccounts[PlayerJob.name].AccountName),
				type = 'shared',
				identifier = PlayerJob.name
			}
			exports.pefcl:createUniqueAccount(playerSrc, data)
		end
	end
	local accounts = exports.pefcl:getAccounts(playerSrc).data
	for k, v in pairs(accounts) do
		if Config.BusinessAccounts[v.ownerIdentifier] and v.ownerIdentifier == PlayerJob.name then
			local role = false
			if PlayerJob.grade.level >= Config.BusinessAccounts[v.ownerIdentifier].AdminRole then
				role = 'admin'
			elseif PlayerJob.grade.level >= Config.BusinessAccounts[v.ownerIdentifier].ContributorRole then
				role = 'contributor'
			end
			if not role then
				local data1 = {
					userIdentifier = citizenid,
					accountIdentifier = v.ownerIdentifier,
				}
				exports.pefcl:removeUserFromUniqueAccount(playerSrc, data1)
			elseif v.role ~= role then
				local data1 = {
					userIdentifier = citizenid,
					accountIdentifier = v.ownerIdentifier,
				}
				exports.pefcl:removeUserFromUniqueAccount(playerSrc, data1)
				if Config.BusinessAccounts[PlayerJob.name] then
					local role = false
					if PlayerJob.grade.level >= Config.BusinessAccounts[PlayerJob.name].AdminRole then
						role = 'admin'
					elseif PlayerJob.grade.level >= Config.BusinessAccounts[PlayerJob.name].ContributorRole then
						role = 'contributor'
					end
					if role then
						local data = {
							role = role,
							accountIdentifier = PlayerJob.name,
							userIdentifier = citizenid,
							source = playerSrc
						}
						exports.pefcl:addUserToUniqueAccount(playerSrc, data)
					end
				end
			end
		elseif Config.BusinessAccounts[v.ownerIdentifier] and v.ownerIdentifier ~= PlayerJob.name then
			local data1 = {
				userIdentifier = citizenid,
				accountIdentifier = v.ownerIdentifier,
			}
			exports.pefcl:removeUserFromUniqueAccount(playerSrc, data1)
		elseif Config.BusinessAccounts[PlayerJob.name] and v.ownerIdentifier ~= PlayerJob.name and v.type == 'shared' then
			local data1 = {
				userIdentifier = citizenid,
				accountIdentifier = v.ownerIdentifier,
			}
			exports.pefcl:removeUserFromUniqueAccount(playerSrc, data1)
			if Config.BusinessAccounts[PlayerJob.name] then
				local role = false
				if PlayerJob.grade.level >= Config.BusinessAccounts[PlayerJob.name].AdminRole then
					role = 'admin'
				elseif PlayerJob.grade.level >= Config.BusinessAccounts[PlayerJob.name].ContributorRole then
					role = 'contributor'
				end
				if role then
					local data = {
						role = role,
						accountIdentifier = PlayerJob.name,
						userIdentifier = citizenid,
						source = playerSrc
					}
					exports.pefcl:addUserToUniqueAccount(playerSrc, data)
				end
			end
		end
	end
end

lib.addCommand('bill', {
	help = 'Bill A Player',
	params = {
		{ name = 'id',      help = 'Player ID' },
		{ name = 'amount',  help = 'Bill Amount' },
		{ name = 'message', help = 'Message' }
	},
}, function(source, args)
	local biller = exports.qbx_core:GetPlayer(source)
	local billed = exports.qbx_core:GetPlayer(tonumber(args[1]))
	local billerJobName = biller.PlayerData.job.name
	local amount = math.ceil(tonumber(args[2]))
	local message = args[3]
	if not Config.BusinessAccounts[billerJobName] then
		TriggerClientEvent('ox_lib:notify', source, 'No Access', 'error')
	end
	if not billed then
		TriggerClientEvent('ox_lib:Notify', source, 'Player Not Online', 'error')
	end
	if biller.PlayerData.citizenid == billed.PlayerData.citizenid then
		TriggerClientEvent('ox_lib:notify', source, 'You Cannot Bill Yourself', 'error')
	end
	if not amount or amount <= 0 then
		TriggerClientEvent('ox_lib:notify', source, 'Must Be A Valid Amount Above 0', 'error')
	end
	exports.pefcl:createInvoice(-1, {
		to = billed.PlayerData.charinfo.firstname .. billed.PlayerData.charinfo.lastname,
		toIdentifier = billed.PlayerData.citizenid,
		from = tostring(Config.BusinessAccounts[billerJobName].AccountName),
		fromIdentifier = biller.PlayerData.citizenid,
		amount = amount,
		message = message,
		receiverAccountIdentifier = billerJobName
	})
	TriggerClientEvent('ox_lib:notify', source, 'Invoice Successfully Sent', 'success')
	TriggerClientEvent('ox_lib:notify', billed.PlayerData.source, 'New Invoice Received')
end)

getCards = function(src)
	local retval = {}
	local cards = exports.ox_inventory:Search(src, 'slots', 'visa')
	for _, v in pairs(cards) do
		retval[#retval + 1] = {
			id = v.metadata.id,
			holder = v.metadata.holder,
			number = v.metadata.number
		}
	end
	return retval
end

giveCard = function(src, card)
	exports.ox_inventory:AddItem(src, 'visa', 1, {
		id = card.id,
		holder = card.holder,
		number = card.number,
		description = ('Card Number: %s'):format(card.number)
	})
end

getBank = function(source)
	local Player = exports.qbx_core:GetPlayer(source)
	return Player.PlayerData.money.bank or 0
end

GetAccount = function(account)
	if exports.pefcl:getUniqueAccount(-1, account).data then
		return exports.pefcl:getBankBalanceByIdentifier(-1, account).data
	else
		return false
	end
end
exports('GetAccount', GetAccount)

AddMoney = function(src, account, amount, reason)
	if exports.pefcl:getUniqueAccount(src, account).data then
		local data = {
			identifier = account,
			amount = amount,
			description = reason
		}
		exports.pefcl:addBankBalanceByIdentifier(src, data)
		return true
	else
		return false
	end
end
exports('AddMoney', AddMoney)

RemoveMoney = function(account, amount, reason)
	if exports.pefcl:getUniqueAccount(-1, account).data then
		if tonumber(exports.pefcl:getBankBalanceByIdentifier(-1, account).data) >= amount then
			local data = {
				identifier = account,
				amount = amount,
				message = reason
			}
			exports.pefcl:removeBankBalanceByIdentifier(-1, data)
			return true
		else
			return false
		end
	else
		return false
	end
end
exports('RemoveMoney', RemoveMoney)

local eventHandlers = {
	{'__cfx_export_qbx_management_AddMoney', AddMoney},
	{'__cfx_export_qbx_management_RemoveMoney', RemoveMoney},
	{'__cfx_export_qbx_management_GetAccount', GetAccount},
	{'__cfx_export_qb_management_AddMoney', AddMoney},
	{'__cfx_export_qb_management_RemoveMoney', RemoveMoney},
	{'__cfx_export_qb_management_GetAccount', GetAccount},
	{'__cfx_export_Renewed-Banking_addAccountMoney', AddMoney},
	{'__cfx_export_Renewed-Banking_removeAccountMoney', RemoveMoney},
	{'__cfx_export_Renewed-Banking_getAccountMoney', GetAccount}
}
for _, eventHandler in ipairs(eventHandlers) do
	local eventName, callback = table.unpack(eventHandler)
	AddEventHandler(eventName, function(setCB)
		setCB(callback)
	end)
end

exports('getBank', getBank)
exports('addCash', addCash)
exports('removeCash', removeCash)
exports('getCash', getCash)
exports('giveCard', giveCard)
exports('getCards', getCards)

onMoneyChange = function(playerSrc, moneyType, amount, action, reason)
    if moneyType == 'bank' then
        local data = {
            amount = amount,
            message = reason
        }
        if action == 'add' then
            exports.pefcl:addBankBalance(playerSrc, data)
        elseif action == 'remove' then
            exports.pefcl:removeBankBalance(playerSrc, data)
        elseif action == 'set' then
            exports.pefcl:setBankBalance(playerSrc, data)
        end
    end
end
AddEventHandler('QBCore:Server:OnMoneyChange', onMoneyChange)

AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
	if not player then return end
	local citizenid = player.PlayerData.citizenid
    local charInfo = player.PlayerData.charinfo
	local playerSrc = player.PlayerData.source
    loadPlayer(playerSrc, citizenid, charInfo.firstname .. ' ' .. charInfo.lastname)
	UniqueAccounts(player)
    SyncMoney(player)
end)

RegisterNetEvent('qbx_pefcl:server:UnloadPlayer', function()
	exports.pefcl:unloadPlayer(source)
end)

RegisterNetEvent('qbx_pefcl:server:SyncMoney', function()
	local player = exports.qbx_core:GetPlayer(source)
	SyncMoney(player)
end)

RegisterNetEvent('qbx_pefcl:server:OnJobUpdate', function(oldJob)
	local player = exports.qbx_core:GetPlayer(source)
	UniqueAccounts(player)
	SyncMoney(player)
end)

AddEventHandler('onServerResourceStart', function(resourceName)
	if resourceName ~= GetCurrentResourceName() then return end
	local players = exports.qbx_core:GetQBPlayers()
	if not players or players == nil then
		print("Error: Unable to load player data. If there are no players currently on the server, you may ignore this message.")
		return
	end
	for _, v in pairs(players) do
		loadPlayer(v.PlayerData.source, v.PlayerData.citizenid, v.PlayerData.charinfo.firstname .. ' ' .. v.PlayerData.charinfo.lastname)
		UniqueAccounts(v)
		SyncMoney(v)
	end
end)
