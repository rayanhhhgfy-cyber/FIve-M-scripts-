# Five M Server — Complete Setup Guide

## 📦 What Was Added This Session

### 1. Bodycam Auto-On Duty
When you go on duty as police/CID, your bodycam **turns on automatically** and starts recording. When you go off duty, it stops.
- Bodycam key: **L** (toggle manually too)
- Now works for **CID** as well
- Config: `resources/[police]/bodycam/config.lua`

### 2. P-List (Personnel List) — `/plist` or **F6**
Shows every police/CID officer currently on duty, their name, job, rank, and what radio channel they're on.
- Press **F6** or type `/plist`
- Shows **count** of active officers at the top
- Updates live every 3 seconds
- Dark glassmorphism UI on the right side of screen

### 3. On-Duty Map Blips
When you go on duty, other police/CID can see your **blue blip** on the map with your name. When you go off duty, the blip disappears.
- Police = blue blip
- CID = dark blue/purple blip
- Updates every 5 seconds

### 4. FIB Building
Brand new FIB building MLO at the Pillbox area with:
- **Elevator** with door sounds, fade transitions, and floor selection
- **Computer terminals** you can use to check building status, date, BOLOs
- **Access control** — only police/CID can enter, CID gets restricted floors
- Elevator floors: Lobby, Offices, Armory, Interrogation, Server Room, Roof (rank-gated)

---

## 🚀 Step-by-Step: What You MUST Do to Launch

### Step 1 — Get a Server
You need a FiveM server to run this. Options:
- Use a hosting company (e.g., ZAP-Hosting, GTANet, OVH) — $5-15/month
- Use a friend's PC as a server

### Step 2 — Upload Files
Upload the entire `resources/` folder to your server's resources directory.

### Step 3 — Configure server.cfg
The file at `resources/server.cfg` is your main config. Edit these:

```
# Change your server name
sv_hostname "YOUR SERVER NAME HERE"

# Your Steam API key (get from https://steamcommunity.com/dev/apikey)
set steam_webApiKey "YOUR_KEY_HERE"

# Optional: server icon (place logo.png in resources folder)
load_server_icon logo.png
```

### Step 4 — Database Setup
1. Open `resources/[shared]/database/master_schema.sql`
2. Copy all the SQL
3. Run it on your **MySQL database** (your hosting company gives you database access)
4. This creates all tables the server needs

### Step 5 — Configure God Admin (VERY IMPORTANT)
Open `resources/[admin]/admin-commander/config.lua`

Find `Config.ownerIdentifiers` and add your **Steam Hex** ID:
```lua
Config.ownerIdentifiers = {
    'steam:110000123456789',  -- <-- PUT YOUR STEAM HEX HERE
}
```

To find your Steam Hex:
1. Start the server and join
2. Type `/steam` in chat
3. It shows your hex (looks like `steam:110000xxxxxxxxx`)
4. Add it to the config, restart server

The **first person** who joins after you set this will become permanent admin (saved in database). After that, only that person can use `/addowner` to add others.

### Step 6 — Set ox_inventory Items
The server needs custom items defined. Run these SQL queries on your database:
```sql
-- Insert bodycam item (if not exists)
INSERT IGNORE INTO items (name, label, weight, type, category) VALUES
('bodycam', 'Body Camera', 500, 'item', 'police'),
('police_radio', 'Police Radio', 200, 'item', 'police');
```

### Step 7 — Start Server
1. Start your FiveM server
2. It should load all resources automatically from server.cfg
3. Join the server and test

---

## 🎮 All Commands You'll Use

### Player Commands
| Command | What it does |
|---------|-------------|
| `/plist` or **F6** | Open Personnel List (who's on duty + radio freq) |
| **L** | Toggle bodycam on/off |
| **F5** | Open Outfit Manager |
| **U** | Open surveillance console (CID) |
| **H** | Open/close undercover vehicle trunk (CID UC car) |
| **J/K** | Identity swap hotkeys (CID UC car) |
| `/e [emote]` | Do an emote (dance, sit, etc.) |
| `/radio [freq]` | Join radio channel (e.g., `/radio 1`) |
| `/respawn` | Respawn at hospital |
| `/911 [message]` | Call 911 (e.g., `/911 I need help at Pillbox`) |
| `/cancel` | Cancel current action |

### Police/CID Commands
| Command | What it does |
|---------|-------------|
| **E** (on duty panel) | Clock in/out at police station |
| `/panic` or **P** | Send panic alert |
| `/cuff` | Handcuff nearest player |
| `/uncuff` | Remove handcuffs |
| `/escort` | Drag/escort cuffed player |
| `/check` | Check ID of nearest player |
| `/search` | Search nearest player |
| `/plate` | Run plate of nearest vehicle |
| `/impound` | Impound vehicle (charges fee) |
| `/ticket [amount]` | Issue a ticket |
| `/fine [amount]` | Issue a fine |
| `/call [number]` | Use patrol phone |
| `/mdt` | Open Mobile Data Terminal |
| `/bolo` | Create/view BOLO alerts |
| `/clear [id]` | Clear a 911 call |
| `/cuff [id]` | Cuff a specific player |

### CID-Specific Commands
| Command | What it does |
|---------|-------------|
| `/trace [phone]` | Trace a phone number |
| `/wiretap [phone]` | Wiretap a phone (court order) |
| `/deploybug` | Deploy surveillance bug |
| `/gps [id]` | Deploy GPS tracker on vehicle |
| `/sweep` | Sweep vehicle for trackers |
| `/entry` | Begin covert entry (lockpick + alarm bypass) |
| `/op [name]` | Start/join operations in ops center |

### Admin / God Commands
| Command | What it does |
|---------|-------------|
| `/addowner [id]` | Add someone as permanent owner/admin |
| `/removeowner [id]` | Remove owner status |
| `/listowners` | List all permanent owners |
| `/bunker` | Open Bunker Builder wizard |
| `/place` | Open Place Anywhere mode |
| `/goto [id]` | Teleport to player |
| `/bring [id]` | Bring player to you |
| `/revive [id]` | Revive yourself or someone |
| `/heal [id]` | Fully heal yourself or someone |
| `/car [model]` | Spawn any vehicle (e.g., `/car adder`) |
| `/dv` | Delete nearest vehicle |
| `/fix [id]` | Fix nearest vehicle or target |
| `/noclip` | Toggle noclip mode |
| `/god` | Toggle god mode |
| `/setjob [id] [job] [grade]` | Set someone's job |
| `/setmoney [id] [type] [amount]` | Set money (cash/bank) |
| `/setgroup [id] [group]` | Set admin group |
| `/announce [msg]` | Server-wide announcement |
| `/weather [type]` | Change weather (EXTRASUNNY, RAIN, etc.) |
| `/time [hour]` | Set time of day |
| `/ban [id] [reason]` | Ban a player |
| `/unban [id]` | Unban a player |
| `/kick [id] [reason]` | Kick a player |

### FIB Building Controls
| Key/Action | What it does |
|------------|-------------|
| **E** (at FIB door) | Enter/exit FIB building |
| **E** (at elevator) | Open floor selector → click floor → door closes → fade → arrive |
| **E** (at computer) | Open terminal → type `help` for commands |

FIB elevator commands inside terminal: `help`, `clear`, `date`, `status`, `bolos`, `exit`

---

## ⚙️ How to Configure Things

### Bodycam Settings
File: `resources/[police]/bodycam/config.lua`
```lua
Config.Bodycam = {
    ToggleKey = 'L',           -- Key to toggle bodycam
    AutoRecordOnDuty = true,   -- Auto-start when going on duty
    RequireDuty = true,        -- Must be on duty to use
    BatteryMax = 100,          -- Battery capacity
    BatteryDrainRate = 1,      -- How fast battery drains
    AllowedJobs = { 'police', 'sheriff', 'statepolice', 'cid' },
}
```

### P-List Settings
File: `resources/[police]/p-list/config.lua`
```lua
Config.PList = {
    command = 'plist',      -- Command name
    keybind = 'F6',          -- Key to open
    refreshInterval = 3000,  -- Update every 3 seconds
    allowedJobs = { 'police', 'sheriff', 'statepolice', 'cid' },
}
```

### Duty Blips Settings
File: `resources/[police]/duty-blips/config.lua`
```lua
Config.DutyBlips = {
    updateInterval = 5000,   -- Update every 5 seconds
    -- Colors: 3=blue, 5=green, 17=orange, 57=purple
    blips = {
        police = { sprite = 1, color = 3, scale = 0.7 },
        cid = { sprite = 1, color = 57, scale = 0.7 },
    },
}
```

### FIB Building Settings
File: `resources/[shared]/fib-building/config.lua`

**IMPORTANT: After launching the server, you may need to adjust coordinates!**
The FIB MLO places its geometry at specific world coords. If the entrance door isn't where you expect:
1. Go to the FIB building in-game
2. Use `/coords` in chat to see your position
3. Update the `entrance.coords` in this file
4. Restart the resource

```lua
Config.FIB = {
    entrance = { coords = vector3(135.0, -749.0, 45.0) },
    interior = { coords = vector3(110.0, -740.0, 42.0) },
    elevator = {
        floors = {
            { name = 'lobby', label = 'Lobby', coords = vector3(...), minRank = 0 },
            { name = 'offices', label = 'Offices', ..., minRank = 0 },
            { name = 'armory', label = 'Armory / Evidence', ..., minRank = 2 },
            { name = 'interrogation', label = 'Interrogation', ..., minRank = 1 },
            { name = 'server', label = 'Server Room', ..., minRank = 3 },
            { name = 'roof', label = 'Roof / Helipad', ..., minRank = 3 },
        }
    },
    allowedJobs = { 'police', 'cid' },
    restrictedJobs = { 'cid' },
}
```

### FIB Elevator Floor Configuration
After testing in-game, you'll know the exact coordinates for each floor. Use `/coords` standing where the elevator should drop you, then update `config.lua`:

```lua
-- Example after finding correct coords:
floors = {
    { name = 'lobby', label = 'Lobby', coords = vector3(110.0, -740.0, 42.0), heading = 180.0, minRank = 0 },
    ...
}
```

---

## 🔍 Troubleshooting

| Problem | Solution |
|---------|----------|
| Server won't start | Check `server.cfg` for typos. Make sure all `ensure` paths exist. |
| People can't join | Check your `sv_endpoint_ping` setting. Open port 30120 in firewall. |
| Items missing | Check `items.lua` in ox_inventory. Did you run the SQL inserts? |
| FIB building invisible | The MLO coords may be wrong. Use `/coords` near where the FIB should be, update config. |
| Elevator doesn't work | Teleport coords need adjustment. Use `/coords` at each floor location. |
| Bodycam not auto-starting | Make sure you have the `bodycam` item in your inventory and you're going on duty properly. |
| P-List shows no one | Make sure players are actually toggling on duty at a police station. |
| No blips on map | Make sure `Config.DutyBlips.updateInterval` is set. Officers must be on duty. |

---

## 👑 Admin Quick Reference

After setting your Steam Hex in `admin-commander/config.lua`:
1. Join server
2. You are automatically saved as permanent owner
3. Use `/addowner` to give other admins permanent access
4. Use `/listowners` to see all owners
5. Use `/place` to spawn objects anywhere (WASD to move, Q/E to rotate, Enter to place)
6. Use `/bunker` to create custom bunkers for players
7. Use `/car` to spawn any vehicle
8. Use `/setjob` to give people jobs

All admin commands listed in the table above under "Admin / God Commands".

---

That's it! Your server has all the CID/police systems, FIB building, bodycams, personnel list, map blips, and more. Test everything in-game and adjust the FIB coordinates as needed. Good luck!
