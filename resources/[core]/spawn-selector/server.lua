local QBox = exports['qbx_core']:GetCoreObject()

-- Minimal server callback for spawn system
lib.callback.register('qb-spawn:server:getOwnedHouses', function(_, cid)
    if cid then
        return MySQL.query.await('SELECT house FROM player_houses WHERE citizenid = ?', { cid })
    end
    return {}
end)