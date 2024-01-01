<h2 align="center">qbx_pefcl</h2>

This compatibility resource enables PEFCL to function properly with QBOX.

## Installation Steps:

1. Download this repository and place it in the `resources` directory.
2. Add `ensure qbx_pefcl` to your `server.cfg` before pefcl.
3. Navigate to the `config.json` in `PEFCL` and make the following changes:

    - Under `frameworkIntegration`:
        - `enabled`: `true`
        - `resource`: `qbx_pefcl`

    - Under `target`:
        - `type`: `"qtarget"`
        - `enabled`: `true`

4. Navigate to `qbx_core\server\player.lua` and replace the following functions:

    - `self.Functions.AddMoney`:

    ```lua
    function self.Functions.AddMoney(moneytype, amount, reason)
        reason = reason or 'unknown'
        moneytype = moneytype:lower()
        amount = tonumber(amount)
        if amount < 0 then return end
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
            TriggerClientEvent('qbx-hud:client:OnMoneyChange', self.PlayerData.source, moneytype, amount, false)
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
        moneytype = moneytype:lower()
        amount = tonumber(amount)
        if amount < 0 then return end
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
            TriggerClientEvent('qbx-hud:client:OnMoneyChange', self.PlayerData.source, moneytype, amount, true)
            if moneytype == 'bank' then
                TriggerClientEvent('qbx-phone:client:RemoveBankMoney', self.PlayerData.source, amount)
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
        moneytype = moneytype:lower()
        amount = tonumber(amount)
        if amount < 0 then return false end
        if moneytype == 'bank' then
            local data = {}
            data.amount = amount
            exports.pefcl:setBankBalance(self.PlayerData.source, data)
            self.PlayerData.money[moneytype] = exports.pefcl:getDefaultAccountBalance(self.PlayerData.source).data or 0
        else
            if not self.PlayerData.money[moneytype] then return false end
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
        moneytype = moneytype:lower()
        if moneytype == 'bank' then
            self.PlayerData.money[moneytype] = exports.pefcl:getDefaultAccountBalance(self.PlayerData.source).data or 0
            return exports.pefcl:getDefaultAccountBalance(self.PlayerData.source).data
        end
        return self.PlayerData.money[moneytype]
    end
    ```

5. Additionally, add the following function to `qbx_core\server\player.lua`:

    ```lua
    function self.Functions.SyncMoney() 
        local money = exports.pefcl:getDefaultAccountBalance(self.PlayerData.source).data
        if money then
            self.PlayerData.money['bank'] = money
        end
        if not self.Offline then
            self.Functions.UpdatePlayerData()
        end
    end
    ```

Feel free to replace the comments with the actual code modifications for better clarity. If you have any questions or need further assistance, please let me know!
