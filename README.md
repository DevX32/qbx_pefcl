<h2 align="center">qbx_pefcl</h2>
This Compatibility Resource Enables PEFCL To Function Properly With QBOX.

## Installation Steps:

1. Download This Repository And Place It In The `resources` Directory.
2. Add `ensure qbx_pefcl` To Your `server.cfg` Before Pefcl.
3. Navigate To The `config.json` In `PEFCL` And Make The Following Changes:

    - Under `Framework Integration`:
        - `enabled`: `true`
        - `resource`: `qbx_pefcl`

    - Under `Target`:
        - `type`: `"qtarget"`
        - `enabled`: `true`

4. Navigate To `qbx_core\server\player.lua` And Replace The Following Functions:

    - `self.Functions.AddMoney`:

    ```lua
    function self.Functions.AddMoney(moneytype, amount, reason)
        reason = reason or 'unknown'
        amount = qbx.math.round(tonumber(amount)) --[[@as number]]
        if amount < 0 then return false end
        if moneytype == 'bank' then
            local data = {}
            data.amount = amount
            data.message = reason
            exports.pefcl:addBankBalance(self.PlayerData.source, data)
        else
            if not self.PlayerData.money[moneytype] then return false end
            self.PlayerData.money[moneytype] = self.PlayerData.money[moneytype] + amount
        end
        if not self.Offline then
            self.Functions.UpdatePlayerData()
            local tags = amount > 100000 and config.logging.role or nil
            logger.log({
                source = 'qbx_core',
                webhook = config.logging.webhook['playermoney'],
                event = 'AddMoney',
                color = 'lightgreen',
                tags = tags,
                message = '**' .. GetPlayerName(self.PlayerData.source) .. ' (citizenid: ' .. self.PlayerData.citizenid .. ' | id: ' .. self.PlayerData.source .. ')** $' .. amount .. ' (' .. moneytype .. ') added, new ' .. moneytype .. ' balance: ' .. self.PlayerData.money[moneytype] .. ' reason: ' .. reason,
            })
            TriggerClientEvent('qbx_hud:client:OnMoneyChange', self.PlayerData.source, moneytype, amount, false)
            TriggerClientEvent('QBCore:Client:OnMoneyChange', self.PlayerData.source, moneytype, amount, "add", reason)
            TriggerEvent('QBCore:Server:OnMoneyChange', self.PlayerData.source, moneytype, amount, "add", reason)
        end
        return true
    end
    ```

    - `self.Functions.RemoveMoney`:

    ```lua
    function self.Functions.RemoveMoney(moneytype, amount, reason)
        reason = reason or 'unknown'
        amount = qbx.math.round(tonumber(amount)) --[[@as number]]
        if amount < 0 then return false end
        if not self.PlayerData.money[moneytype] then return false end
        for _, mtype in pairs(config.money.dontAllowMinus) do
            if mtype == moneytype then
                if (self.PlayerData.money[moneytype] - amount) < 0 then
                    return false
                end
            end
            if moneytype == 'bank' then
                if (exports.pefcl:getDefaultAccountBalance(self.PlayerData.source).data - amount) < 0 then
                    return false
                end
            end
        end
        if moneytype == 'bank' then
            local data = {}
            data.amount = amount
            data.message = reason
            exports.pefcl:removeBankBalance(self.PlayerData.source, data)
        else
            self.PlayerData.money[moneytype] = self.PlayerData.money[moneytype] - amount
        end
        if not self.Offline then
            self.Functions.UpdatePlayerData()
            local tags = amount > 100000 and config.logging.role or nil
            logger.log({
                source = 'qbx_core',
                webhook = config.logging.webhook['playermoney'],
                event = 'RemoveMoney',
                color = 'red',
                tags = tags,
                message = '**' .. GetPlayerName(self.PlayerData.source) .. ' (citizenid: ' .. self.PlayerData.citizenid .. ' | id: ' .. self.PlayerData.source .. ')** $' .. amount .. ' (' .. moneytype .. ') removed, new ' .. moneytype .. ' balance: ' .. self.PlayerData.money[moneytype] .. ' reason: ' .. reason,
            })
            TriggerClientEvent('qbx_hud:client:OnMoneyChange', self.PlayerData.source, moneytype, amount, true)
            if moneytype == 'bank' then
                TriggerClientEvent('qbx_phone:client:RemoveBankMoney', self.PlayerData.source, amount)
            end
            TriggerClientEvent('QBCore:Client:OnMoneyChange', self.PlayerData.source, moneytype, amount, "remove", reason)
            TriggerEvent('QBCore:Server:OnMoneyChange', self.PlayerData.source, moneytype, amount, "remove", reason)
        end
        return true
    end
    ```

    - `self.Functions.SetMoney`:

    ```lua
    function self.Functions.SetMoney(moneytype, amount, reason)
        reason = reason or 'unknown'
        amount = qbx.math.round(tonumber(amount)) --[[@as number]]
        if moneytype == 'bank' then
            local data = {}
            data.amount = amount
            exports.pefcl:setBankBalance(self.PlayerData.source, data)
            self.PlayerData.money[moneytype] = exports.pefcl:getDefaultAccountBalance(self.PlayerData.source).data or 0
        else
            if not self.PlayerData.money[moneytype] then return false end
            local difference = amount - self.PlayerData.money[moneytype]
            self.PlayerData.money[moneytype] = amount
        end

        if not self.Offline then
            self.Functions.UpdatePlayerData()
            logger.log({
                source = 'qbx_core',
                webhook = config.logging.webhook['playermoney'],
                event = 'SetMoney',
                color = 'green',
                message = '**' .. GetPlayerName(self.PlayerData.source) .. ' (citizenid: ' .. self.PlayerData.citizenid .. ' | id: ' .. self.PlayerData.source .. ')** $' .. amount .. ' (' .. moneytype .. ') set, new ' .. moneytype .. ' balance: ' .. self.PlayerData.money[moneytype] .. ' reason: ' .. reason,
            })
            TriggerClientEvent('hud:client:OnMoneyChange', self.PlayerData.source, moneytype, math.abs(difference), difference < 0)
            TriggerClientEvent('QBCore:Client:OnMoneyChange', self.PlayerData.source, moneytype, amount, "set", reason)
            TriggerEvent('QBCore:Server:OnMoneyChange', self.PlayerData.source, moneytype, amount, "set", reason)
        end
        return true
    end
    ```

    - `self.Functions.GetMoney`:

    ```lua
    function self.Functions.GetMoney(moneytype)
        if not moneytype then return false end
        if moneytype == 'bank' then
            self.PlayerData.money[moneytype] = exports.pefcl:getDefaultAccountBalance(self.PlayerData.source).data or 0
            return exports.pefcl:getDefaultAccountBalance(self.PlayerData.source).data
        end
        return self.PlayerData.money[moneytype]
    end
    ```

5. Additionally, Add The Following Function To `qbx_core\server\player.lua`:

    ```lua
    function self.Functions.SyncMoney() 
        local money = exports.pefcl:getDefaultAccountBalance(self.PlayerData.source).data
        if money then
            self.PlayerData.money.bank = money
        end
        if not self.Offline then
            self.Functions.UpdatePlayerData()
        end
    end
    ```
6. Change Renewed Banking Exports If You Have Old qbx_management Without Renewed Exports, `qbx_core\config\server.lua`:
   ```lua
    getSocietyAccount = function(accountName)
        return exports.qbx_management:GetAccount(accountName)
    end,

    removeSocietyMoney = function(accountName, payment)
        return exports.qbx_management:RemoveMoney(accountName, payment)
    end
   ```
- Update Event Handlers In `qbx_pefcl/server.lua` To Adapt To Banking Exports Changes:
- - - - - - - - - - - -
Feel free to replace the comments with the actual code modifications for better clarity. If you have any questions or need further assistance, please let me know!
