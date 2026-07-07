# FiveM Server — System Reference

> Complete documentation of all custom features, architecture, and usage.
> Last updated: June 2026

---

## Table of Contents

1. [God Menu — Admin Panel](#1-god-menu--admin-panel)
2. [Admin Door Lock System](#2-admin-door-lock-system)
3. [Admin Inventory Viewer](#3-admin-inventory-viewer)
4. [Ban / Kick Management](#4-ban--kick-management)
5. [Vehicle Garage Viewer](#5-vehicle-garage-viewer)
6. [Staff Management](#6-staff-management)
7. [Report Queue](#7-report-queue)
8. [Drag System](#8-drag-system)
9. [iPhone Vehicles App](#9-iphone-vehicles-app)
10. [CDN-HUD (NUI Overlay)](#10-cdn-hud-nui-overlay)
11. [Quick Fixes Applied](#11-quick-fixes-applied)
12. [Database Schema](#12-database-schema)
13. [Security & Access Control](#13-security--access-control)
14. [Troubleshooting](#14-troubleshooting)

---

## 1. God Menu — Admin Panel

| Resource | Path |
|----------|------|
| `god-menu` | `resources/[admin]/god-menu/` |
| Config | `config.lua` |
| Server | `server/main.lua` (881 lines) |
| Client | `client/main.lua` (848 lines) |
| UI | `html/index.html`, `html/script.js`, `html/style.css` |

### How to Open

- **Command**: `/god`
- **Keybind**: `F6` (configurable in `config.lua:8`)

### Access Control — Auto God Owner

The first player to **ever join the server** is automatically assigned as the **God Owner** and stored in the `server_owners` database table. Only they (and anyone they add) can access the god menu.

**How it works:**
1. On `playerJoining`, server checks if `server_owners` has any god entries
2. If **none exist**, the joining player is inserted with `group_name = 'god'`
3. They receive a notification: **"You have been auto-assigned as the God Owner!"**
4. Every subsequent access check queries the DB cache + optional config override

**Adding more owners (in-game):**
```
/godowner add [playerID]      — Grant god access to a player
/godowner remove [identifier] — Revoke god access
/godowner list                — List all god owners
```
Only existing owners can use this command.

**Config fallback override:**
Optionally hardcode Steam hexes in `config.lua:3` for emergency access. These always pass the check regardless of DB state. Leave empty `{}` for pure DB-based ownership.

**Two-layer verification:**
- **Client side**: `checkOwner()` calls `lib.callback('god:server:checkOwner')` before opening the menu
- **Server side**: Every single event/callback starts with `if not isOwner(source) then return end`
- `isOwner()` checks: config override → DB cache → denied

### Tab Overview

| Tab | Description | Requires |
|-----|-------------|----------|
| Players | List online players, teleport to them, copy ID | isOwner |
| Vehicles | Spawn vehicles by model | isOwner |
| Inventory | View any player's inventory, remove items | isOwner |
| Items | Give items/weapons to yourself | isOwner |
| Money | Set cash/bank for any player | isOwner |
| Weather | Change weather globally | isOwner |
| Time | Freeze/unfreeze/set time | isOwner |
| Teleport | Teleport to preset locations (config.lua:15) | isOwner |
| Server | Restart resources, announce messages | isOwner |
| **Bans** | Manages bans (Phase 2) | isOwner |
| **Garage** | View/manage player vehicles (Phase 3) | isOwner |
| **Staff** | Promote/demote/view staff (Phase 4) | isOwner |
| **Reports** | View/accept/close reports (Phase 6) | isOwner |
| **Doors** | Admin door lock management (Phase 1) | isOwner |
| Tools | Misc utilities (delete vehicle, noclip, revive) | isOwner |

### Server Events Reference

All in `server/main.lua`. Every event prefixed with `god:`.

**Core:**
- `god:server:openMenu` — Opens the menu (isOwner check)
- `god:server:getPlayerDetails` — Returns player inventory, identity, weapon info

**Players tab:**
- `god:server:teleportToPlayer` — Teleport source to target player
- `god:server:getPlayerList` — Returns all online players

**Money tab:**
- `god:server:setCash` / `god:server:setBank` — Set money for a player
- `god:server:setPlayerMoney` — UI-driven money set

**Items tab:**
- `god:server:giveItem` — Give item/weapon to source
- `god:server:giveItemToPlayer` — Give item to another player

**Inventory tab (Phase 1):**
- `god:server:removePlayerItem` — Remove item from a player's inventory

**Server tab:**
- `god:server:restartResource` — Restart a resource
- `god:server:announce` — Global announcement

**Weather/Time:**
- `god:server:setWeather` — Set weather type
- `god:server:freezeTime` / `god:server:unfreezeTime` / `god:server:setTime`

**Vehicles tab:**
- `god:server:spawnVehicle` — Spawn vehicle
- `god:server:deleteVehicleServer` — Delete nearby vehicle by plate
- `god:server:repairVehicle` — Repair vehicle
- `god:server:giveVehicleKeys` — Give keys for a vehicle

---

## 2. Admin Door Lock System

### Overview

Full CRUD door lock management inside the god-menu's **Doors** tab. Also accessible via `/dooradmin` command in-game. Works alongside existing `doorlock`/`passcode-doors` without conflict.

### How It Works

1. **Detect Current Door** — Player stands near a door, clicks "Detect Current Door" in UI. Client calls `GetDoorFromPosition()`, returns door details, and highlights the detected door with a **cyan outline** (`DrawBox`).

2. **Add Door** — Auto-fills door details from detection. Set mode:
   - **Permanent** — Always locked
   - **Passcode** — Simple numeric code (stored hashed via small hash)
   - **Job Only** — Lock unlocks for selected jobs (multi-select)

3. **Manage Doors** — Every door shows as a card with status badge, mode badge, toggle lock/unlock, edit, delete buttons.

4. **Bulk Actions** — Lock All / Unlock All buttons at the top.

5. **ox_target Integration** — Each admin-managed door gets an ox_target zone. Interaction: "Toggle Door Lock" (visible to everyone) and "Admin Door Settings" (visible only to owners via `isOwner()`).

### Commands

| Command | Description |
|---------|-------------|
| `/dooradmin` | Opens door management UI (same as Doors tab) |

### Server Events (`server/main.lua:796-878`)

| Event/Callback | Description |
|---------------|-------------|
| `god:server:addDoor` | Insert new door into `admin_managed_doors` table |
| `god:server:editDoor` | Update door settings |
| `god:server:deleteDoor` | Remove door from DB |
| `god:server:toggleDoorLock` | Toggle lock state (accessed via ox_target) |
| `god:server:lockAllDoors` | Lock every admin door |
| `god:server:unlockAllDoors` | Unlock every admin door |
| `god:server:syncDoorState` | Sync door state to all clients |
| `god:server:verifyPasscode` | Check entered passcode against stored hash |
| `godGetDoors` | Fetch all doors for UI |

### Client-Side

- `god:client:syncDoor` — Receives door state changes, updates ox_target zone options
- `god:client:highlightDoor` — Draws cyan box around a detected door
- `/dooradmin` command registers and opens UI
- ox_target zones created for each door on load

### Database Table

```sql
admin_managed_doors (
    id INT AUTO_INCREMENT PRIMARY KEY,
    door_id VARCHAR(128) NOT NULL UNIQUE,
    label VARCHAR(128) NOT NULL DEFAULT 'Unknown Door',
    model_hash INT NOT NULL DEFAULT 0,
    coords JSON NOT NULL,
    locked TINYINT(1) NOT NULL DEFAULT 1,
    mode ENUM('permanent','passcode','job') NOT NULL DEFAULT 'permanent',
    passcode_hash VARCHAR(64) DEFAULT NULL,
    allowed_jobs JSON DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)
```

### Key Details

- Door state syncs globally: `TriggerClientEvent('god:client:syncDoor', -1, doorId, state)`
- ox_target zones use `addBoxZone` with door coords
- Passcode stored as simple hash (same pattern as passcode-doors)
- Job multi-select renders in setup modal

---

## 3. Admin Inventory Viewer

### Overview

View any online player's inventory from the god-menu **Inventory** tab. Shows weapons with components (attachments), ammo counts, and all items in the ox_inventory format.

### How to Use

1. Open god-menu → Inventory tab
2. Select a player from the dropdown (populated from online players)
3. Browse items with category filters: All / Weapons / Attachments / Ammo / Items / Clothing
4. Use the search bar to filter items by name
5. Click on any item card to see full details and optionally remove it

### Enhanced Data from Server

When selecting a player, the server enriches `getPlayerDetails` with:
- **Weapon components** — Attachments on each weapon (suppressor, grip, scope, etc.)
- **Categories** — `weapon`, `ammo`, `attachment`, `clothing`, `item`
- **Serial numbers** — Weapon serials
- **Durability** — HP/Metadata for wearables and weapons

### UI Features

- **Stats Bar** — Shows player at the top (name, citizenid, job)
- **Category Filters** — Row of buttons for quick filtering
- **Search Bar** — Real-time text search
- **Item Cards** — Icon, label, count, durability bar, component chips
- **Detail Modal** — Full item info + red "Remove" button with quantity input

### Server Events

| Event/Callback | Description |
|---------------|-------------|
| `god:server:removePlayerItem` | Remove item from player inventory |

---

## 4. Ban / Kick Management

### Phase 2 Feature

| Tab | "Bans" in god-menu |
|-----|-------------------|

### How to Use

**View Active Bans:**
1. Open god-menu → Bans tab
2. Table shows: Name, Identifier, Reason, Banner, Duration, Remaining Time, Unban button

**Ban a Player:**
1. Go to Players tab first, select a player
2. Click "Ban" in the player details section
3. Choose duration: 1h / 6h / 24h / 7d / 30d / Permanent / Custom (seconds)
4. Enter reason and confirm
5. Player is kicked with ban message and the ban is saved

**Unban:**
- Click the red "Unban" button in the bans table
- Ban is removed from the `bans` table

### Server Events

| Event/Callback | Description |
|---------------|-------------|
| `godGetActiveBans` | Returns all active bans (not expired) |
| `godSearchBans` | Search bans by name/identifier |
| `godExecuteBan` | Create a ban + kick the player |
| `godExecuteUnban` | Remove a ban by ID |

### Ban Duration Options

| Label | Seconds |
|-------|---------|
| 1 Hour | 3600 |
| 6 Hours | 21600 |
| 24 Hours | 86400 |
| 7 Days | 604800 |
| 30 Days | 2592000 |
| Permanent | -1 (no expiry) |
| Custom | User-defined |

### Database Table

```sql
bans (
    id INT AUTO_INCREMENT PRIMARY KEY,
    identifier VARCHAR(64) NOT NULL,
    player_name VARCHAR(64) DEFAULT NULL,
    reason TEXT NOT NULL,
    banner VARCHAR(64) DEFAULT NULL,
    banned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at INT DEFAULT -1,
    active TINYINT(1) DEFAULT 1
)
```

---

## 5. Vehicle Garage Viewer

### Phase 3 Feature

| Tab | "Garage" in god-menu |
|-----|---------------------|

### How to Use

1. Open god-menu → Garage tab
2. Enter a **CitizenID** and click "Search"
3. See player's vehicles with summary: **Stored / Out / Impounded** counts
4. Each vehicle card shows: model name, plate, fuel level, status badge
5. Actions per vehicle:
   - **Spawn** — Admin-spawns the vehicle at your location
   - **Delete** — Deletes the vehicle from existence
   - **Impound** — Sends vehicle to impound lot
   - **Release** — Releases an impounded vehicle back to garage

### Server Events

| Event/Callback | Description |
|---------------|-------------|
| `godGetPlayerGarage` | Query `player_vehicles` + `impounded_vehicles` for a citizenid |
| `godAdminSpawnPlayerVehicle` | Spawn a specific vehicle by plate near admin |
| `godAdminDeletePlayerVehicle` | Delete vehicle from DB + entity |
| `godAdminImpoundVehicle` | Add to `impounded_vehicles` |
| `godAdminReleaseImpound` | Remove from `impounded_vehicles` |

### Queries

```sql
-- Player vehicles
SELECT * FROM player_vehicles WHERE citizenid = ?

-- Impounded vehicles
SELECT * FROM impounded_vehicles WHERE citizenid = ? AND released = 0
```

---

## 6. Staff Management

### Phase 4 Feature

| Tab | "Staff" in god-menu |
|-----|-------------------|

### How to Use

1. Open god-menu → Staff tab
2. See all online staff members as cards
3. Each card shows: name, citizenid, **group badge** (color-coded), online time
4. Actions:
   - **Promote** — Promote to a higher rank (dropdown with available ranks)
   - **Demote** — Demote to a lower rank (dropdown with available ranks)
   - **Log** — View action log for that staff member

### Rank Hierarchy

```
god (3) > superadmin (2) > admin (1) > user (0)
```

- You cannot promote someone to a rank >= your own rank
- You cannot demote someone with rank >= your own rank
- Color coding: admin = blue, superadmin = purple, god = gold

### Server Events

| Event/Callback | Description |
|---------------|-------------|
| `godGetOnlineStaff` | Returns all staff players with their groups |
| `godSetStaffGroup` | Change a player's group (with hierarchy check) |
| `godGetStaffActionLog` | Query action logs for a specific player |

### Action Logging

Staff actions are logged to a `staff_action_log` table (configurable). The log captures:
- Action type
- Target player
- Timestamp

---

## 7. Report Queue

### Phase 6 Feature

| Tab | "Reports" in god-menu |
|-----|---------------------|

### How to Use

1. Open god-menu → Reports tab
2. See open and handling reports with counts
3. Each report card shows: player name, reason, status, citizenid
4. Actions:
   - **Accept** — Claim a report (status → "handling", your name attached)
   - **Close** — Resolve a report (prompt asks for resolution text)

### Badge on Nav

The Reports tab shows a red badge with the count of **open** reports. Updates in real-time.

### How Reports Flow

1. Player submits a report via `report:server:submit` (from report-system resource)
2. God-menu hooks into that event and stores in `activeReports` (in-memory table)
3. Pushes to all god-menu clients: `TriggerClientEvent('god:client:newReport', -1, report)`
4. When accepted/closed, pushes updates: `god:client:updateReport` / `god:client:removeReport`

### Server Events

| Event/Callback | Description |
|---------------|-------------|
| `godGetReports` | Returns all active reports |
| `godAcceptReport` | Set report status to "handling", assign staff name |
| `godCloseReport` | Remove report, log resolution |

### Ephemeral Storage

Reports are stored **in-memory** only (`activeReports` table). They are lost on server restart. This is intentional — reports are ephemeral by nature (live session support).

---

## 8. Drag System

### Overview

Standalone resource that allows police to drag cuffed players and EMS to drag knocked (downed) players. Supports forcing the dragged player into a vehicle.

| Resource | Path |
|----------|------|
| `drag-system` | `resources/[player]/drag-system/` |

### Dependencies

- `ox_lib` — Notifications
- `ox_target` — Interaction with players
- `qbx_core` — QBox core
- `cuff-system` — `exports['cuff-system']:IsCuffed(src)` + `GetCuffer()`
- `wasabi-ambulance` — `exports['wasabi-ambulance']:IsPlayerDown(src)`

### Configuration (`config.lua`)

```lua
Config.Drag = {
    policeGroups = { 'police', 'sheriff', 'statepolice' },
    emsGroups = { 'ambulance', 'ems', 'doctor' },
    dragDistance = 1.8,       -- Distance to start drag
    forceCarDistance = 2.5,   -- Distance to detect open door for vehicle force
    releaseKey = 38,          -- E key
}
```

### How It Works

**Starting a Drag:**
1. Stand near a cuffed or downed player (< `dragDistance`)
2. An ox_target option appears: "🔗 Drag Cuffed Player" or "🏥 Drag Injured Player"
3. Click it → drag starts

**While Dragging:**
- Target player's position is forced near the dragger
- Target player is ragdolled
- Target has most controls disabled
- If dragger moves too far (> 3.0), drag auto-stops with error notification

**Force Into Vehicle:**
1. Walk near a vehicle with an **open door**
2. A notification appears: "Press E to force into vehicle"
3. Press E → target is placed in the nearest open seat
4. Drag session ends

**Force Out of Vehicle (Extract):**
1. While dragging someone who is sitting in a vehicle
2. A notification appears: "Press E to pull out of vehicle"
3. Press E → target is yanked out of the vehicle via `TaskLeaveVehicle` + placed near the dragger + ragdolled
4. Drag session continues — you keep dragging them on foot

**Releasing:**
- Press `E` (key 38) to release the dragged player at any time
- Only works when no vehicle action is active (avoids conflicts)

### Server Events

| Event | Description |
|-------|-------------|
| `drag:server:startDrag` | Start drag session (checks role + canDragTarget) |
| `drag:server:stopDrag` | End drag session, clean up |
| `drag:server:forceIntoVehicle` | Place target into vehicle, end session |
| `drag:server:forceOutOfVehicle` | Pull target out of vehicle, continue dragging |

### Client Events

| Event | Description |
|-------|-------------|
| `drag:client:startDrag` | Start dragger follow loop |
| `drag:client:beingDragged` | Enable ragdoll + disable controls |
| `drag:client:stopDrag` | Stop dragger loop |
| `drag:client:stopBeingDragged` | Unfreeze, re-enable collision |
| `drag:client:forceIntoVehicle` | NetToVeh → SetPedIntoVehicle |

### Cleanup

When a player disconnects (`playerDropped`), their drag session is cleaned up:
- Dragged target is unfrozen
- Session table entries removed

---

## 9. iPhone Vehicles App

### Overview

Adds a **Vehicles** app to the iPhone phone system. Players can:
- View all owned vehicles
- Toggle engine on/off remotely
- Toggle door locks remotely
- Track vehicle location (waypoint)

### Files Modified

| File | Lines | Change |
|------|-------|--------|
| `resources/[phones]/iphone/config.lua:37-39` | +3 | Added Vehicles app config entry |
| `resources/[phones]/iphone/server/main.lua:722-794` | +73 | Server callbacks: getVehicles, toggleLock, toggleEngine, trackVehicle |
| `resources/[phones]/iphone/client/main.lua:417-444` | +28 | Client NUI callbacks proxy to server |
| `resources/[phones]/iphone/web/script.js` | +vehicles | `renderVehiclesApp()` + SVG car icon |
| `resources/[phones]/iphone/web/style.css` | +vehicles | Vehicle card CSS |

### Server Callbacks

| Callback | Description |
|----------|-------------|
| `vehicleApp:getVehicles` | Query `player_vehicles` by citizenid, return list with fuel, state, location |
| `vehicleApp:toggleLock` | Server-side: iterate `GetAllVehicles()`, find by plate, toggle door lock |
| `vehicleApp:toggleEngine` | Server-side: find vehicle by plate, toggle engine state |
| `vehicleApp:trackVehicle` | Return coords of vehicle by plate, client sets waypoint |

### Vehicle Query Logic

```lua
-- Server queries player_vehicles by citizenid
-- For each vehicle, checks if it exists in the world:
for _, veh in ipairs(GetAllVehicles()) do
    if GetVehicleNumberPlateText(veh) == v.plate then
        -- Found in world: get fuel, lock state, engine state, coords
    end
end
-- If not found in world: mark as "In Garage"
```

### UI Features

- **Vehicle Cards** — Model name, plate, fuel bar (green/yellow/red)
- **State Badges** — "Stored" (garage), "Out" (+ lock/engine status)
- **Buttons** — Lock/Unlock (toggles), Engine On/Off, Track (sets waypoint)
- **Empty State** — "No vehicles found" message

---

## 10. CDN-HUD (NUI Overlay)

### Overview

Replaced the original cdn-hud's native Lua drawing with a modern **glass-morphism** NUI-based HUD. Uses CSS backdrop-blur, gradients, and smooth animations.

| Resource | `cdn-hud` |
|----------|-----------|
| Files | `resources/[player]/cdn-hud/web/` (index.html, style.css, script.js) |
| Client | `resources/[player]/cdn-hud/client/main.lua` — `sendHudUpdate()` → `SendNUIMessage` |
| Dependency | `cdn-fuel` REMOVED from fxmanifest |

### Data Sent to NUI (18 fields)

The client sends `SendNUIMessage` with a `hudUpdate` action containing:

| Field | Description |
|-------|-------------|
| `health` | Player health (0-100) |
| `armor` | Player armor (0-100) |
| `hunger` | Hunger level (0-100) |
| `thirst` | Thirst level (0-100) |
| `stress` | Stress level (0-100) |
| `cash` | Cash amount |
| `bank` | Bank balance |
| `job` | Job name |
| `jobGrade` | Job grade name |
| `inVehicle` | Boolean |
| `seatbelt` | Boolean |
| `speed` | Speed in km/h |
| `fuel` | Fuel level (0-100) |
| `engineOn` | Boolean |
| `street` | Current street name |
| `crossing` | Crossing street name |
| `area` | Area/zone name |
| `showHud` | Boolean — toggle HUD visibility |

### Fuel Reading Priority

```lua
-- In client/main.lua (sendHudUpdate)
local fuel = Entity(vehicle).state.fuel           -- 1. State bag
if not fuel then fuel = GetVehicleFuelLevel(vehicle) end  -- 2. Native
if not fuel then fuel = 100.0 end                 -- 3. Fallback
```

### HUD Layout

- **Top Bar** — Money display (cash/bank icons) + job badge
- **Status Bars** — 5 bars: Health (red), Armor (blue), Hunger (orange), Thirst (cyan), Stress (purple) — each with icon + percentage
- **Vehicle HUD** — Only visible when in a vehicle: speedometer, fuel bar, engine indicator, seatbelt indicator
- **Street Info** — Current street + crossing street

### Style Highlights

- `backdrop-filter: blur(12px)` on all panels
- Smooth CSS transitions for bar widths (0.5s ease)
- Color transitions at thresholds (health < 25 → pulsing red, fuel < 15 → pulsing yellow)
- `@keyframes pulse` for critical alerts
- `font-family: 'Segoe UI', sans-serif`

---

## 11. Quick Fixes Applied

### Tackle Fix (`resources/[police]/tackle/server/main.lua`)

| Issue | Fix |
|-------|-----|
| `exports['qbx-core']` | Changed to `exports['qbx_core']` (underscore) |
| `Wrappers.Notify(src, ...)` | Replaced with `TriggerClientEvent('ox_lib:notify', src, { type, description })` |
| `Locale('police.not_on_duty')` | Inlined: `'You are not on duty'` |
| `Locale('police.player_not_found')` | Inlined: `'Player not found'` |
| `exports['discord-logs']:LogCustom(...)` | Wrapped in `pcall()` so it doesn't crash if resource missing |

### Person Search Fix (`resources/[police]/person-search/server/main.lua`)

| Issue | Fix |
|-------|-----|
| `TriggerClientEvent('admin:deleteVehicle', -1, plate)` — nonexistent event | Replaced with native `GetAllVehicles()` + `GetVehicleNumberPlateText()` + `DeleteEntity()` server-side |

---

## 12. Database Schema

### `admin_managed_doors` — Admin Door Lock System

```sql
CREATE TABLE IF NOT EXISTS admin_managed_doors (
    id INT AUTO_INCREMENT PRIMARY KEY,
    door_id VARCHAR(128) NOT NULL UNIQUE,
    label VARCHAR(128) NOT NULL DEFAULT 'Unknown Door',
    model_hash INT NOT NULL DEFAULT 0,
    coords JSON NOT NULL,
    locked TINYINT(1) NOT NULL DEFAULT 1,
    mode ENUM('permanent','passcode','job') NOT NULL DEFAULT 'permanent',
    passcode_hash VARCHAR(64) DEFAULT NULL,
    allowed_jobs JSON DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### `bans` — Ban Management

```sql
CREATE TABLE IF NOT EXISTS bans (
    id INT AUTO_INCREMENT PRIMARY KEY,
    identifier VARCHAR(64) NOT NULL,
    player_name VARCHAR(64) DEFAULT NULL,
    reason TEXT NOT NULL,
    banner VARCHAR(64) DEFAULT NULL,
    banned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at INT DEFAULT -1,
    active TINYINT(1) DEFAULT 1
);
```

---

## 13. Security & Access Control

### isOwner() Pattern

Every server-side event in god-menu starts with `if not isOwner(source) then return end`.

The `isOwner()` function checks in this order:
1. **Config override** — `Config.GodMenu.ownerIdentifiers` (hardcoded Steam hexes always pass)
2. **DB cache** — In-memory table populated from `server_owners` table on resource start and player join
3. **Denied** — If neither matches, return false

First joiner auto-assignment happens via `playerJoining` handler:
- Checks `SELECT COUNT(*) FROM server_owners WHERE group_name = 'god'`
- If zero, inserts `INSERT INTO server_owners (identifier, group_name)` with the player's Steam hex
- Cache is refreshed immediately

Clients call `lib.callback('god:server:checkOwner')` before opening the menu UI.

### Drag System Role Check

```lua
local function getPlayerGroup(src)
    local group = p.PlayerData.group
    local job = p.PlayerData.job and p.PlayerData.job.name or ''
    if group == 'god' or group == 'superadmin' or group == 'admin' then return 'admin' end
    -- Check policeGroups table
    -- Check emsGroups table
    return nil  -- Not allowed
end
```

### Staff Rank Hierarchy

```
god(3) > superadmin(2) > admin(1) > user(0)
```

Promote/demote blocked if:
- Target rank >= your rank
- You try to promote someone to your own rank or higher

---

## 14. Troubleshooting

### Door Highlight Not Showing

The cyan highlight box uses `DrawBox(coords.x, coords.y, coords.z - 1, coords.x, coords.y, coords.z + 2, 0, 255, 255, 100)` which only renders within ~100m. Make sure you're standing close to the detected door.

### ox_target Zone Not Appearing

Ensure `ox_target` is in the resource's `dependencies` in fxmanifest. Verify `ox_target` resource is started before `god-menu` in server.cfg.

### Drag System Not Working

1. Check that all dependencies exist and exports work:
   - `exports['cuff-system']:IsCuffed(src)` — must return true/false
   - `exports['wasabi-ambulance']:IsPlayerDown(src)` — must return true/false
2. Verify the target is in the correct job group (policeGroups or emsGroups in config)
3. Check server console for errors — the drag system depends on specific export names

### Fuel Not Showing in HUD

The HUD reads fuel in this order:
1. `Entity(vehicle).state.fuel` — State bag (set by most fuel scripts)
2. `GetVehicleFuelLevel(vehicle)` — Native function
3. Falls back to `100.0`

If neither works, ensure your fuel script sets the `fuel` state bag on vehicles.

### Ban System Not Kicking Player

The `godExecuteBan` callback calls `QBox.Functions.Kick(identifier, reason)`. Check that `QBox.Functions.Kick` works in your qbx_core version. Some versions use `DropPlayer(source, reason)` instead.

### Report Queue Empty

The report queue hooks into `report:server:submit` event. If your report-system uses a different event name, the queue won't populate. Check the existing report system's event names.

---

## 15. Ported Resources (from qb-core → qbx_core)

### Loading Screen (`[polish]/loading-screen-new`)
- **Source**: qb-loading-main (standalone, no Lua)
- **Vue3/Quasar** carousel with background images, tips, keybinds display, settings dialog
- Loading progress bar via FiveM native loading events
- Supports audio, video, and image backgrounds
- No framework dependencies — pure HTML/JS/CSS

### Radio (`[player]/radio`)
- **Source**: qb-radio → ported to qbx_core
- Full radio UI with channel input, volume control, channel cycling, power off
- Integrates with **pma-voice** for voice channel switching
- Restricted channels by job (police, ems, etc.)
- Handheld radio animation + prop
- `/radio` keybind to open/close
- **Dependencies**: qbx_core, ox_lib, pma-voice

### Spawn Selector (`[core]/spawn-selector`)
- **Source**: qb-spawn → ported to qbx_core
- Vue2/Vuetify spawn UI with camera fly-through to each location
- 4 default spawns: Legion, Police DP, Paleto Bay, Motel
- Supports "last location" spawn (remembers where you left)
- Simplified to work without qb-apartments/qb-houses
- Camera transitions from high altitude → ground level
- **Dependencies**: qbx_core, ox_lib, oxmysql

### Radial Menu (`[player]/radialmenu`)
- **Source**: qb-radialmenu → ported to qbx_core
- SVG-based radial menu with keyboard (1-9) and mouse wheel navigation
- **Vehicle controls**: doors (4), extras (1-13), seat switching, engine, trunk
- **Clothing system**: Full drawable/prop toggle (hat, glasses, mask, top, pants, shoes, etc.)
- **Trunk system**: Enter/exit trunk, kidnap integration
- **Stretcher system**: EMS stretcher spawn/attach/lay
- **Job interactions**: per-job menus (police, ambulance, mechanic, taxi, tow)
- **Keybind**: F1 (configurable)
- **Dependencies**: qbx_core, ox_lib

### HUD (`[player]/hud`)
- **Source**: qb-hud → ported to qbx_core
- Vue3/Quasar HUD with **circular progress bars** (health, armor, hunger, thirst, stress, oxygen)
- **Vehicle HUD**: speedometer, fuel gauge, altitude, seatbelt, cruise, nitrous, harness
- **Compass system**: dynamic compass with N/NE/E/SE/S/SW/W/NW markers
- **Street display**: current street + crossing street names
- **Minimap**: toggleable square/circle shape, borders, zoom
- **Stress system**: automatic stress gain from speeding/shooting with screen blur, ragdoll effects
- **Cinematic mode**: black bars top/bottom, hides HUD
- **Settings menu** (I key): toggle every HUD element individually
- **Money display**: cash/bank amounts with change animation
- **Fuel alerts**: warning at 20% fuel
- **Radio indicator**: shows when on radio
- **Dependencies**: qbx_core, ox_lib, pma-voice

## File Index

```
resources/
├── [admin]/god-menu/
│   ├── config.lua                    ← Owner identifiers, presets, items
│   ├── fxmanifest.lua               ← ox_target dependency
│   ├── server/main.lua              ← All server events (881 lines → 974 with auto-owner)
│   ├── client/main.lua              ← All NUI callbacks + door zones (833 lines)
│   └── html/
│       ├── index.html               ← Full UI with all tabs (621 lines)
│       ├── script.js                ← All JS logic (1236 lines)
│       └── style.css                ← All styles including new features (885 lines)
│
├── [core]/spawn-selector/           ← NEW (ported from qb-spawn)
│   ├── fxmanifest.lua              ← qbx_core, ox_lib
│   ├── config.lua                  ← Spawn locations
│   ├── client.lua                  ← Camera + UI control
│   └── server.lua                  ← Callbacks
│
├── [player]/hud/                    ← NEW (ported from qb-hud, replaces cdn-hud)
│   ├── fxmanifest.lua              ← qbx_core, ox_lib, pma-voice
│   ├── config.lua                  ← All HUD toggles + stress config
│   ├── client.lua                  ← Main HUD loop, compass, stress effects
│   ├── server.lua                  ← Stress + commands
│   └── html/                       ← Vue3/Quasar UI
│
├── [player]/radio/                  ← NEW (ported from qb-radio, replaces old radio)
│   ├── fxmanifest.lua              ← qbx_core, ox_lib, pma-voice
│   ├── config.lua                  ← Channels, restrictions
│   ├── client.lua                  ← Radio UI + pma-voice integration
│   ├── server.lua                  ← Channel access + useable item
│   └── html/                       ← Radio UI
│
├── [player]/radialmenu/             ← NEW (ported from qb-radialmenu)
│   ├── fxmanifest.lua              ← qbx_core, ox_lib
│   ├── config.lua                  ← Menu items, jobs, trunk classes
│   ├── client/                     ← main.lua, clothing.lua, trunk.lua, stretcher.lua
│   ├── server/                     ← trunk.lua, stretcher.lua
│   └── html/                       ← SVG radial menu
│
├── [player]/drag-system/            ← Drag system
│   ├── fxmanifest.lua              ← ox_lib, ox_target, qbx_core, cuff-system, wasabi-ambulance
│   ├── config.lua                  ← Police/EMS groups, distances, key
│   ├── server/main.lua             ← Drag sessions, role checks, force in/out
│   └── client/main.lua             ← ox_target, follow loop, ragdoll, vehicle force
│
├── [polish]/loading-screen-new/     ← NEW (ported from qb-loading, replaces old loading)
│   ├── fxmanifest.lua              ← Standalone (no deps)
│   └── html/                       ← Vue3/Quasar carousel
│
├── [phones]/iphone/
│   ├── config.lua                  ← Vehicles app entry
│   ├── server/main.lua             ← vehicleApp callbacks
│   ├── client/main.lua             ← Vehicle NUI callbacks
│   └── web/                        ← Vehicle cards UI
│
├── [shared]/database/
│   └── master_schema.sql           ← admin_managed_doors + bans tables
│
└── (DISABLED — renamed to *-DISABLED)
    ├── [player]/cdn-hud-DISABLED           ← Replaced by [player]/hud
    ├── [polish]/radio-DISABLED             ← Replaced by [player]/radio
    ├── [polish]/loading-screen-DISABLED    ← Replaced by loading-screen-new
    └── [polish]/admin-menu-DISABLED        ← Replaced by [admin]/god-menu
```

---

## 16. New Resources (Phase 2)

### 16.1 Server Guide (`[polish]/server-guide`)

**Purpose**: In-game `/rules` command opens a styled NUI modal with Server Rules, Key Binds, and Staff Contacts tabs.

| File | Purpose |
|------|---------|
| `fxmanifest.lua` | ox_lib + qbx_core deps |
| `config.lua` | All rules, keybinds, staff contacts, color scheme |
| `client/main.lua` | `/rules` command, NUI open/close callbacks |
| `server/main.lua` | Empty (reserved for future use) |
| `html/index.html` | Modal layout with header, tabs, content area |
| `html/style.css` | Glass-morphism dark theme with accent color |
| `html/script.js` | Tab switching, rule/keybind/staff rendering |

**Commands**: `/rules` — Opens the server guide modal.

**Config**: All content in `config.lua` — rules, keybinds, staff contacts, and colors are fully customizable.

### 16.2 Vehicle Keys + Lockpick Mini-Game (`[player]/vehicle-keys`)

**Purpose**: Full vehicle key system with lockpick mini-game, lock/unlock, and key transfer.

**Features**:
- **Vehicle Keys** — `vehicle_key` item with plate metadata stored in ox_inventory
- **Lock/Unlock** — Via radial menu ("Lock/Unlock") or `/vehiclelock` keybind (L key)
- **Lockpick Mini-Game** — NUI canvas-based rotating needle + sweet spot arc:
  - Needle rotates clockwise at configurable speed
  - Golden "sweet spot" arc at random position each round
  - Player clicks when needle is inside the sweet spot
  - 4 successful rounds → vehicle starts
  - 3 failed rounds total → lockpick breaks + chance of alarm
  - Difficulty varies by vehicle class (luxury = smaller sweet spot)
- **Give Key** — Radial menu → "Give Vehicle Key" → select key → nearest player receives it
- **Create Key** — Radial menu → "Create Vehicle Key" for owned/admin vehicles
- **/givekey** — Admin command: `/givekey [plate] [player_id]`

**Files**:

| File | Purpose |
|------|---------|
| `fxmanifest.lua` | ox_lib, qbx_core, ox_inventory deps |
| `config.lua` | Lockpick difficulty per vehicle class, ranges, timings |
| `client/main.lua` | Lock/unlock, lockpick trigger, radial events, NUI callbacks |
| `server/main.lua` | Key DB ops, exports (`HasVehicleKey`, `GiveKeyToPlayer`), `/givekey` |
| `html/index.html` | Lockpick mini-game layout (canvas, round/fail display) |
| `html/style.css` | Dark terminal theme for lockpick UI |
| `html/script.js` | Canvas rendering, needle animation, sweet spot detection, click handling |

**Dependencies**: qbx_core, ox_lib, ox_inventory

**Item**: `vehicle_key` (non-stackable, plate/model in metadata, image: `carkey.png`) — added to `ox_inventory/data/items.lua`. `lockpick` item already existed, now stack=false with description.

**Key Generation**: The `/givecar` admin command in `admin-commander` now auto-generates a vehicle key for the recipient via `exports['vehicle-keys']:GiveKeyToPlayer()`.

**Radial Menu Integration**: "Vehicle Keys" submenu added under "General" in `[player]/radialmenu/config.lua`:
- Lock/Unlock → `vehicle-keys:radial:Lock`
- Lockpick Vehicle → `vehicle-keys:radial:Lockpick`
- Give Vehicle Key → `vehicle-keys:radial:GiveKey`
- Create Vehicle Key → `vehicle-keys:radial:CreateKey`

### 16.3 Tool Shop (`ox_inventory` built-in)

**Purpose**: Black-market tool shop selling heist equipment. Uses ox_inventory's built-in shop system — no custom resource needed.

**Location**: Temporary warehouse location (`vec3(723.49, -964.57, 24.0)`) until MLO is provided.

**Inventory**:

| Item | Price | Notes |
|------|-------|-------|
| `lockpick` | $5,000 | Consumable — breaks on failed lockpick attempt |
| `drill` | $25,000 | Consumed after vault drill phase |
| `hack_usb` | $15,000 | Consumed after terminal hack phase |
| `c4_charge` | $35,000 | Consumed after detonation |
| `heist_mask` | $2,000 | Reusable disguise item |

**Implementation**: Single entry added to `ox_inventory/data/shops.lua` with blip (toolbox icon, red), target zones, and item listings. Regular cash currency. No job restriction.

**Updating**: When MLO is provided, edit `ToolShop.locations[1]` and `ToolShop.targets[1]` in `shops.lua`.

---

### 16.4 Crime Scene Investigation — Forensics (`[polish]/forensics`)

**Purpose**: Crime scene evidence collection and analysis terminal for CID investigators.

**Items** (added to `ox_inventory/data/items.lua`):

| Item | Weight | Description |
|------|--------|-------------|
| `evidence_bag` | 20 | Sterile bag for storing collected evidence. Stack=false, consume=0 |
| `fingerprint_kit` | 200 | Use on surfaces to lift fingerprints. Export: `forensics.collectFingerprint` |
| `casing_kit` | 250 | Use near recent gunfire to collect shell casings. Export: `forensics.collectCasing` |
| `dna_swab` | 150 | Use on blood pools to collect DNA samples. Export: `forensics.collectDNA` |

**Collection Flow**:
1. Player stands near evidence source (blood pool, shell casing, surface)
2. Uses the appropriate kit item from inventory
3. 3-second progress bar with animation
4. Evidence is bagged in `evidence_bag` (if available) or stored loose
5. Evidence contains metadata: type, data, coords, timestamp, evidence ID, collector name

**Analysis Terminal**:
- Located at CID HQ: `vec3(-1454.36, -519.81, 29.88)`
- Blue marker visible in world
- Press E at terminal to open analysis NUI
- Left panel: list of evidence items in inventory
- Right panel: analysis results
- Click "Run Analysis" → progress bar → server callback → result

**Analysis Types**:
- **Fingerprint**: Checks against `criminal_records` DB table (random match with 60% chance if records exist)
- **Casing**: Reconstructs weapon hash, checks against hypothetical `registered_weapons` table
- **DNA**: Checks against `criminal_records` DB table (random match with 70% chance)

**Files**:

| File | Purpose |
|------|---------|
| `fxmanifest.lua` | ox_lib, qbx_core, ox_inventory deps |
| `config.lua` | Collection range, terminal location, marker settings |
| `client/main.lua` | Item use exports, collection logic, terminal interaction, NUI callbacks |
| `server/main.lua` | `forensics:getEvidence` + `forensics:analyzeEvidence` callbacks |
| `html/index.html` | Split-panel terminal UI (evidence list + analysis panel) |
| `html/style.css` | Dark CID-themed terminal with color-coded evidence types |
| `html/script.js` | Evidence list rendering, analysis trigger, result display |

### 16.4 Multi-Heist System (`[criminal]/multi-heists`)

**Purpose**: Four heist types with phased execution, police alerts, and loot distribution.

**Heist Types**:

| Heist | Payout | Phases | Required Items | Cooldown |
|-------|--------|--------|----------------|----------|
| **Fleeca Bank** | $50k-$100k | Drill Vault → Hack Terminal → Grab Cash | drill, hack_usb | 15m |
| **Jewelry Store** | $80k-$150k | Smash Cases → Collect Jewelry → Bag Loot | None | 20m |
| **Bank Truck** | $100k-$200k | Stop Truck → Place C4 → Detonate & Loot | c4_charge | 25m |
| **Paleto Bay Bank** | $200k-$400k | Cut Power → Drill Vault → Drill Inner → Hack → Secure Loot → Hold Off Police | drill, hack_usb, c4_charge | 40m |

**New Items** (added to `ox_inventory/data/items.lua`):

| Item | Weight | Description |
|------|--------|-------------|
| `drill` | 3000 | Industrial drill for vault doors and safes |
| `hack_usb` | 50 | USB with bypass software for security terminals |
| `c4_charge` | 2500 | Explosive charge for breaching reinforced doors |
| `heist_loot` | 500 | Assorted valuables needing laundering. Metadata: value, source, time |
| `heist_mask` | 100 | Disposable mask for concealing identity. Export: `multi-heists.wearMask` |

**Gameplay Flow**:
1. **Start**: Player approaches heist location marker (above entry) and presses E
2. **Requirements**: Server checks police count (3 minimum), cooldown, required items
3. **Phases**: Each phase requires player to be at the location and press E:
   - Generic phases: progress bar with animation
   - Drill phases: Creates a drill object at vault location, plays drill animation
   - C4 phases: Progress bar + explosion effect on detonation
   - Hack phases: Opens NUI Simon Says pattern-matching mini-game
   - Hold phase: Timer countdown (defend position)
4. **Police Alerts**: Triggered at configured phase (phase 0 for police-heavy heists). Adds red blip + notification to all on-duty LEO
5. **Completion**: Loot distributed equally among participants as `heist_loot` items with value metadata
6. **Cooldown**: Per-heist cooldown prevents repeat runs

**Hack Mini-Game (Simon Says)**:
- Random sequence of 4-8 colored blocks shown (difficulty-dependent)
- Player must repeat the sequence by clicking blocks
- 4 rounds of increasing sequence length
- Succeed → bypass complete, fail → heist phase fails

**Bank Truck**:
- Random spawn timer (30-60 min intervals)
- All non-LEO players notified with blip on truck route
- Manual start at truck location

**Files**:

| File | Purpose |
|------|---------|
| `fxmanifest.lua` | ox_lib, qbx_core, ox_inventory deps |
| `config.lua` | All 4 heist definitions with locations, phases, loot, items |
| `client/main.lua` | Heist location markers, phase execution, drill/C4/hold logic, hack NUI, police alerts |
| `server/main.lua` | Heist state machine, police checks, loot distribution, bank truck spawner |
| `html/index.html` | Simon Says hack mini-game grid |
| `html/style.css` | Dark terminal theme for hack UI |
| `html/script.js` | Pattern generation, display, click handling, round progression |

### 16.5 Animation Menu (`[player]/anim-menu`)

**Purpose**: Full emote system integrated directly into the radial menu. Browse and play animations by category.

**Key Features**:
- **7 categories**: Dances (6), Gestures (10), Idles (8), Expressions (6), Greetings (5), Actions (12), Walk Styles (20)
- **Access via radial menu** (F1 → Emotes section) — each category opens an ox_lib context menu with specific animations
- **Walk Styles** — Set walking style via `SetPedMovementClipset`, or reset to default
- **Expressions** — Use `SetFacialIdleAnimOverride` for persistent facial expressions
- **Cancel** — X key, `/cancel` command, or radial option stops all animations
- **Commands**: `/anim [name]` plays a specific emote by command name, `/cancel` stops
- **Exports**: `PlayEmote(command)`, `StopEmote()`, `SetWalkStyle(styleName)`

**Files**:

| File | Purpose |
|------|---------|
| `fxmanifest.lua` | ox_lib + qbx_core deps |
| `config.lua` | All animation definitions organized by category |
| `client/main.lua` | Animation playback, walk style setting, context menus, cancel key |

**Radial Menu Integration**: "Emotes" section added to `[player]/radialmenu/config.lua` with items for each category + Cancel Emote.

**Dependencies**: qbx_core, ox_lib

---

### 16.6 Anticheat Integration (`[polish]/anticheat`)

**Purpose**: Server-side cheat detection with strike escalation and admin notifications.

**Detection Types**:
- **Health changes**: Monitors health per tick, flags changes > 5
- **Armour changes**: Monitors armour per tick, flags changes > 5
- **Teleport detection**: Flags distance > 300m between ticks
- **Velocity detection**: Flags speed > 250 km/h
- **Weapon blacklist**: Removes blacklisted weapons (railgun, minigun, RPG)
- **Client reports**: `anticheat:report` event with rate limiting (5/min)

**Strike System**:
- Each detection adds a strike to the player
- Strikes reset on disconnect
- **3 strikes** → automatic ban + kick with message
- All strikes logged to Discord webhook + `admin_logs` DB table

**Admin Notifications**:
- Police, FIB, and admin job players receive in-game `[ANTICHEAT]` alerts
- Strike count and reason displayed
- Auto-ban announcements broadcast to staff

**Configuration** (`config.lua`):
- `detectionInterval`: 5000ms
- `maxHealthChanges`: 5
- `maxArmourChanges`: 5
- `maxTeleportDistance`: 300m
- `maxVelocity`: 250 km/h
- `maxStrikes`: 3
- `weaponBlacklist`: `{ 'WEAPON_RAILGUN', 'WEAPON_MINIGUN', 'WEAPON_RPG' }`

**Files Modified**:
- `server/main.lua` — Complete rewrite with strike tracking, admin alerts, auto-ban
- `config.lua` — Added `maxStrikes` setting

