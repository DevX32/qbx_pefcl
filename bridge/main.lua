local logger = require '@qbx_core.modules.logger'
local config = require '@qbx_core.config.server'
local Bridge = {}

AddMoney = function(player, moneytype, amount, reason)
    reason = reason or 'unknown'
    moneytype = moneytype:lower()
    amount = qbx.math.round(tonumber(amount)) --[[@as number]]
    if amount < 0 then return false end
    if moneytype == 'bank' then
        local data = {}
        data.amount = amount
        data.message = reason
        exports.pefcl:addBankBalance(player.source, data)
    else
        if not player.money[moneytype] then return false end
        player.money[moneytype] = player.money[moneytype] + amount
    end
    if not player.Offline then
        player.Functions.UpdatePlayerData()
        local tags = amount > 100000 and config.logging.role or nil
        logger.log({
            source = 'qbx_pefcl',
            webhook = config.logging.webhook['playermoney'],
            event = 'AddMoney',
            color = 'lightgreen',
            tags = tags,
            message = ('**%s (citizenid: %s | id: %s)** $%s (%s) added, new %s balance: $%s reason: %s'):format(GetPlayerName(player.PlayerData.source), player.PlayerData.citizenid, player.PlayerData.source, amount, moneytype, moneytype, player.PlayerData.money[moneytype], reason),
        })
        TriggerClientEvent('hud:client:OnMoneyChange', player.source, moneytype, amount, false)
        TriggerClientEvent('QBCore:Client:OnMoneyChange', player.source, moneytype, amount, "add", reason)
        TriggerEvent('QBCore:Server:OnMoneyChange', player.source, moneytype, amount, "add", reason)
    end
    return true
end

RemoveMoney = function(player, moneytype, amount, reason)
    reason = reason or 'unknown'
    moneytype = moneytype:lower()
    amount = qbx.math.round(tonumber(amount)) --[[@as number]]
    if amount < 0 then return false end
    if not player.money[moneytype] then return false end
    for _, mtype in pairs(config.money.dontAllowMinus) do
        if mtype == moneytype then
            if (player.money[moneytype] - amount) < 0 then
                return false
            end
        end
        if moneytype == 'bank' then
            if (exports.pefcl:getDefaultAccountBalance(player.source).data - amount) < 0 then
                return false
            end
        end
    end
    if moneytype == 'bank' then
        local data = {}
        data.amount = amount
        data.message = reason
        exports.pefcl:removeBankBalance(player.source, data)
    else
        player.money[moneytype] = player.money[moneytype] - amount
    end
    if not player.Offline then
        player.Functions.UpdatePlayerData()
        local tags = amount > 100000 and config.logging.role or nil
        logger.log({
            source = 'qbx_pefcl',
            webhook = config.logging.webhook['playermoney'],
            event = 'RemoveMoney',
            color = 'red',
            tags = tags,
            message = ('** %s (citizenid: %s | id: %s)** $%s (%s) removed, new %s balance: $%s reason: %s'):format(GetPlayerName(player.PlayerData.source), player.PlayerData.citizenid, player.PlayerData.source, amount, moneytype, moneytype, player.PlayerData.money[moneytype], reason),
        })
        TriggerClientEvent('hud:client:OnMoneyChange', player.source, moneytype, amount, true)
        if moneytype == 'bank' then
            TriggerClientEvent('qbx_phone:client:RemoveBankMoney', player.source, amount)
        end
        TriggerClientEvent('QBCore:Client:OnMoneyChange', player.source, moneytype, amount, "remove", reason)
        TriggerEvent('QBCore:Server:OnMoneyChange', player.source, moneytype, amount, "remove", reason)
    end
    return true
end

SetMoney = function(player, moneytype, amount, reason)
    reason = reason or 'unknown'
    moneytype = moneytype:lower()
    amount = qbx.math.round(tonumber(amount)) --[[@as number]]
    if amount < 0 then return false end
    if moneytype == 'bank' then
        local data = {}
        data.amount = amount
        exports.pefcl:setBankBalance(player.source, data)
        player.money[moneytype] = exports.pefcl:getDefaultAccountBalance(player.source).data or 0
    else
        if not player.money[moneytype] then return false end
        player.money[moneytype] = amount
    end
    if not player.Offline then
        player.Functions.UpdatePlayerData()
        logger.log({
            source = 'qbx_pefcl',
            webhook = config.logging.webhook['playermoney'],
            event = 'SetMoney',
            color = 'green',
            message = ('**%s (citizenid: %s | id: %s)** $%s (%s) set, new %s balance: $%s reason: %s'):format(GetPlayerName(player.PlayerData.source), player.PlayerData.citizenid, player.PlayerData.source, amount, moneytype, moneytype, player.PlayerData.money[moneytype], reason),
        })
        TriggerClientEvent('QBCore:Client:OnMoneyChange', player.source, moneytype, amount, "set", reason)
        TriggerEvent('QBCore:Server:OnMoneyChange', player.source, moneytype, amount, "set", reason)
    end
    return true
end

GetMoney = function(player, moneytype)
    if not moneytype then return false end
    moneytype = moneytype:lower()
    if moneytype == 'bank' then
        player.money[moneytype] = exports.pefcl:getDefaultAccountBalance(player.source).data or 0
        return exports.pefcl:getDefaultAccountBalance(player.source).data
    end
    return player.money[moneytype]
end

SyncMoney = function(player)
    local money = exports.pefcl:getDefaultAccountBalance(player.PlayerData.source).data
    if money then
        player.PlayerData.money.bank = money
    end
    if not player.Offline then
        player.Functions.UpdatePlayerData()
    end
end

return Bridge
