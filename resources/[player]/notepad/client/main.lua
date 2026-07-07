local notepadOpen = false

function useNotepad()
    local hasPen = exports.ox_inventory:Search('count', 'pen')
    if not hasPen or hasPen < 1 then
        exports.ox_lib:notify({ type = 'error', description = 'You need a pen to write' })
        return
    end
    notepadOpen = true
    SetNuiFocus(true, true)
    local notes = lib.callback.await('notepad:server:getNotes', false)
    SendNUIMessage({ action = 'open', notes = notes or {} })
end

RegisterNUICallback('notepadSave', function(data, cb)
    if not data.title or not data.content then cb({ ok = false }) return end
    TriggerServerEvent('notepad:server:saveNote', data.title, data.content)
    cb({ ok = true })
end)

RegisterNUICallback('notepadDelete', function(data, cb)
    if not data.noteId then cb({ ok = false }) return end
    TriggerServerEvent('notepad:server:deleteNote', data.noteId)
    cb({ ok = true })
end)

RegisterNUICallback('notepadClose', function(_, cb)
    notepadOpen = false
    SetNuiFocus(false, false)
    cb({})
end)

RegisterNUICallback('notepadGetNotes', function(_, cb)
    local notes = lib.callback.await('notepad:server:getNotes', false)
    cb(notes or {})
end)

exports('useNotepad', useNotepad)
