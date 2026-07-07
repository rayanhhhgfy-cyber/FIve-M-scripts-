local QBox = exports['qbx_core']:GetCoreObject()
local RATE_LIMITS = {}

local function checkRateLimit(src, action, maxPerMin)
    local key = src .. ':' .. action
    local now = os.time()
    RATE_LIMITS[key] = RATE_LIMITS[key] or {}
    table.insert(RATE_LIMITS[key], now)
    for i = #RATE_LIMITS[key], 1, -1 do
        if now - RATE_LIMITS[key][i] > 60 then table.remove(RATE_LIMITS[key], i) end
    end
    return #RATE_LIMITS[key] <= maxPerMin
end

local function isAuthorized(src)
    local player = QBox.Functions.GetPlayer(src)
    if not player then return false end
    if not Config.CIDWeapons.requireDuty or player.PlayerData.job.onduty then
        for _, j in ipairs(Config.CIDWeapons.allowedJobs) do
            if player.PlayerData.job.name == j then return true end
        end
    end
    for _, g in ipairs(Config.CIDWeapons.adminGroups) do
        if player.PlayerData.group == g then return true end
    end
    return false
end

--- Take weapon from CID armory
RegisterNetEvent('cidweapons:take', function(weaponName)
    local src = source
    if not checkRateLimit(src, 'cidWeapon', 10) then return end
    if not isAuthorized(src) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Not authorized' })
        return
    end
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    local wepConfig = nil
    for _, w in ipairs(Config.CIDWeapons.weapons) do
        if w.weapon == weaponName then wepConfig = w end
    end
    if not wepConfig then return end
    if player.PlayerData.job.grade.level < wepConfig.rank then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Rank too low (need rank ' .. wepConfig.rank .. ')' })
        return
    end
    if player.Functions.AddItem(weaponName, wepConfig.count) then
        -- Auto-give matching ammo
        local ammoMap = {
            WEAPON_PISTOL = 'ammo-9', WEAPON_PISTOL50 = 'ammo-9', WEAPON_STUNGUN = 'ammo-9',
            WEAPON_COMBATPDW = 'ammo-9', WEAPON_MICROSMG = 'ammo-9', WEAPON_SMG = 'ammo-9',
            WEAPON_ASSAULTRIFLE = 'ammo-rifle2', WEAPON_CARBINERIFLE = 'ammo-rifle2',
            WEAPON_SPECIALCARBINE = 'ammo-rifle2', WEAPON_ADVANCEDRIFLE = 'ammo-rifle2',
            WEAPON_BULLPUPRIFLE = 'ammo-rifle2', WEAPON_MILITARYRIFLE = 'ammo-rifle2',
            WEAPON_MG = 'ammo-rifle2', WEAPON_COMBATMG = 'ammo-rifle2',
            WEAPON_HEAVYSNIPER = 'ammo-heavysniper', WEAPON_SNIPERRIFLE = 'ammo-sniper',
            WEAPON_MARKSMANRIFLE = 'ammo-rifle2',
            WEAPON_PUMPSHOTGUN = 'ammo-shotgun', WEAPON_ASSAULTSHOTGUN = 'ammo-shotgun',
            WEAPON_RPG = 'ammo-rocket',
            WEAPON_NIGHTSTICK = nil, WEAPON_BZGAS = nil, WEAPON_GRENADE = nil,
            WEAPON_STICKYBOMB = nil, WEAPON_MOLOTOV = nil, WEAPON_SMOKEGRENADE = nil, WEAPON_FLARE = nil,
        }
        local ammoType = ammoMap[weaponName]
        if ammoType then
            player.Functions.AddItem(ammoType, 60)
        end
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Took ' .. wepConfig.label .. (ammoType and ' + ammo' or '') })
    end
end)

--- Admin: give any CID weapon bypassing rank
RegisterNetEvent('cidweapons:admin:give', function(targetSrc, weaponName)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    local isAdmin = false
    for _, g in ipairs(Config.CIDWeapons.adminGroups) do
        if player.PlayerData.group == g then isAdmin = true end
    end
    if not isAdmin then return end
    local target = QBox.Functions.GetPlayer(targetSrc)
    if not target then return end
    local wepConfig = nil
    for _, w in ipairs(Config.CIDWeapons.weapons) do
        if w.weapon == weaponName then wepConfig = w end
    end
    if not wepConfig then return end
    if target.Functions.AddItem(weaponName, wepConfig.count) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Gave ' .. wepConfig.label .. ' to ' .. target.PlayerData.charinfo.firstname })
    end
end)
