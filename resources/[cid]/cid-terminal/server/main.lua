local QBox = exports['qbx_core']:GetCoreObject()

-----------------------------------------------------------------
-- HELPERS
-----------------------------------------------------------------
local function isOnDuty(src)
    local p = QBox.Functions.GetPlayer(src)
    if not p then return false end
    return p.PlayerData.job.onduty
end

local function hasAccess(src)
    local p = QBox.Functions.GetPlayer(src)
    if not p then return false end
    local job = p.PlayerData.job.name
    for _, j in ipairs(Config.CIDTerminal.allowedJobs) do
        if job == j then return true end
    end
    return false
end

local function canManage(src)
    local p = QBox.Functions.GetPlayer(src)
    if not p then return false end
    local job = p.PlayerData.job.name
    for _, j in ipairs(Config.CIDTerminal.manageJobs) do
        if job == j then return true end
    end
    return p.PlayerData.job.grade.level >= Config.CIDTerminal.minRankToManage
end

local function getPlayer(src)
    return QBox.Functions.GetPlayer(src)
end

local function logAction(src, action, details)
    local p = getPlayer(src)
    if not p then return end
    MySQL.insert('INSERT INTO cid_audit_log (action, target, performed_by_cid, performed_by_name, details) VALUES (?, ?, ?, ?, ?)', {
        action, details or 'none', p.PlayerData.citizenid, p.PlayerData.charinfo.firstname .. ' ' .. p.PlayerData.charinfo.lastname, details or ''
    })
end

-----------------------------------------------------------------
-- DASHBOARD
-----------------------------------------------------------------
lib.callback.register('cid-terminal:server:getDashboard', function(source)
    if not hasAccess(source) then return nil end
    local totalAgents = MySQL.query.await('SELECT COUNT(*) as count FROM cid_grade_config')
    local online = 0
    local players = QBox.Functions.GetPlayers()
    for _, s in ipairs(players) do
        local p = QBox.Functions.GetPlayer(s)
        if p then
            for _, j in ipairs(Config.CIDTerminal.allowedJobs) do
                if p.PlayerData.job.name == j then online = online + 1; break end
            end
        end
    end
    local activeCases = MySQL.query.await('SELECT COUNT(*) as count FROM cid_cases WHERE status = \'open\'')
    local activeOps = MySQL.query.await('SELECT COUNT(*) as count FROM cid_operations WHERE status = \'active\'')
    local activeBolos = MySQL.query.await('SELECT COUNT(*) as count FROM cid_bolos WHERE active = 1')
    local spawnCount = MySQL.query.await('SELECT COUNT(*) as count FROM vehicle_spawn_log')
    return {
        totalAgents = totalAgents[1] and totalAgents[1].count or 0,
        onlineAgents = online,
        activeCases = activeCases[1] and activeCases[1].count or 0,
        activeOps = activeOps[1] and activeOps[1].count or 0,
        activeBolos = activeBolos[1] and activeBolos[1].count or 0,
        vehicleSpawns = spawnCount[1] and spawnCount[1].count or 0,
    }
end)

-----------------------------------------------------------------
-- STAFF MANAGEMENT
-----------------------------------------------------------------
lib.callback.register('cid-terminal:server:getStaff', function(source)
    if not hasAccess(source) then return {} end
    local players = QBox.Functions.GetPlayers()
    local staff = {}
    for _, s in ipairs(players) do
        local p = QBox.Functions.GetPlayer(s)
        if p then
            local job = p.PlayerData.job.name
            for _, j in ipairs(Config.CIDTerminal.allowedJobs) do
                if job == j then
                    table.insert(staff, {
                        src = s,
                        citizenid = p.PlayerData.citizenid,
                        name = p.PlayerData.charinfo.firstname .. ' ' .. p.PlayerData.charinfo.lastname,
                        job = job,
                        grade = p.PlayerData.job.grade.level,
                        gradeName = p.PlayerData.job.grade.name,
                        onduty = p.PlayerData.job.onduty,
                    })
                    break
                end
            end
        end
    end
    local rows = MySQL.query.await('SELECT citizenid, job, grade FROM job_rosters WHERE job = \'cid\' OR job = \'police\'')
    if rows then
        for _, r in ipairs(rows) do
            local found = false
            for _, s in ipairs(staff) do
                if s.citizenid == r.citizenid then found = true; break end
            end
            if not found then
                table.insert(staff, {
                    src = nil,
                    citizenid = r.citizenid,
                    name = 'Offline',
                    job = r.job,
                    grade = r.grade,
                    gradeName = 'Grade ' .. r.grade,
                    onduty = false,
                })
            end
        end
    end
    return staff
end)

lib.callback.register('cid-terminal:server:hireStaff', function(source, targetCid, jobName)
    if not canManage(source) then return { error = 'Access denied' } end
    local p = getPlayer(source)
    if not p then return { error = 'Not found' } end
    local target = nil
    local players = QBox.Functions.GetPlayers()
    for _, s in ipairs(players) do
        local pl = QBox.Functions.GetPlayer(s)
        if pl and pl.PlayerData.citizenid == targetCid then target = s; break end
    end
    if not target then return { error = 'Player not online' } end
    local tp = getPlayer(target)
    if not tp then return { error = 'Player not found' } end
    local success = tp.Functions.SetJob(jobName, 0)
    if success then
        MySQL.insert('INSERT INTO job_rosters (citizenid, job, grade, hired_by) VALUES (?, ?, 0, ?) ON DUPLICATE KEY UPDATE job = ?, grade = 0', { targetCid, jobName, p.PlayerData.citizenid, jobName })
        logAction(source, 'hire', targetCid .. ' -> ' .. jobName)
        return { success = true }
    end
    return { error = 'Failed to set job' }
end)

lib.callback.register('cid-terminal:server:fireStaff', function(source, targetCid)
    if not canManage(source) then return { error = 'Access denied' } end
    local p = getPlayer(source)
    if not p then return { error = 'Not found' } end
    MySQL.query('DELETE FROM job_rosters WHERE citizenid = ? AND (job = \'cid\' OR job = \'police\')', { targetCid })
    local players = QBox.Functions.GetPlayers()
    for _, s in ipairs(players) do
        local pl = QBox.Functions.GetPlayer(s)
        if pl and pl.PlayerData.citizenid == targetCid then
            pl.Functions.SetJob('unemployed', 0)
            break
        end
    end
    logAction(source, 'fire', targetCid)
    return { success = true }
end)

lib.callback.register('cid-terminal:server:setStaffGrade', function(source, targetCid, newGrade)
    if not canManage(source) then return { error = 'Access denied' } end
    local players = QBox.Functions.GetPlayers()
    for _, s in ipairs(players) do
        local pl = QBox.Functions.GetPlayer(s)
        if pl and pl.PlayerData.citizenid == targetCid then
            pl.Functions.SetJob(pl.PlayerData.job.name, newGrade)
            MySQL.query('UPDATE job_rosters SET grade = ? WHERE citizenid = ?', { newGrade, targetCid })
            logAction(source, 'setgrade', targetCid .. ' -> grade ' .. newGrade)
            return { success = true }
        end
    end
    return { error = 'Player not online' }
end)

-----------------------------------------------------------------
-- GRADES
-----------------------------------------------------------------
lib.callback.register('cid-terminal:server:getGrades', function(source)
    if not hasAccess(source) then return {} end
    local rows = MySQL.query.await('SELECT grade, label, salary FROM cid_grade_config ORDER BY grade ASC')
    if not rows or #rows == 0 then
        for _, dg in ipairs(Config.CIDTerminal.defaultGrades) do
            MySQL.insert('INSERT IGNORE INTO cid_grade_config (grade, label, salary) VALUES (?, ?, ?)', { dg.grade, dg.label, dg.salary })
        end
        rows = MySQL.query.await('SELECT grade, label, salary FROM cid_grade_config ORDER BY grade ASC')
    end
    return rows or {}
end)

lib.callback.register('cid-terminal:server:updateGrade', function(source, grade, label, salary)
    if not canManage(source) then return { error = 'Access denied' } end
    MySQL.insert('INSERT INTO cid_grade_config (grade, label, salary) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE label = ?, salary = ?', { grade, label, salary, label, salary })
    logAction(source, 'updategrade', 'Grade ' .. grade .. ': ' .. label .. ' ($' .. salary .. ')')
    return { success = true }
end)

-----------------------------------------------------------------
-- PAYROLL
-----------------------------------------------------------------
lib.callback.register('cid-terminal:server:triggerPayroll', function(source)
    if not canManage(source) then return { error = 'Access denied' } end
    local p = getPlayer(source)
    if not p then return { error = 'Not found' } end
    local grades = MySQL.query.await('SELECT grade, label, salary FROM cid_grade_config ORDER BY grade')
    if not grades then return { error = 'No grades configured' } end
    local paid = 0
    local players = QBox.Functions.GetPlayers()
    for _, s in ipairs(players) do
        local pl = QBox.Functions.GetPlayer(s)
        if pl then
            local job = pl.PlayerData.job.name
            for _, j in ipairs(Config.CIDTerminal.allowedJobs) do
                if job == j and pl.PlayerData.job.onduty then
                    local gradeLevel = pl.PlayerData.job.grade.level
                    local salary = 500
                    for _, g in ipairs(grades) do
                        if g.grade == gradeLevel then salary = g.salary; break end
                    end
                    pl.Functions.AddMoney('bank', salary)
                    TriggerClientEvent('ox_lib:notify', s, { type = 'success', description = 'Payroll: $' .. salary .. ' deposited for ' .. job })
                    paid = paid + 1
                    break
                end
            end
        end
    end
    logAction(source, 'payroll', 'Paid ' .. paid .. ' employees')
    return { success = true, paid = paid }
end)

lib.callback.register('cid-terminal:server:getPayrollHistory', function(source)
    if not hasAccess(source) then return {} end
    local rows = MySQL.query.await('SELECT action, performed_by_cid, performed_by_name, details, created_at FROM cid_audit_log WHERE action = \'payroll\' ORDER BY created_at DESC LIMIT 20')
    return rows or {}
end)

-----------------------------------------------------------------
-- ARMORY
-----------------------------------------------------------------
lib.callback.register('cid-terminal:server:getArmoryItems', function(source)
    if not hasAccess(source) then return {} end
    local rows = MySQL.query.await('SELECT id, item_name, label, rank, price, category FROM cid_armory_items ORDER BY category, rank ASC')
    if not rows or #rows == 0 then
        for _, ai in ipairs(Config.CIDTerminal.defaultArmoryItems) do
            MySQL.insert('INSERT IGNORE INTO cid_armory_items (item_name, label, rank, price, category) VALUES (?, ?, ?, ?, ?)', { ai.item, ai.label, ai.rank, ai.price, ai.category })
        end
        rows = MySQL.query.await('SELECT id, item_name, label, rank, price, category FROM cid_armory_items ORDER BY category, rank ASC')
    end
    return rows or {}
end)

lib.callback.register('cid-terminal:server:addArmoryItem', function(source, itemName, label, rank, price, category)
    if not canManage(source) then return { error = 'Access denied' } end
    MySQL.insert('INSERT INTO cid_armory_items (item_name, label, rank, price, category) VALUES (?, ?, ?, ?, ?)', { itemName, label, rank or 0, price or 0, category or 'general' })
    logAction(source, 'addarmory', itemName .. ' (rank ' .. (rank or 0) .. ')')
    return { success = true }
end)

lib.callback.register('cid-terminal:server:updateArmoryItem', function(source, id, label, rank, price, category)
    if not canManage(source) then return { error = 'Access denied' } end
    MySQL.update('UPDATE cid_armory_items SET label = ?, rank = ?, price = ?, category = ? WHERE id = ?', { label, rank, price, category, id })
    logAction(source, 'updatearmory', 'Item #' .. id)
    return { success = true }
end)

lib.callback.register('cid-terminal:server:removeArmoryItem', function(source, id)
    if not canManage(source) then return { error = 'Access denied' } end
    MySQL.query('DELETE FROM cid_armory_items WHERE id = ?', { id })
    logAction(source, 'removearmory', 'Item #' .. id)
    return { success = true }
end)

-----------------------------------------------------------------
-- CASES
-----------------------------------------------------------------
lib.callback.register('cid-terminal:server:getCases', function(source)
    if not hasAccess(source) then return {} end
    local rows = MySQL.query.await('SELECT c.id, c.title, c.description, c.assigned_to, c.status, c.created_by, c.created_at, c.closed_at FROM cid_cases c ORDER BY c.created_at DESC')
    return rows or {}
end)

lib.callback.register('cid-terminal:server:createCase', function(source, title, description, assignedTo)
    if not hasAccess(source) then return { error = 'Access denied' } end
    local p = getPlayer(source)
    if not p then return { error = 'Not found' } end
    MySQL.insert('INSERT INTO cid_cases (title, description, assigned_to, created_by, status) VALUES (?, ?, ?, ?, \'open\')', { title, description, assignedTo, p.PlayerData.citizenid })
    logAction(source, 'createcase', title)
    return { success = true }
end)

lib.callback.register('cid-terminal:server:closeCase', function(source, caseId)
    if not canManage(source) then return { error = 'Access denied' } end
    MySQL.update('UPDATE cid_cases SET status = \'closed\', closed_at = NOW() WHERE id = ?', { caseId })
    logAction(source, 'closecase', 'Case #' .. caseId)
    return { success = true }
end)

-----------------------------------------------------------------
-- WARRANTS
-----------------------------------------------------------------
lib.callback.register('cid-terminal:server:getWarrants', function(source)
    if not hasAccess(source) then return {} end
    local rows = MySQL.query.await('SELECT id, target_name, target_cid, crime, issued_by, status, created_at FROM cid_warrants ORDER BY created_at DESC')
    return rows or {}
end)

lib.callback.register('cid-terminal:server:issueWarrant', function(source, targetName, targetCid, crime)
    if not hasAccess(source) then return { error = 'Access denied' } end
    local p = getPlayer(source)
    if not p then return { error = 'Not found' } end
    MySQL.insert('INSERT INTO cid_warrants (target_name, target_cid, crime, issued_by, status) VALUES (?, ?, ?, ?, \'active\')', { targetName, targetCid, crime, p.PlayerData.citizenid })
    logAction(source, 'issuewarrant', targetName .. ' - ' .. crime)
    return { success = true }
end)

lib.callback.register('cid-terminal:server:closeWarrant', function(source, warrantId)
    if not canManage(source) then return { error = 'Access denied' } end
    MySQL.update('UPDATE cid_warrants SET status = \'closed\' WHERE id = ?', { warrantId })
    logAction(source, 'closewarrant', 'Warrant #' .. warrantId)
    return { success = true }
end)

-----------------------------------------------------------------
-- BOLOS
-----------------------------------------------------------------
lib.callback.register('cid-terminal:server:getBOLOs', function(source)
    if not hasAccess(source) then return {} end
    local rows = MySQL.query.await('SELECT id, type, plate, description, reason, issued_by, active, created_at FROM cid_bolos ORDER BY active DESC, created_at DESC')
    return rows or {}
end)

lib.callback.register('cid-terminal:server:createBOLO', function(source, boloType, plate, description, reason)
    if not hasAccess(source) then return { error = 'Access denied' } end
    local p = getPlayer(source)
    if not p then return { error = 'Not found' } end
    MySQL.insert('INSERT INTO cid_bolos (type, plate, description, reason, issued_by, active) VALUES (?, ?, ?, ?, ?, 1)', { boloType, plate, description, reason, p.PlayerData.citizenid })
    logAction(source, 'createbolo', (boloType or 'person') .. ': ' .. (plate or description))
    return { success = true }
end)

lib.callback.register('cid-terminal:server:removeBOLO', function(source, boloId)
    if not canManage(source) then return { error = 'Access denied' } end
    MySQL.update('UPDATE cid_bolos SET active = 0 WHERE id = ?', { boloId })
    logAction(source, 'removebolo', 'BOLO #' .. boloId)
    return { success = true }
end)

-----------------------------------------------------------------
-- PERSON DB
-----------------------------------------------------------------
lib.callback.register('cid-terminal:server:searchPerson', function(source, query)
    if not hasAccess(source) then return {} end
    local rows = MySQL.query.await('SELECT citizenid, firstname, lastname, phone_number FROM characters WHERE citizenid LIKE ? OR firstname LIKE ? OR lastname LIKE ? OR phone_number LIKE ? LIMIT 20',
        { '%' .. query .. '%', '%' .. query .. '%', '%' .. query .. '%', '%' .. query .. '%' })
    return rows or {}
end)

lib.callback.register('cid-terminal:server:getPersonNotes', function(source, targetCid)
    if not hasAccess(source) then return {} end
    local rows = MySQL.query.await('SELECT id, note, flagged_by, created_at FROM cid_person_notes WHERE target_cid = ? ORDER BY created_at DESC', { targetCid })
    local record = MySQL.query.await('SELECT id, offense, fine, prison_time, officer, created_at FROM criminal_records WHERE citizenid = ? ORDER BY created_at DESC', { targetCid })
    return { notes = rows or {}, records = record or {} }
end)

lib.callback.register('cid-terminal:server:addPersonNote', function(source, targetCid, note)
    if not hasAccess(source) then return { error = 'Access denied' } end
    local p = getPlayer(source)
    if not p then return { error = 'Not found' } end
    MySQL.insert('INSERT INTO cid_person_notes (target_cid, note, flagged_by) VALUES (?, ?, ?)', { targetCid, note, p.PlayerData.citizenid })
    logAction(source, 'personnote', targetCid .. ': ' .. note)
    return { success = true }
end)

-----------------------------------------------------------------
-- VEHICLE SPAWN TRACKING
-----------------------------------------------------------------
lib.callback.register('cid-terminal:server:getVehicleSpawns', function(source)
    if not hasAccess(source) then return { total = 0, spawns = {} } end
    local count = MySQL.query.await('SELECT COUNT(*) as c FROM vehicle_spawn_log')
    local rows = MySQL.query.await('SELECT spawner_cid, spawner_name, vehicle_model, vehicle_label, spawned_at FROM vehicle_spawn_log ORDER BY spawned_at DESC LIMIT 50')
    return { total = count[1] and count[1].c or 0, spawns = rows or {} }
end)

-- Hook into admin-commander vehicle spawns
RegisterNetEvent('cid-terminal:server:logVehicleSpawn', function(vehicleModel, vehicleLabel)
    local src = source
    local p = getPlayer(src)
    if not p then return end
    MySQL.insert('INSERT INTO vehicle_spawn_log (spawner_cid, spawner_name, vehicle_model, vehicle_label) VALUES (?, ?, ?, ?)', {
        p.PlayerData.citizenid, p.PlayerData.charinfo.firstname .. ' ' .. p.PlayerData.charinfo.lastname, vehicleModel, vehicleLabel or vehicleModel
    })
end)

-----------------------------------------------------------------
-- AUDIT LOG
-----------------------------------------------------------------
lib.callback.register('cid-terminal:server:getAuditLog', function(source)
    if not hasAccess(source) then return {} end
    local rows = MySQL.query.await('SELECT action, target, performed_by_cid, performed_by_name, details, created_at FROM cid_audit_log ORDER BY created_at DESC LIMIT 50')
    return rows or {}
end)

-----------------------------------------------------------------
-- ANNOUNCEMENTS
-----------------------------------------------------------------
lib.callback.register('cid-terminal:server:sendAnnouncement', function(source, message)
    if not canManage(source) then return { error = 'Access denied' } end
    local p = getPlayer(source)
    if not p then return { error = 'Not found' } end
    local senderName = p.PlayerData.charinfo.firstname .. ' ' .. p.PlayerData.charinfo.lastname
    local players = QBox.Functions.GetPlayers()
    for _, s in ipairs(players) do
        local pl = QBox.Functions.GetPlayer(s)
        if pl then
            for _, j in ipairs(Config.CIDTerminal.allowedJobs) do
                if pl.PlayerData.job.name == j then
                    TriggerClientEvent('ox_lib:notify', s, { type = 'info', description = '[CID ANNOUNCEMENT] ' .. senderName .. ': ' .. message, duration = 10000 })
                    break
                end
            end
        end
    end
    logAction(source, 'announcement', message)
    return { success = true }
end)

-----------------------------------------------------------------
-- CHECK ACCESS
-----------------------------------------------------------------
lib.callback.register('cid-terminal:server:checkAccess', function(source)
    local p = getPlayer(source)
    if not p then return false end
    local job = p.PlayerData.job.name
    local grade = p.PlayerData.job.grade.level
    for _, j in ipairs(Config.CIDTerminal.allowedJobs) do
        if job == j then return true end
    end
    return false
end)
