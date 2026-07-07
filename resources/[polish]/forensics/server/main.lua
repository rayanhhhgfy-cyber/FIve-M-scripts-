local QBox = exports['qbx_core']:GetCoreObject()

lib.callback.register('forensics:getEvidence', function(source)
    local player = QBox.Functions.GetPlayer(source)
    if not player then return {} end
    local items = exports.ox_inventory:GetItems(source)
    if not items then return {} end
    local evidence = {}
    for _, item in ipairs(items) do
        if item.name == 'evidence_bag' and item.metadata and item.metadata.type then
            table.insert(evidence, {
                slot = item.slot,
                id = item.metadata.evidenceId,
                type = item.metadata.type,
                data = item.metadata.data or 'No data',
                time = item.metadata.timestamp and os.date('%Y-%m-%d %H:%M', item.metadata.timestamp) or 'Unknown',
                coords = item.metadata.coords,
                collectedBy = item.metadata.playerName or 'Unknown',
            })
        end
    end
    return evidence
end)

lib.callback.register('forensics:analyzeEvidence', function(source, evidenceId)
    local player = QBox.Functions.GetPlayer(source)
    if not player then return { success = false, message = 'Player not found' } end
    local items = exports.ox_inventory:GetItems(source)
    if not items then return { success = false, message = 'No inventory' } end

    local foundItem = nil
    local foundSlot = nil
    for _, item in ipairs(items) do
        if item.name == 'evidence_bag' and item.metadata and item.metadata.evidenceId == evidenceId then
            foundItem = item
            foundSlot = item.slot
            break
        end
    end

    if not foundItem then
        return { success = false, message = 'Evidence item not found in inventory' }
    end

    local meta = foundItem.metadata
    local result = {
        success = true,
        evidenceId = meta.evidenceId,
        evidenceType = meta.type,
        collectedBy = meta.playerName,
        collectedAt = os.date('%Y-%m-%d %H:%M', meta.timestamp or os.time()),
        coords = meta.coords,
        match = false,
        matchType = nil,
        matchName = nil,
        details = nil,
    }

    if meta.type == 'fingerprint' then
        local knownRecords = MySQL.query.await('SELECT * FROM criminal_records WHERE type = ? ORDER BY created_at DESC LIMIT 20', { 'fingerprint' })
        if knownRecords and #knownRecords > 0 then
            local match = knownRecords[math.random(1, #knownRecords)]
            local matchChance = math.random()
            if matchChance > 0.4 then
                result.match = true
                result.matchType = 'Fingerprint'
                result.matchName = match.offender_name or 'Unknown'
                result.details = 'Fingerprint match found in database — ' .. (match.offender_name or 'Unknown') .. ' (Case #' .. (match.case_id or 'N/A') .. ')'
            else
                result.details = 'No fingerprint match in database. Prints archived for future comparison.'
            end
        else
            result.details = 'No fingerprint records in database. Prints archived for future comparison.'
        end
    elseif meta.type == 'casing' then
        local weaponHash = nil
        if meta.data and meta.data:find('weapon:') then
            weaponHash = meta.data:match('weapon:(%w+)')
        end
        if weaponHash then
            result.details = 'Casing analysis complete. Weapon hash: ' .. weaponHash
            local weaponName = GetWeaponNameFromHash(tonumber(weaponHash) or 0)
            if weaponName and weaponName ~= '' then
                result.details = result.details .. ' (' .. weaponName .. ')'

                local registered = MySQL.query.await('SELECT * FROM registered_weapons WHERE weapon_hash = ? LIMIT 1', { weaponHash })
                if registered and #registered > 0 then
                    result.match = true
                    result.matchType = 'Firearm'
                    result.matchName = registered[1].owner_name or 'Registered Owner'
                    result.details = result.details .. ' — Registered to ' .. (registered[1].owner_name or 'Unknown')
                end
            end
        else
            result.details = 'Casing analysis complete. No weapon hash recovered.'
        end
    elseif meta.type == 'dna' then
        local knownRecords = MySQL.query.await('SELECT * FROM criminal_records WHERE type = ? ORDER BY created_at DESC LIMIT 20', { 'dna' })
        if knownRecords and #knownRecords > 0 then
            local match = knownRecords[math.random(1, #knownRecords)]
            local matchChance = math.random()
            if matchChance > 0.3 then
                result.match = true
                result.matchType = 'DNA'
                result.matchName = match.offender_name or 'Unknown'
                result.details = 'DNA match found — ' .. (match.offender_name or 'Unknown') .. ' (Case #' .. (match.case_id or 'N/A') .. ')'
            else
                result.details = 'No DNA match in database. Sample archived for future comparison.'
            end
        else
            result.details = 'No DNA records in database. Sample archived for future comparison.'
        end
    else
        result.details = 'Unknown evidence type. Analysis inconclusive.'
    end

    MySQL.insert('INSERT INTO admin_logs (admin_cid, target_cid, action, reason, created_at) VALUES (?, ?, ?, ?, NOW())', {
        player.PlayerData.citizenid, source, 'evidence_analysis', evidenceId .. ':' .. meta.type .. ':' .. (result.match and 'MATCH' or 'NO_MATCH'),
    })

    return result
end)
