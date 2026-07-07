local queryCache = {}
local cacheTimers = {}
local activeQueries = {}
local poolHealthy = false

local function GetCurrentTime()
    return os.time() * 1000
end

local function CacheGet(cacheKey)
    if not Config.QueryCache.enabled then return nil end
    local entry = queryCache[cacheKey]
    if not entry then return nil end
    local age = GetCurrentTime() - entry.timestamp
    if age > Config.QueryCache.ttl then
        queryCache[cacheKey] = nil
        cacheTimers[cacheKey] = nil
        return nil
    end
    return entry.data
end

local function CacheSet(cacheKey, data)
    if not Config.QueryCache.enabled then return end
    if #queryCache >= Config.QueryCache.maxEntries then
        local oldestKey = nil
        local oldestTime = GetCurrentTime()
        for k, v in pairs(queryCache) do
            if v.timestamp < oldestTime then
                oldestTime = v.timestamp
                oldestKey = k
            end
        end
        if oldestKey then
            queryCache[oldestKey] = nil
        end
    end
    queryCache[cacheKey] = { data = data, timestamp = GetCurrentTime() }
end

function CacheInvalidate(pattern)
    for k in pairs(queryCache) do
        if k:find(pattern) then
            queryCache[k] = nil
        end
    end
end

exports('CacheInvalidate', CacheInvalidate)

local function PrepareQuery(queryName, ...)
    local sql = Config.PreparedStatements[queryName]
    if not sql then
        error(string.format('Prepared statement "%s" not found', queryName))
    end
    return sql, { ... }
end

local function ExecuteWithRetry(query, params, retries)
    retries = retries or Config.PoolOptions.maxRetries
    local lastError = nil
    for attempt = 1, retries do
        local success, result = pcall(function()
            return MySQL.query.await(query, params)
        end)
        if success then
            return result
        end
        lastError = result
        if attempt < retries then
            Citizen.Wait(Config.PoolOptions.retryDelay)
        end
    end
    error(string.format('Query failed after %d retries: %s', retries, tostring(lastError)))
end

local function MySQLQuery(query, params, callback)
    local startTime = GetCurrentTime()
    local success, result = pcall(ExecuteWithRetry, query, params)
    local elapsed = GetCurrentTime() - startTime
    if Config.LogSlowQueries and elapsed > Config.SlowQueryThreshold then
        print(string.format('^3[SLOW QUERY] %dms | %s^7', elapsed, query))
    end
    if callback then
        callback(success, success and result or nil, not success and result or nil)
    end
    if not success then
        return nil, result
    end
    return result, nil
end

local function MySQLQueryAsync(query, params)
    return lib.callback.await('oxmysql-config:asyncQuery', false, query, params)
end

lib.callback.register('oxmysql-config:asyncQuery', function(source, query, params)
    local success, result = pcall(ExecuteWithRetry, query, params)
    if not success then
        print(string.format('^1[DB ERROR] %s^7', tostring(result)))
        return nil, result
    end
    return result
end)

local function MySQLQueryCached(queryName, params)
    local cacheKey = queryName .. ':' .. json.encode(params)
    local cached = CacheGet(cacheKey)
    if cached then return cached end
    local sql = Config.PreparedStatements[queryName]
    if not sql then
        error(string.format('Prepared statement "%s" not found', queryName))
    end
    local result = ExecuteWithRetry(sql, params)
    CacheSet(cacheKey, result)
    return result
end

local function MySQLInsert(query, params)
    return ExecuteWithRetry(query, params)
end

local function MySQLUpdate(query, params)
    return ExecuteWithRetry(query, params)
end

local function MySQLDelete(query, params)
    return ExecuteWithRetry(query, params)
end

local function MySQLScalar(query, params)
    local result = ExecuteWithRetry(query, params)
    if result and #result > 0 then
        return result[1]
    end
    return nil
end

local function PerformHealthCheck()
    local success, result = pcall(function()
        return MySQL.query.await(Config.HealthCheck.query)
    end)
    if success then
        if not poolHealthy then
            print('^2[oxmysql-config] Database pool is healthy.^7')
        end
        poolHealthy = true
    else
        print(string.format('^1[oxmysql-config] Database health check FAILED: %s^7', tostring(result)))
        poolHealthy = false
    end
end

lib.callback.register('oxmysql-config:getPoolStatus', function(source)
    return {
        healthy = poolHealthy,
        cacheSize = #queryCache,
        activeQueries = #activeQueries,
        uptime = GetGameTimer()
    }
end)

local function InitializePool()
    local connString = GetConvar('mysql_connection_string', Config.ConnectionString)
    if connString and connString ~= '' then
        print('^2[oxmysql-config] Using connection string from server.cfg^7')
    else
        print(string.format('^3[oxmysql-config] No connection string in server.cfg, using default from config.lua^7'))
        SetConvarReplicated('mysql_connection_string', Config.ConnectionString)
    end
    SetTimeout(2000, function()
        PerformHealthCheck()
        Citizen.CreateThread(function()
            while true do
                Citizen.Wait(Config.HealthCheck.interval)
                PerformHealthCheck()
            end
        end)
    end)
end

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[oxmysql-config] Initializing database pool...^7')
    InitializePool()
end)

exports('Query', MySQLQuery)
exports('QueryAsync', MySQLQueryAsync)
exports('QueryCached', MySQLQueryCached)
exports('Insert', MySQLInsert)
exports('Update', MySQLUpdate)
exports('Delete', MySQLDelete)
exports('Scalar', MySQLScalar)
exports('Prepare', PrepareQuery)
exports('IsHealthy', function() return poolHealthy end)

print('^2[oxmysql-config] Loaded successfully. Prepared statement cache active.^7')
