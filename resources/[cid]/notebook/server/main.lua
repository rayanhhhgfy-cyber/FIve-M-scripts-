local QBox = exports['qbx-core']:GetCoreObject()

local RATE_LIMITS = {}
local function checkRateLimit(src, a, m)
    local k = src .. ':' .. a; local n = os.time()
    RATE_LIMITS[k] = RATE_LIMITS[k] or {}; table.insert(RATE_LIMITS[k], n)
    for i = #RATE_LIMITS[k], 1, -1 do if n - RATE_LIMITS[k][i] > 60 then table.remove(RATE_LIMITS[k], i) end end
    return #RATE_LIMITS[k] <= m
end

RegisterNetEvent('notebook:server:getNotes', function()
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    MySQL.query('SELECT * FROM cid_notebook WHERE citizenid = ? OR id IN (SELECT note_id FROM notebook_shares WHERE target_citizenid = ?) ORDER BY updated_at DESC',
        { p.PlayerData.citizenid, p.PlayerData.citizenid }, function(r)
        TriggerClientEvent('notebook:client:showNotes', src, r or {})
    end)
end)

RegisterNetEvent('notebook:server:createNote', function(title, content, category, caseId)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    if not checkRateLimit(src, 'createNote', 30) then return end
    MySQL.insert('INSERT INTO cid_notebook (citizenid, title, content, category, case_id, created_at, updated_at) VALUES (?, ?, ?, ?, ?, NOW(), NOW())',
        { p.PlayerData.citizenid, title, content, category, caseId or nil }, function(id)
        TriggerClientEvent('Wrappers:Notify', src, Locale('cid.note_created'), 'success')
        exports['discord-logs']:LogCustom(src, 'Notebook Note', 'Created: ' .. title)
    end)
end)

RegisterNetEvent('notebook:server:updateNote', function(noteId, title, content, category)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    MySQL.update('UPDATE cid_notebook SET title = ?, content = ?, category = ?, updated_at = NOW() WHERE id = ? AND citizenid = ?',
        { title, content, category, noteId, p.PlayerData.citizenid }, function()
        Wrappers.Notify(src, Locale('cid.note_updated'), 'success')
    end)
end)

RegisterNetEvent('notebook:server:deleteNote', function(noteId)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    MySQL.update('DELETE FROM cid_notebook WHERE id = ? AND citizenid = ?', { noteId, p.PlayerData.citizenid })
    MySQL.update('DELETE FROM notebook_shares WHERE note_id = ?', { noteId })
    Wrappers.Notify(src, Locale('cid.note_deleted'), 'success')
end)

RegisterNetEvent('notebook:server:shareNote', function(noteId, targetCitizenId)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    MySQL.query('SELECT * FROM cid_notebook WHERE id = ? AND citizenid = ?', { noteId, p.PlayerData.citizenid }, function(r)
        if not r or #r == 0 then Wrappers.Notify(src, Locale('cid.note_not_found'), 'error') return end
        MySQL.query('SELECT * FROM notebook_shares WHERE note_id = ? AND target_citizenid = ?', { noteId, targetCitizenId }, function(existing)
            if existing and #existing > 0 then Wrappers.Notify(src, Locale('cid.already_shared'), 'info') return end
            MySQL.insert('INSERT INTO notebook_shares (note_id, owner_citizenid, target_citizenid) VALUES (?, ?, ?)',
                { noteId, p.PlayerData.citizenid, targetCitizenId })
            Wrappers.Notify(src, Locale('cid.note_shared'), 'success')
            local target = QBox.Functions.GetPlayerByCitizenId(targetCitizenId)
            if target then
                TriggerClientEvent('Wrappers:Notify', target.PlayerData.source, Locale('cid.note_shared_with_you'), 'info')
            end
        end)
    end)
end)

RegisterNetEvent('notebook:server:searchNotes', function(term)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    MySQL.query('SELECT * FROM cid_notebook WHERE (citizenid = ? OR id IN (SELECT note_id FROM notebook_shares WHERE target_citizenid = ?)) AND (title LIKE ? OR content LIKE ?) ORDER BY updated_at DESC',
        { p.PlayerData.citizenid, p.PlayerData.citizenid, '%' .. term .. '%', '%' .. term .. '%' }, function(r)
        TriggerClientEvent('notebook:client:searchResults', src, r or {})
    end)
end)
