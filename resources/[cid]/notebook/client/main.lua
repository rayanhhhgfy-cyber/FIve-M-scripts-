local QBox = exports['qbx-core']:GetCoreObject()
local playerData = {}
local notebookOpen = false
local currentNotes = {}
local currentNote = { id = nil, title = '', content = '', category = 'general', tags = {}, caseId = nil }

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function() playerData = QBox.Functions.GetPlayerData() end)
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(j) playerData.job = j end)

local function isCID() return playerData.job and (playerData.job.name == 'cid' or playerData.job.name == 'police') end
local function hasNotebook() return QBox.Functions.HasItem(Config.Notebook.ItemName) end

RegisterCommand('+notebook', function() TriggerEvent('notebook:toggle') end, false)
RegisterKeyMapping('+notebook', 'Open Investigation Notebook', 'keyboard', 'f5')

RegisterNetEvent('notebook:toggle', function()
    if not isCID() then Wrappers.Notify(Locale('cid.not_authorized'), 'error') return end
    if Config.Notebook.RequireItem and not hasNotebook() then Wrappers.Notify(Locale('cid.no_notebook'), 'error') return end
    notebookOpen = not notebookOpen
    if notebookOpen then
        TriggerServerEvent('notebook:server:getNotes')
    end
end)

RegisterNetEvent('notebook:client:showNotes', function(notes)
    currentNotes = notes or {}
    local items = {}
    for _, note in ipairs(currentNotes) do
        local cat = Config.Notebook.Categories[note.category] or Config.Notebook.Categories.general
        table.insert(items, {
            title = note.title,
            description = (cat and cat.label or 'General') .. ' | ' .. (note.content:sub(1, 50) or ''),
            onSelect = function() TriggerEvent('notebook:viewNote', note) end
        })
    end
    table.insert(items, { title = '---' })
    table.insert(items, { title = Locale('cid.new_note'), onSelect = function() TriggerEvent('notebook:createNote') end })
    table.insert(items, { title = Locale('cid.share_note'), onSelect = function() TriggerEvent('notebook:shareMenu') end })
    table.insert(items, { title = Locale('cid.search_notes'), onSelect = function() TriggerEvent('notebook:search') end })
    Wrappers.ContextMenu({ id = 'notebook_menu', title = Locale('cid.notebook'), menuItems = items })
end)

RegisterNetEvent('notebook:viewNote', function(note)
    local cat = Config.Notebook.Categories[note.category] or Config.Notebook.Categories.general
    local menuItems = {
        { title = Locale('cid.note_title') .. ': ' .. note.title, description = '' },
        { title = Locale('cid.note_content'), description = note.content },
        { title = Locale('cid.note_category') .. ': ' .. cat.label, description = '' },
        { title = Locale('cid.note_case') .. ': ' .. (note.case_id or 'None'), description = '' }
    }
    table.insert(menuItems, { title = Locale('cid.edit_note'), onSelect = function() TriggerEvent('notebook:editNote', note) end })
    table.insert(menuItems, { title = Locale('cid.delete_note'), onSelect = function()
        Wrappers.AlertDialog({ title = Locale('cid.delete_note'), content = note.title }, function(confirmed)
            if confirmed then TriggerServerEvent('notebook:server:deleteNote', note.id) end
        end)
    end})
    Wrappers.ContextMenu({ id = 'notebook_view', title = note.title, menuItems = menuItems })
end)

RegisterNetEvent('notebook:createNote', function()
    local catOptions = {}
    for catId, catData in pairs(Config.Notebook.Categories) do
        table.insert(catOptions, { value = catId, label = catData.label })
    end
    Wrappers.InputDialog({ title = Locale('cid.new_note'), inputs = {
        { type = 'input', label = Locale('cid.note_title'), name = 'title', required = true },
        { type = 'textarea', label = Locale('cid.note_content'), name = 'content', required = true, maxLength = Config.Notebook.MaxNoteLength },
        { type = 'select', label = Locale('cid.note_category'), name = 'category', options = catOptions, default = 'general' },
        { type = 'input', label = Locale('cid.case_id_optional'), name = 'caseId', required = false }
    }}, function(v)
        if v then TriggerServerEvent('notebook:server:createNote', v.title, v.content, v.category, v.caseId) end
    end)
end)

RegisterNetEvent('notebook:editNote', function(note)
    local catOptions = {}
    for catId, catData in pairs(Config.Notebook.Categories) do
        table.insert(catOptions, { value = catId, label = catData.label })
    end
    Wrappers.InputDialog({ title = Locale('cid.edit_note'), inputs = {
        { type = 'input', label = Locale('cid.note_title'), name = 'title', default = note.title, required = true },
        { type = 'textarea', label = Locale('cid.note_content'), name = 'content', default = note.content, required = true },
        { type = 'select', label = Locale('cid.note_category'), name = 'category', options = catOptions, default = note.category }
    }}, function(v)
        if v then TriggerServerEvent('notebook:server:updateNote', note.id, v.title, v.content, v.category) end
    end)
end)

RegisterNetEvent('notebook:shareMenu', function()
    Wrappers.InputDialog({ title = Locale('cid.share_note'), inputs = {
        { type = 'select', label = Locale('cid.select_note'), name = 'noteId', options = currentNotes and #currentNotes > 0 and (function()
            local opts = {}
            for i, n in ipairs(currentNotes) do table.insert(opts, { value = tostring(n.id), label = n.title }) end
            return opts
        end)() or {} },
        { type = 'input', label = Locale('cid.target_citizenid'), name = 'targetId', required = true }
    }}, function(v)
        if v then TriggerServerEvent('notebook:server:shareNote', tonumber(v.noteId), v.targetId) end
    end)
end)

RegisterNetEvent('notebook:search', function()
    Wrappers.InputDialog({ title = Locale('cid.search_notes'), inputs = {
        { type = 'input', label = Locale('cid.search_term'), name = 'term', required = true }
    }}, function(v)
        if v then TriggerServerEvent('notebook:server:searchNotes', v.term) end
    end)
end)

RegisterNetEvent('notebook:client:searchResults', function(results)
    local items = {}
    for _, note in ipairs(results or {}) do
        local cat = Config.Notebook.Categories[note.category] or Config.Notebook.Categories.general
        table.insert(items, { title = note.title, description = cat.label .. ' - ' .. note.content:sub(1, 50), onSelect = function() TriggerEvent('notebook:viewNote', note) end })
    end
    if #items == 0 then table.insert(items, { title = Locale('cid.no_results'), description = '' }) end
    Wrappers.ContextMenu({ id = 'notebook_search', title = Locale('cid.search_results'), menuItems = items })
end)
