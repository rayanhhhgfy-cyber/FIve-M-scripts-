local QBox = exports['qbx_core']:GetCoreObject()

local function canUse(src)
    local p = QBox.Functions.GetPlayer(src)
    if not p then return false end
    for _, j in ipairs(Config.MDT.allowedJobs) do
        if p.PlayerData.job.name == j and p.PlayerData.job.onduty then return true end
    end
    return false
end

QBox.Functions.CreateCallback('mdt:plateSearch', function(source, cb, plate)
    if not canUse(source) then cb({ error = 'Unauthorized' }) return end
    if not plate or plate == '' then cb({ error = 'No plate provided' }) return end
    MySQL.query('SELECT * FROM players WHERE JSON_EXTRACT(charinfo, "$.plate") = ?', { plate }, function(rows)
        if rows and #rows > 0 then
            local charinfo = json.decode(rows[1].charinfo)
            cb({
                plate = plate,
                owner = (charinfo.firstname or '') .. ' ' .. (charinfo.lastname or ''),
                registered = true,
                stolen = false,
            })
        else
            cb({ plate = plate, owner = 'Unknown', registered = false, stolen = true })
        end
    end)
end)

QBox.Functions.CreateCallback('mdt:warrantSearch', function(source, cb, name)
    if not canUse(source) then cb({ error = 'Unauthorized' }) return end
    MySQL.query('SELECT * FROM player_warrants WHERE name LIKE ?', { '%' .. name .. '%' }, function(rows)
        if rows and #rows > 0 then
            cb({ warrants = rows, count = #rows })
        else
            cb({ warrants = {}, count = 0 })
        end
    end)
end)

RegisterNetEvent('mdt:submitReport', function(data)
    local src = source
    if not canUse(src) then return end
    local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    MySQL.insert('INSERT INTO mdt_reports (citizenid, title, content, time) VALUES (?, ?, ?, ?)',
        { p.PlayerData.citizenid, data.title or 'Report', data.content or '', os.time() })
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Report submitted' })
end)

MySQL.ready(function()
    MySQL.execute([[
        CREATE TABLE IF NOT EXISTS mdt_reports (
            id INT AUTO_INCREMENT PRIMARY KEY,
            citizenid VARCHAR(50),
            title VARCHAR(255),
            content TEXT,
            time INT
        )
    ]])
    MySQL.execute([[
        CREATE TABLE IF NOT EXISTS player_warrants (
            id INT AUTO_INCREMENT PRIMARY KEY,
            citizenid VARCHAR(50),
            name VARCHAR(100),
            reason TEXT,
            issued_by VARCHAR(100),
            active TINYINT DEFAULT 1,
            time INT
        )
    ]])
end)
