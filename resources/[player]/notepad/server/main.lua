local QBCore = exports['qbx_core']:GetCoreObject()

lib.callback.register('notepad:server:getNotes', function(source)
    local p = QBCore.Functions.GetPlayer(source)
    if not p then return {} end
    local cid = p.PlayerData.citizenid
    local rows = MySQL.query.await('SELECT id, title, content, created_at, updated_at FROM player_notes WHERE citizenid = ? ORDER BY updated_at DESC', { cid })
    return rows or {}
end)

RegisterNetEvent('notepad:server:saveNote', function(title, content)
    local src = source
    local p = QBCore.Functions.GetPlayer(src)
    if not p then return end
    local cid = p.PlayerData.citizenid
    MySQL.insert('INSERT INTO player_notes (citizenid, title, content) VALUES (?, ?, ?)', { cid, title, content })
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Note saved' })
end)

RegisterNetEvent('notepad:server:deleteNote', function(noteId)
    local src = source
    local p = QBCore.Functions.GetPlayer(src)
    if not p then return end
    local cid = p.PlayerData.citizenid
    MySQL.query('DELETE FROM player_notes WHERE id = ? AND citizenid = ?', { noteId, cid })
    TriggerClientEvent('ox_lib:notify', src, { type = 'info', description = 'Note deleted' })
end)
