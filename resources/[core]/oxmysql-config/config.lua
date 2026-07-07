Config = Config or {}

Config.PoolOptions = {
    maxRetries = 3,
    retryDelay = 1000,
    poolSize = 20,
    queueLimit = 100,
    acquireTimeout = 10000
}

Config.QueryCache = {
    enabled = true,
    ttl = 300000,
    maxEntries = 500
}

Config.HealthCheck = {
    enabled = true,
    interval = 30000,
    query = 'SELECT 1'
}

Config.ConnectionString = 'mysql://root:password@localhost:3306/fivem?charset=utf8mb4'

Config.LogSlowQueries = true
Config.SlowQueryThreshold = 500

Config.PreparedStatements = {
    findPlayerByLicense = 'SELECT * FROM players WHERE license = ? LIMIT 1',
    findPlayerByCitizenId = 'SELECT * FROM players WHERE citizenid = ? LIMIT 1',
    createPlayer = 'INSERT INTO players (license, citizenid, firstname, lastname, phone, money, job, gang, position, metadata, charinfo) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
    updatePlayer = 'UPDATE players SET money = ?, job = ?, gang = ?, position = ?, metadata = ?, charinfo = ? WHERE citizenid = ?',
    deletePlayer = 'DELETE FROM players WHERE citizenid = ?',
    findVehicles = 'SELECT * FROM player_vehicles WHERE citizenid = ?',
    findVehicleByPlate = 'SELECT * FROM player_vehicles WHERE plate = ?',
    insertVehicle = 'INSERT INTO player_vehicles (citizenid, plate, vehicle, hash, garage, state, fuel, engine_damage, body_damage, mods) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
    updateVehicle = 'UPDATE player_vehicles SET garage = ?, state = ?, fuel = ?, engine_damage = ?, body_damage = ?, mods = ? WHERE plate = ?',
    deleteVehicle = 'DELETE FROM player_vehicles WHERE id = ?',
    findCharacters = 'SELECT * FROM player_chars WHERE license = ? ORDER BY slot ASC',
    findCharacterBySlot = 'SELECT * FROM player_chars WHERE license = ? AND slot = ? LIMIT 1',
    createCharacter = 'INSERT INTO player_chars (license, citizenid, slot, firstname, lastname, dob, gender, phone, money, job, gang, position, metadata, charinfo) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
    deleteCharacter = 'DELETE FROM player_chars WHERE citizenid = ?',
    setActiveCharacter = 'UPDATE player_chars SET is_active = ? WHERE citizenid = ?',
    deactivateAllChars = 'UPDATE player_chars SET is_active = FALSE WHERE license = ?',
    findHouses = 'SELECT * FROM player_houses WHERE citizenid = ? OR JSON_CONTAINS(keys, ?)',
    insertHouse = 'INSERT INTO player_houses (citizenid, property_id, label, shell_id, price) VALUES (?, ?, ?, ?, ?)',
    updateHouse = 'UPDATE player_houses SET keys = ?, furniture = ?, is_locked = ? WHERE id = ?',
    deleteHouse = 'DELETE FROM player_houses WHERE id = ?',
    findBankAccounts = 'SELECT * FROM bank_accounts WHERE citizenid = ?',
    findBankAccountByIban = 'SELECT * FROM bank_accounts WHERE iban = ? LIMIT 1',
    createBankAccount = 'INSERT INTO bank_accounts (citizenid, account_name, account_type, iban, balance) VALUES (?, ?, ?, ?, ?)',
    updateBankBalance = 'UPDATE bank_accounts SET balance = ? WHERE id = ?',
    insertBankTransaction = 'INSERT INTO bank_transactions (account_id, citizenid, type, amount, reason, target) VALUES (?, ?, ?, ?, ?, ?)',
    findTransactions = 'SELECT * FROM bank_transactions WHERE account_id = ? ORDER BY timestamp DESC LIMIT 50',
    findGang = 'SELECT * FROM gangs WHERE name = ? LIMIT 1',
    createGang = 'INSERT INTO gangs (name, label, color, owner, members, vault, territory) VALUES (?, ?, ?, ?, ?, ?, ?)',
    updateGang = 'UPDATE gangs SET members = ?, vault = ?, territory = ? WHERE name = ?',
    findCriminalRecords = 'SELECT * FROM criminal_records WHERE citizenid = ? ORDER BY timestamp DESC',
    insertCriminalRecord = 'INSERT INTO criminal_records (citizenid, offense, fine, prison_time, officer) VALUES (?, ?, ?, ?, ?)',
    findMdtIncidents = 'SELECT * FROM mdt_incidents ORDER BY created_at DESC LIMIT 100',
    insertMdtIncident = 'INSERT INTO mdt_incidents (title, details, officers, suspects, status) VALUES (?, ?, ?, ?, ?)',
    updateMdtIncident = 'UPDATE mdt_incidents SET details = ?, officers = ?, evidence = ?, suspects = ?, status = ? WHERE id = ?',
    findMdtWarrants = 'SELECT * FROM mdt_warrants WHERE is_active = TRUE',
    insertMdtWarrant = 'INSERT INTO mdt_warrants (citizenid, issuing_officer, charges, expires_at) VALUES (?, ?, ?, ?)',
    findCryptoWallet = 'SELECT * FROM crypto_wallets WHERE citizenid = ? LIMIT 1',
    createCryptoWallet = 'INSERT INTO crypto_wallets (citizenid, qbit_balance) VALUES (?, ?)',
    updateCryptoBalance = 'UPDATE crypto_wallets SET qbit_balance = ? WHERE citizenid = ?'
}
