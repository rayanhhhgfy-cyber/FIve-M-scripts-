# Custom FiveM Roleplay Server - Complete System & Script Encyclopedia

Welcome to the definitive system reference and documentation manual for this fully integrated custom FiveM Roleplay server, built on top of the QBox (QBX) framework.

Unlike generic servers built from disconnected scripts, this ecosystem is organized centrally. It communicates through standardized exports, a centralized database (`master_schema.sql` with 80+ interconnected tables), and unified UI interfaces using modern frontend styling (such as glassmorphism, Vue3, and Quasar).

---

## 📖 Table of Contents

1. [Core Framework & Initialization](#1-core-framework--initialization)
2. [Admin Resources (`[admin]`)](#2-admin-resources-admin)
3. [Criminal Investigation Division (`[cid]`)](#3-criminal-investigation-division-cid)
4. [Civilian Jobs & Activities (`[civilian]`)](#4-civilian-jobs--activities-civilian)
5. [Core Utilities & Frameworks (`[core]`)](#5-core-utilities--frameworks-core)
6. [Criminal Gameplay & Heists (`[criminal]`)](#6-criminal-gameplay--heists-criminal)
7. [Economy & Business Systems (`[economy]`)](#7-economy--business-systems-economy)
8. [Emergency Alerts & Dispatch (`[emergency]`)](#8-emergency-alerts--dispatch-emergency)
9. [Emergency Medical Services (`[ems]`)](#9-emergency-medical-services-ems)
10. [Entertainment & Leisure (`[entertainment]`)](#10-entertainment--leisure-entertainment)
11. [Housing (`[housing]`)](#11-housing-housing)
12. [Immersion Systems (`[immersion]`)](#12-immersion-systems-immersion)
13. [Jobs (`[jobs]`)](#13-jobs-jobs)
14. [Logistics & Towing (`[logistics]`)](#14-logistics--towing-logistics)
15. [Map Loadable Objects / MLOs (`[mlo]`)](#15-map-loadable-objects--mlos-mlo)
16. [Smartphones & Tech (`[phones]`)](#16-smartphones--tech-phones)
17. [Player Systems (`[player]`)](#17-player-systems-player)
18. [Police Department (`[police]`)](#18-police-department-police)
19. [Polish & Quality of Life (`[polish]`)](#19-polish--quality-of-life-polish)
20. [Prison System (`[prison]`)](#20-prison-system-prison)
21. [Shared Resources (`[shared]`)](#21-shared-resources-shared)
22. [Vehicle Packs (`[vehicles]`)](#22-vehicle-packs-vehicles)
23. [Unused/Legacy Overlaps (`_disabled-overlaps`)](#23-unusedlegacy-overlaps-_disabled-overlaps)
24. [Extra Assets & Sources for Porting](#24-extra-assets--sources-for-porting)
25. [Database Schema Quick Guide](#25-database-schema-quick-guide)
26. [Technical Reference & Internal Workflows](#26-technical-reference--internal-workflows)

---

## 1. Core Framework & Initialization

The server utilizes `resources/server.cfg` to orchestrate resource startups sequentially. It maintains server-wide parameters, slots (up to 64 players), txAdmin integrations, database queries, and loads dependencies correctly to prevent race conditions during startup.

---

## 2. Admin Resources (`[admin]`)

Admin resources provide robust world-building, moderation, and player tracking tools for server owners and administrators.

| Resource Name | Path | Description | Activation & How to Trigger |
|---|---|---|---|
| **admin-commander** | `resources/[admin]/admin-commander/` | Fast command-based utility for granting items, vehicles, and configuring ownership privileges. | **Commands:** `/addowner [playerID]`, `/removeowner [identifier]`, `/listowners`, `/giveitem [playerID] [item] [amount]`, `/givecar [playerID] [model]`. |
| **admin-zones** | `resources/[admin]/admin-zones/` | Allows creation of interactive zones (wardrobes, duty areas, shops, storages, armories, and garages). | Configured in `config.lua` or triggered dynamically. **Commands:** `/zoneadmin` |
| **bunker-builder** | `resources/[admin]/bunker-builder/` | Allows admins to build and place custom bunkers with customizable entrance models (small, medium, large rocks), passcode restrictions, interiors (7 presets), and vehicle spawners. Includes built-in HTML creator UI. | **UI-Enabled:** Automatically triggers NUI builder panel when using corresponding admin menu options or specific admin events. |
| **god-dashboard** | `resources/[admin]/god-dashboard/` | A luxury vehicle previewing and spawning interface. Allows admins to preview distance, transparency, and rotation of vehicles across 8 categories (Super, Sports, Muscle, Off-Road, Motorcycles, Emergency, Commercial, Helicopters) before spawning them. | **UI-Enabled:** Triggers when vehicle-related spawning requests are made via the admin menu tools. |
| **god-menu** | `resources/[admin]/god-menu/` | The server's main admin control hub. Comprises over a dozen distinct tabs: Players, Vehicles, Inventory, Items, Money, Weather, Time, Teleport, Server, Bans, Garage, Staff, Reports, Doors, Zones, and Tools. Uses persistent DB-based owner tracking. | **Keybind:** `F6` (Configurable)<br>**Command:** `/god`<br>**NUI Interface:** Sleek web panel.<br>**Database Ownership:** First player joining gets auto-assigned. |
| **place-anywhere** | `resources/[admin]/place-anywhere/` | Allows persistent placement, movement, and rotation of objects/props directly in the game world, saved persistently to the database across restarts. | Accessible through the `god-menu` Tools tab or admin commands. |

---

## 3. Criminal Investigation Division (`[cid]`)

An ultra-sophisticated surveillance and crime-solving suite designed for detective roles.

| Resource Name | Path | Description | Activation & How to Trigger |
|---|---|---|---|
| **anonymity-bridge** | `resources/[cid]/anonymity-bridge/` | Secure communication system enabling anonymous tip-offs and encrypted messages between informants and detectives. | Automatically triggered via specified phone/laptop interactions. |
| **camera-drone** | `resources/[cid]/camera-drone/` | Remote-controlled surveillance drone equipped with aerial cameras for tracking targets and spying on suspect meetings. | Triggered by using the `drone` item from the inventory. |
| **cid-garage** | `resources/[cid]/cid-garage/` | Spawning and storage system for unmarked or specialized CID detective cruisers. | Target-based interactions at the CID Headquarters. |
| **cid-hq** | `resources/[cid]/cid-hq/` | Core map and marker coordinate handler for CID operations. | Physical location interactions. |
| **cid-laptop** | `resources/[cid]/cid-laptop/` | Portable laptop for detectives to access cases, plate logs, and criminal dossiers on the field. | **Command/Keybind:** `+cidLaptop` (registers key map) or using the `cid_laptop` inventory item. |
| **cid-terminal** | `resources/[cid]/cid-terminal/` | Terminal station located within MRPD / CID HQ for filing investigative warrants and monitoring trackers. | Interaction at physical terminal screens. |
| **cid-weapons** | `resources/[cid]/cid-weapons/` | Access armory system restricted specifically to CID detective clearance levels. | Target-interaction inside CID Headquarters. |
| **covert-entry** | `resources/[cid]/covert-entry/` | Lockpicking and alarm-bypassing module specifically optimized for detective infiltration missions. | **Command:** `/leavenotrace` (clears evidence footprint). |
| **crypto-tracking** | `resources/[cid]/crypto-tracking/` | Traces darknet financial transactions, locating black market dealer nodes. | Accessed from CID laptops/terminals. |
| **evidence-lab** | `resources/[cid]/evidence-lab/` | Processing stations where gathered forensics evidence can be stored and cataloged. | Interacting with processing points in MRPD/CID labs. |
| **forensic-kit** | `resources/[cid]/forensic-kit/` | Mobile kit for taking DNA swabs, fingerprint lifts, and ballistic casing prints at active crime scenes. | **Command/Keybind:** `forensic` or using `forensic_kit` item. |
| **interrogation-room** | `resources/[cid]/interrogation-room/` | Manages active interrogation rooms, including camera controls and recording functions. | Targeted interaction on interrogation room control units. |
| **notebook** | `resources/[cid]/notebook/` | A portable notepad item that allows CID officers to write and store crime notes persistently. | **Command/Keybind:** `+notebook` or using the `notebook` usable item. |
| **operations-center** | `resources/[cid]/operations-center/` | Tactical war-room interface mapping live tracking bugs and camera feeds on a main grid. | **UI-Enabled:** Access from CID Headquarters terminals. |
| **plate-scanner** | `resources/[cid]/plate-scanner/` | Automatically reads license plates of passing vehicles, checking them against active warrants and BOLOs. | **Command/Keybind:** `+platescan` or automatic in patrol cruisers. |
| **strobes** | `resources/[cid]/strobes/` | Custom emergency flashing strobe lights for unmarked CID tactical vehicles. | Keybind mapped in undercover vehicles. |
| **surveillance-bugs** | `resources/[cid]/surveillance-bugs/` | Allows detectives to plant listening/tracking devices inside rooms or on suspect vehicles. | **Command/Keybind:** `+surveillanceConsole` or using the `surveillance_bug` item. **UI-Enabled.** |
| **undercover-vehicles** | `resources/[cid]/undercover-vehicles/` | Adds unmarked undercover cruisers with identity swappers and custom storage trunks. | **Commands/Keybinds:** `+ucLights`, `+ucScanner`, `+ucSilent`, `+ucSiren` inside unmarked vehicles. |
| **wiretaps** | `resources/[cid]/wiretaps/` | Authorized monitoring of phone lines, messaging logs, and live audio intercept streams of suspect players. | Initiated from CID Terminals via proper warrant procedures. |

---

## 4. Civilian Jobs & Activities (`[civilian]`)

Legitimate economic pursuits designed to keep players integrated into the server's passive economy.

| Resource Name | Path | Description | Activation & How to Trigger |
|---|---|---|---|
| **bus** | `resources/[civilian]/bus/` | Bus driving routes where players drive public buses and pick up NPC passengers. | Start route at the Bus Depot using the radial menu or `/busstart` command from the civilian jobs script. |
| **city-hall** | `resources/[civilian]/city-hall/` | Municipal building where civilians acquire driver's licenses, weapon permits, ID cards, and register marriage licenses. | Ped/target-based interactions inside the City Hall building. |
| **court-system** | `resources/[civilian]/court-system/` | Legal arbitration system with full judicial controls, cases, files, sentencing, and jury mechanics. | **Commands:** `/starttrial`, `/juryvote`, `/filecase`, `/sentence`, `/cases`. |
| **delivery** | `resources/[civilian]/delivery/` | Parcel and commercial logistics shipping routes. | Started at delivery warehouses via target interaction or `/mailstart`. |
| **economy-core** | `resources/[civilian]/economy-core/` | Base math algorithms for calculating taxes, default interest rates, and commodity market values. | Automated server-side. |
| **electrician** | `resources/[civilian]/electrician/` | Grid repairs and powerline maintenance jobs across Los Santos. | Start work at the Power Utility building. |
| **fuel** | `resources/[civilian]/fuel/` | Underpins the physical fuel stations, allowing players to refuel at pumps. | Target interaction on gas pumps. |
| **garbage** | `resources/[civilian]/garbage/` | Sanitation worker job where players drive trash trucks and gather waste piles. | Job started at the Garbage Depot (or `/garbagestart`). |
| **hotdog-stand** | `resources/[civilian]/hotdog-stand/` | Player-run street vending stand with cooking mechanics and customer service. | Buy/rent a Hotdog vendor cart and initiate selling. |
| **legal-system** | `resources/[civilian]/legal-system/` | Lawyer bar association logs, allowing licensed attorneys to register clients and view jail records. | Accessed at Courthouse terminals. |
| **lumberjack** | `resources/[civilian]/lumberjack/` | Wood harvesting, tree chopping, and processing logs into sellable paper or wood sheets. | Located at Paleto Forest lumber mills. Target interactions. |
| **mining** | `resources/[civilian]/mining/` | Ore mining, smelting, and mineral refining for crafting raw metals. | Located at the Senora Desert mine shaft. Target interactions. |
| **news** | `resources/[civilian]/news/` | Weazel News reporter career. Grants access to heavy video cameras and news microphones. | Target interactions inside Weazel News HQ. |
| **taxi** | `resources/[civilian]/taxi/` | Standard taxi transport jobs servicing NPC or player taxi requests. | Triggered by visiting Downtown Cab Co or using `/taxiui`. |
| **vehicle-shop** | `resources/[civilian]/vehicle-shop/` | Retail dealerships selling standard civilian vehicles. | Interactive markers inside dealerships. |
| **winery** | `resources/[civilian]/winery/` | Vineyard tending, grape gathering, processing wine barrels, and selling to local stores. | Target interactions at Marlowe Vineyards. |

---

## 5. Core Utilities & Frameworks (`[core]`)

The central nervous system of the server. These scripts manage identities, targets, database connection bridges, voice configurations, performance, and key setups.

| Resource Name | Path | Description | Activation & How to Trigger |
|---|---|---|---|
| **afk-kicker** | `resources/[core]/afk-kicker/` | Automatic kicker to prevent idle players from wasting server slots. | Automatic server-side monitoring. |
| **alert-system** | `resources/[core]/alert-system/` | Framework for routing server-wide announcements, police dispatch pings, and emergency notices. | Automatic. |
| **character-system** | `resources/[core]/character-system/` | Custom UI system managing player character creation, customization, and spawning. | **UI-Enabled:** Runs on first login. |
| **chat-commands** | `resources/[core]/chat-commands/` | Essential roleplay-oriented chat commands. | **Commands:** `/me`, `/do`, `/try`, `/ooc`, `/b`, `/sit`, `/laydown`, `/wave`. |
| **discord-logs** | `resources/[core]/discord-logs/` | Forwards in-game activities (heists, arrests, admin actions) directly to Discord Webhooks. | Server-side automated. |
| **emote-menu** | `resources/[core]/emote-menu/` | Main animation overlay library. Handles client-side triggers, animations, walks, and facial expressions. | **Keybind:** `F5` / `F1` radial or command `+emotemenu` / `/e [emotename]` / `/cancel`. **UI-Enabled.** |
| **entity-cleaner** | `resources/[core]/entity-cleaner/` | Runs garbage collection to delete abandoned vehicles, peds, and loose objects to prevent server lag. | Automatic. |
| **identity-core** | `resources/[core]/identity-core/` | Internal mapper linking player Steam/Discord identifiers with character IDs (citizenid) persistently. | Server-side background hook. |
| **multi-character** | `resources/[core]/multi-character/` | Sleek selection screen allowing up to five character profiles per player. | Activates automatically when a player connects. |
| **oxlib-init** | `resources/[core]/oxlib-init/` | Initializes standard configurations for `ox_lib` library wrapper modules, notifications, progress bars, and context menus. | Handled dynamically during server initialization. |
| **oxmysql-config** | `resources/[core]/oxmysql-config/` | Configures active parameters for server database connections and pools. | Automatic during startup. |
| **oxtarget-init** | `resources/[core]/oxtarget-init/` | Triggers framework registrations for the central eye-target interaction system (`ox_target`). | Holding down `LEFT ALT` in-game. |
| **ped-blacklist** | `resources/[core]/ped-blacklist/` | Restricts toxic or game-crashing models from spawning. | **Command:** `/checkmodel` for debugging blacklisted assets. |
| **phone-app** | `resources/[core]/phone-app/` | Direct underlying system interface for smartphone functions. | **Command/Keybind:** `+phone` or `/phone`. **UI-Enabled.** |
| **pma-voice-cfg** | `resources/[core]/pma-voice-cfg/` | Standardized audio ranges, megaphone multipliers, call encryptions, and radio frequencies. | **Commands:** `/radio`, `/voicerange`. **Keybind:** `H` (cycles voice ranges). |
| **polyzone-init** | `resources/[core]/polyzone-init/` | Core boundary-checking library used for identifying zones (e.g., banks, safezones, drug labs). | Automated backend library. |
| **queue-system** | `resources/[core]/queue-system/` | Prioritizes and sequences player connections when server slots are full. | Automated when connecting. |
| **report-system** | `resources/[core]/report-system/` | Lets players submit in-game help tickets or exploit notices directly to on-duty administrators. | **Command:** `/report` |
| **resource-optimizer** | `resources/[core]/resource-optimizer/` | Dynamic garbage collector ensuring optimal client frame rates (FPS). | **Command:** `/fpsboost` (swaps render distance profiles). |
| **settings-menu** | `resources/[core]/settings-menu/` | In-game configuration UI enabling custom binds for windows, vehicle doors, HUD styles, and UI sizing. | **Command/Keybind:** `settings`, `+door_menu`, `+frunk_toggle`, `+trunk_toggle`, `+windows_down`, `+windows_up`. |
| **spawn-selector** | `resources/[core]/spawn-selector/` | Visual map allowing players to select their spawning locations (Airports, Garages, last saved position). | **UI-Enabled:** Automatically triggers on load/respawn. |
| **txadmin-hooks** | `resources/[core]/txadmin-hooks/` | Hooks into txAdmin for handling server schedules, bans, restarts, and automatic restarts. | Background automation. |
| **voice-communications** | `resources/[core]/voice-communications/` | Live WebRTC / pma-voice frequency listeners and grid trackers. | Background automation. |
| **weathersync** | `resources/[core]/weathersync/` | Synchronizes server time and weather globally across all players. | **Commands (Admins only):** `/weather [type]`, `/time [hour] [minute]`, `/blackout`. |
| **welcome-system** | `resources/[core]/welcome-system/` | Showcases rules, greetings, and intro cinematics for new players. | Triggered on character creation/spawn. |
| **whitelist-system** | `resources/[core]/whitelist-system/` | Restricts access to players registered on the server database or Discord roster. | Triggers on player connection. |

---

## 6. Criminal Gameplay & Heists (`[criminal]`)

The crime syndicate core. Features progressive multi-phase heists, drug refining empires, money laundering, and turf wars.

| Resource Name | Path | Description | Activation & How to Trigger |
|---|---|---|---|
| **art-heist** | `resources/[criminal]/art-heist/` | Stealing highly valued paintings from the Los Santos Art Gallery. Requires cutting security wires and quiet lockpicking. | Initiated at the Gallery. Requires specific items (`glass_cutter`, etc.). |
| **atm-robbery** | `resources/[criminal]/atm-robbery/` | Ripping open ATM cash slots using high-power drill tools. | Interacting with an ATM with an active `drill` or `atm_card` skimming apparatus. |
| **bank-heist** | `resources/[criminal]/bank-heist/` | Multi-phase robbery system for standard bank institutions. | Interact with vault doors. Requires `hack_usb`, `drill`, and `c4_charge`. |
| **bobcat-heist** | `resources/[criminal]/bobcat-heist/` | Break-in at the Bobcat security armory depot. Involves firefights, C4 breaching, and heavy crates. | Target-based interactions inside the Bobcat building. |
| **card-robbery** | `resources/[criminal]/card-robbery/` | Skimming financial cards, duplicating swipe tracks, and stealing money. | Using skimming items at checkout registers or ATMs. |
| **chop-shop** | `resources/[criminal]/chop-shop/` | Deliver hot vehicles to a scrap yard to chop them down for high-value crafting materials. | Triggered at the Chop Shop depot. |
| **drug-dealing** | `resources/[criminal]/drug-dealing/` | Sell street drugs to passing NPCs. Underpins street reputation, corner turf, and quick cash. | Use drug items inside criminal neighborhoods to corner deal. |
| **drug-manufacturing** | `resources/[criminal]/drug-manufacturing/` | Refining base ingredients into retail chemical packages (Cocaine, Heroin). | Inside hidden manufacturing warehouses. Target-based interactions. |
| **gang-laptop** | `resources/[criminal]/gang-laptop/` | Portable gang laptop offering turf maps, reputation tracking, and illegal weapon ordering. | **Command/Keybind:** `+gangLaptop` or using the `gang_laptop` inventory item. |
| **gangs** | `resources/[criminal]/gangs/` | Roster systems, custom ranks, gang storage safes, and vehicle garage options for official crews. | Set up in the database or via admin commands. |
| **graffiti** | `resources/[criminal]/graffiti/` | Spray-paint customized gang tags on urban walls. Generates gang reputation and controls territory. | Using a `spray_can` item near valid city walls. |
| **house-robbery** | `resources/[criminal]/house-robbery/` | Breaking into civilian properties to loot drawers, electronics, and safes. | Lockpicking residential door handles during night hours. |
| **jewelry-fence** | `resources/[criminal]/jewelry-fence/` | Pawn shop where criminals sell dirty jewelry, clocks, and paintings. | Targeted interaction with the Fence NPC. |
| **meth-lab-empire** | `resources/[criminal]/meth-lab-empire/` | Large-scale methamphetamine cooking operations inside custom mobile RVs or chemical labs. | Interaction with cooking stations. Requires base chemicals. |
| **money-laundry** | `resources/[criminal]/money-laundry/` | Clean black-market marked bills at a loss to make the money legal. | Interacting with washers inside launderette businesses. |
| **multi-heists** | `resources/[criminal]/multi-heists/` | High-fidelity heists (Fleeca, Jewelry, Bank Truck, Paleto Bay) utilizing custom phased sequences. | **UI-Enabled:** Simon Says hacking game. Approaches markers at specified banks. Requires minimum active police. |
| **store-robbery** | `resources/[criminal]/store-robbery/` | Hold up convenience store cashiers or drill back-room safes. | Aiming a firearm at a shop cashier or drilling the back safe. |
| **train-heist** | `resources/[criminal]/train-heist/` | Raid a cargo transport train moving through Blaine County. | Initiated at dispatch trackers or railway intercepts. |
| **turfs** | `resources/[criminal]/turfs/` | Dynamic turf wars where different crews compete for drug margins and local area control. | Accessed through Gang Laptop or map menus. |
| **underground-network** | `resources/[criminal]/underground-network/` | Hidden black market networks for purchasing restricted arms and components. | Target search inside gang tunnels and alleyways. |
| **vangelico-heist** | `resources/[criminal]/vangelico-heist/` | Smash-and-grab heist at the luxury jewelry store. | Smash display cases using heavy weapons. |
| **weapon-manufacturing** | `resources/[criminal]/weapon-manufacturing/` | Craft customized firearms using harvested metals. | Inside secret bunkers. Interaction with workbench props. |
| **yacht-heist** | `resources/[criminal]/yacht-heist/` | Specialized heist targeting a luxurious offshore yacht. | Approaches offshore coordinates via boat. Requires cutting vaults. |

---

## 7. Economy & Business Systems (`[economy]`)

Advanced financial layers representing investments, personal credit scores, and commercial loans.

| Resource Name | Path | Description | Activation & How to Trigger |
|---|---|---|---|
| **atm-card** | `resources/[economy]/atm-card/` | Adds Physical ATM Cards to player inventories. Allows interactive PIN screens and transaction limits. | **UI-Enabled:** Interacting with an ATM with an `atm_card` in inventory. |
| **banking-plus** | `resources/[economy]/banking-plus/` | Banking engine tracking transactions, wire transfers, loans, credit ratings, and corporate investment structures. | Inside banks or via phone apps. |
| **payroll** | `resources/[economy]/payroll/` | Automatic payment handler delivering payroll taxes and salaries to on-duty players. | Background timer. |
| **premium-dealership** | `resources/[economy]/premium-dealership/` | Luxury auto showroom catalog system with full 3D rotating display. | **UI-Enabled:** Interactive showroom markers. |
| **vehicle-dealership** | `resources/[economy]/vehicle-dealership/` | Standard dealership UI for purchasing economy automobiles. | **UI-Enabled:** Showroom triggers. |

---

## 8. Emergency Alerts & Dispatch (`[emergency]`)

| Resource Name | Path | Description | Activation & How to Trigger |
|---|---|---|---|
| **advanced-alerts** | `resources/[emergency]/advanced-alerts/` | Sends AMBER alerts, weather warnings, and critical city news updates. | Triggered by admins or auto-events. |
| **dispatch-system** | `resources/[emergency]/dispatch-system/` | Main dispatch board routing 911/311 emergency calls to police, CID, and EMS. | **UI-Enabled:** Automatic overlay on police HUD. Triggered by emergency notifications. |

---

## 9. Emergency Medical Services (`[ems]`)

Advanced healthcare simulation including triage priorities, organ damage, stretchers, and trauma medicine.

| Resource Name | Path | Description | Activation & How to Trigger |
|---|---|---|---|
| **advanced-trauma** | `resources/[ems]/advanced-trauma/` | Tracks anatomical damage (broken bones, internal bleeding). | Automatic upon receiving heavy damage. |
| **advanced-triage** | `resources/[ems]/advanced-triage/` | EMS prioritization of patient health indices in mass casualty situations. | Interacting with patients using triage cards. |
| **ems-defibrillator** | `resources/[ems]/ems-defibrillator/` | Useable cardiac arrest pads to resuscitate deceased players. | Using the usable item `defibrillator` on downed players. |
| **morgue-extension** | `resources/[ems]/morgue-extension/` | Autopsies, cold slabs, toe tags, and corpse persistence. | Inside Pillbox morgue drawers. Target interactions. |
| **pharmacy-npc** | `resources/[ems]/pharmacy-npc/` | Automated medical dispensary supplying EMS components. | Interacting with the Hospital Pharmacy NPC. |
| **pillbox-mlo** | `resources/[ems]/pillbox-mlo/` | Optimizes Pillbox Hospital layout assets. | Map asset. |
| **qb-medicalbag** | `resources/[ems]/qb-medicalbag/` | Deployable trauma kits for quick field surgeries. | Using the `medicalbag` inventory item. |
| **rcore-medical** | `resources/[ems]/rcore-medical/` | Underlying core medical framework. | Backend hooks. |
| **stretcher-system** | `resources/[ems]/stretcher-system/` | Mobile stretchers that can be deployed from ambulances to transport patients. | Radial menu interaction near ambulance rear. |
| **wasabi-ambulance** | `resources/[ems]/wasabi-ambulance/` | Ambulance vehicle configuration, sirens, medical beds, and check-in procedures. | Targeted interactions inside Pillbox Hospital. |
| **wasabi-crutches** | `resources/[ems]/wasabi-crutches/` | Wearable crutches slowing down movement speed of players with leg injuries. | Automatically equipped when diagnosed with leg trauma. |
| **xray-system** | `resources/[ems]/xray-system/` | Detailed visual medical diagnosis scans for bone fractures. | Triggers at the radiology scanner inside the hospital. |

---

## 10. Entertainment & Leisure (`[entertainment]`)

Leisure activities for roleplayers to unwind between shifts.

| Resource Name | Path | Description | Activation & How to Trigger |
|---|---|---|---|
| **arcade** | `resources/[entertainment]/arcade/` | Playable cabinet minigames inside arcade shops. | Interact with arcade screens. |
| **bowling** | `resources/[entertainment]/bowling/` | Playable bowling lanes with scoreboards. | Located at the bowling alley. Targeted lane interactions. |
| **casino** | `resources/[entertainment]/casino/` | Spin lucky wheels, play blackjack, slots, and roulette games. | Inside Diamond Casino. Uses custom casino chips. |
| **coffee-shop** | `resources/[entertainment]/coffee-shop/` | Player-run coffee house with brewing mechanics. | Located at the Coffee Shop. Target interactions. |
| **diving** | `resources/[entertainment]/diving/` | Scuba gear rentals, underwater salvage, and rare coral gathering. | Approaching diving boat rental points. |
| **fishing** | `resources/[entertainment]/fishing/` | Rod casting and fish weighing mechanics at sea docks. | Use a `fishing_rod` near bodies of water. |
| **hunting** | `resources/[entertainment]/hunting/` | Tracking and hunting wild game, skinning carcasses, and selling meat. | Using hunting rifles in designated woods. |
| **mini-games** | `resources/[entertainment]/mini-games/` | Simon Says, lockpicking, thermite grid, and keypad bypasses. | Executed dynamically via hacking/robbery events. |
| **movie-theater** | `resources/[entertainment]/movie-theater/` | Visual cinema screens playing streaming video streams. | Entering cinema properties. Target seats. |
| **pizza-this** | `resources/[entertainment]/pizza-this/` | Complete pizza kitchen, cooking, and delivery jobs. | Located at Pizza This restaurant. |
| **racing** | `resources/[entertainment]/racing/` | Design custom racing lines, host lobbies, and track lap times. | Opened via racing app or racing laptop nodes. |
| **restaurant-jobs** | `resources/[entertainment]/restaurant-jobs/` | Universal cooking, food assembly, and billing tools for dynamic restaurants. | Target-based interactions inside commercial kitchens. |

---

## 11. Housing (`[housing]`)

| Resource Name | Path | Description | Activation & How to Trigger |
|---|---|---|---|
| **advanced-housing** | `resources/[housing]/advanced-housing/` | Buying houses, customized interior design (furniture placement), guest key ring management, security alarms, and property garages. | Targeted interactions at real estate listings and residential front doors. |

---

## 12. Immersion Systems (`[immersion]`)

Enhancements that bridge the gap between arcade and realistic survival gameplay.

| Resource Name | Path | Description | Activation & How to Trigger |
|---|---|---|---|
| **InteractSound** | `resources/[immersion]/InteractSound/` | Triggers 3D directional audio sound effects (car locking chirps, seatbelts click). | Triggered dynamically via client events. |
| **dp-emotes** | `resources/[immersion]/dp-emotes/` | Alternative animation library. | Background references. |
| **gym-system** | `resources/[immersion]/gym-system/` | Workout at gyms to gain physical strength and endurance. | **Command:** `/gymrest` or interacting with gym machinery. |
| **player-status** | `resources/[immersion]/player-status/` | Constant drainage and replenishment formulas for starvation, dehydration, and stress. | Core background simulation. |
| **ragdoll-system** | `resources/[immersion]/ragdoll-system/` | Fall unconscious, trip over large obstacles, or get knocked down. | Automatically triggers on heavy impact or physics triggers. |
| **rcore-radiocar** | `resources/[immersion]/rcore-radiocar/` | High-fidelity car radio systems allowing surrounding players to hear vehicle music. | Controls via vehicle audio interface. |
| **seatbelt-system** | `resources/[immersion]/seatbelt-system/` | Seatbelt mechanics that prevent player ejecting through the windshield in major crashes. | **Keybind:** `K` or configurable keybind. |
| **stress-engine** | `resources/[immersion]/stress-engine/` | Screenshake, panic panting, and aiming sway during intense gunfights or high-speed driving. | Automatic. Relieved by smoking, relaxing, or eating. |
| **vehicle-physics** | `resources/[immersion]/vehicle-physics/` | Immersive vehicle handling profiles, drift thresholds, and terrain resistance modifiers. | Background vehicle injection. |
| **wasabi-boombox** | `resources/[immersion]/wasabi-boombox/` | Usable boombox prop playing synchronized YouTube/Soundcloud music. | Double clicking `boombox` item in inventory. |

---

## 13. Jobs (`[jobs]`)

| Resource Name | Path | Description | Activation & How to Trigger |
|---|---|---|---|
| **civilian-jobs** | `resources/[jobs]/civilian-jobs/` | Starts entry-level public jobs easily. | **Commands:** `/busstart`, `/garbagestart`, `/mailstart`, `/requesttow`, `/towstart`. |
| **taxi-system** | `resources/[jobs]/taxi-system/` | Advanced fare meters, tip mechanics, and client rating boards. | **Command/Keybind:** `taxiui`. |

---

## 14. Logistics & Towing (`[logistics]`)

Commercial logistics, heavy hauling, flatbed loading, and city towing.

| Resource Name | Path | Description | Activation & How to Trigger |
|---|---|---|---|
| **advanced-tow** | `resources/[logistics]/advanced-tow/` | Physical tow cable winch pulling stranded vehicles onto trucks. | Target interaction near a tow truck. |
| **barricades** | `resources/[logistics]/barricades/` | Road blockers, detour lights, and orange pylons. | Using deployable barricade items. |
| **flatbed** | `resources/[logistics]/flatbed/` | Pulling cars up onto flatbeds persistently. | Target menu at rear of tow trucks. |
| **fleet-management** | `resources/[logistics]/fleet-management/` | Corporate registry tracking commercial logistics truck inventories. | Interactive business terminals. |
| **impound** | `resources/[logistics]/impound/` | Automated vehicle impounding yards with recovery fines. | Interacting with the Impound lot ped. |
| **tow-job** | `resources/[logistics]/tow-job/` | Professional tow routes towing illegally parked cars for cash. | Job start at the Towing Office. |

---

## 15. Map Loadable Objects / MLOs (`[mlo]`)

Custom map interior modifications. No scripts are executed here, but they contain assets streamed directly to client files.

* **borders**: `resources/[mlo]/borders/` - Adds checkpoints at map borders.
* **bunker**: `resources/[mlo]/bunker/` - Underground operational facility.
* **gang-tunnel**: `resources/[mlo]/gang-tunnel/` - Underground passages for gangs.
* **gigz-youtool**: `resources/[mlo]/gigz-youtool/` - Redesigned YouTool store.
* **luxury-autos**: `resources/[mlo]/luxury-autos/` - Luxury car showroom.
* **mrpd**: `resources/[mlo]/mrpd/` - Replaces Mission Row Police Department with highly detailed interiors.
* **mt3d-fib**: `resources/[mlo]/mt3d-fib/` - Replaces FIB Building with full elevators.
* **pillbox-hospital**: `resources/[mlo]/pillbox-hospital/` - Expanded interior hospital layout.
* **sandy-medical**: `resources/[mlo]/sandy-medical/` - Country medical clinic.

---

## 16. Smartphones & Tech (`[phones]`)

Smartphones and criminal laptop interfaces.

| Resource Name | Path | Description | Activation & How to Trigger |
|---|---|---|---|
| **blackmarket** | `resources/[phones]/blackmarket/` | Phone application for buying lockpicks and contraband anonymously. | Open on the smartphone app grid. |
| **criminal-laptop** | `resources/[phones]/criminal-laptop/` | Portable hacking machine used to execute black-market operations. | **Command/Keybind:** `+laptop` or using the `criminal_laptop` item. |
| **hacking** | `resources/[phones]/hacking/` | Interactive keypads, simon says, and logic gateways. | Opens automatically during heist phases. |
| **iphone** | `resources/[phones]/iphone/` | A customizable smartphone (Twitter, Messages, Calls, Camera, Wallet, Notes, TikTok). | **Command/Keybind:** `+phone`. **UI-Enabled.** |
| **locator** | `resources/[phones]/locator/` | App for tracking cell signal locations of wanted individuals. | Opens via specific phone applications. |
| **vpn** | `resources/[phones]/vpn/` | Encryption layer for masking player IP addresses on the network. | Equipped as an item before connecting to net nodes. |

---

## 17. Player Systems (`[player]`)

Player management tools, custom menus, outfits, garages, inventories, and radial wheels.

| Resource Name | Path | Description | Activation & How to Trigger |
|---|---|---|---|
| **Renewed-Banking** | `resources/[player]/Renewed-Banking/` | Detailed banking layout with transactions and cards. | Interacting with banks or ATMs. |
| **Renewed-Garages** | `resources/[player]/Renewed-Garages/` | Standard garages where players retrieve or store vehicles. | Approaching garage terminal points. |
| **anim-menu** | `resources/[player]/anim-menu/` | Fast action and expression animations. | **Commands:** `/anim`, `/cancel`. |
| **custom-pause** | `resources/[player]/custom-pause/` | Custom Pause Screen showcasing server logo, links, rules, and player statistics. | **UI-Enabled:** Triggers on pressing `ESC`. |
| **drag-system** | `resources/[player]/drag-system/` | Allows dragging handcuffed suspects or downed bodies. | Target option on player or using corresponding radial option. |
| **hud** | `resources/[player]/hud/` | Modern UI displaying health, armor, hunger, thirst, stress, speed, street names, and oxygen levels. Built with Vue3 and Quasar. | **Commands/Keybinds:** `menu` (config menu), `/resethud`. **UI-Enabled.** |
| **illenium-appearance** | `resources/[player]/illenium-appearance/` | Complete clothing, hair, skin, and makeup customization. | Interacting with clothing stores or wardrobe zones. |
| **item-actions** | `resources/[player]/item-actions/` | Use and application checks of generic items like handcuffs, bandages, and repair kits. | Triggered by using items. |
| **notepad** | `resources/[player]/notepad/` | Lets players read and write notes in game. | **UI-Enabled:** Double clicking notes in inventory. |
| **outfit-manager** | `resources/[player]/outfit-manager/` | Save custom clothes configurations as persistent outfits. | **UI-Enabled:** Interactive markers in clothing shops. |
| **ox-context** | `resources/[player]/ox-context/` | Adapts custom styling for context popup menus. | Called via custom exports. |
| **ox-inventory-cfg** | `resources/[player]/ox-inventory-cfg/` | Active layout configurations of standard item profiles. | Loads on startup. |
| **ox_inventory** | `resources/[player]/ox_inventory/` | Advanced grid-based inventory featuring items weight, durability, and custom weapons attachment structures. | **Keybind:** `TAB` (Configurable)<br>**Commands:** `/steal` (robbing), `/clearActiveIdentifier`. **UI-Enabled.** |
| **property-system** | `resources/[player]/property-system/` | Internal logic connecting keyrings, land plots, and houses. | Backend maps. |
| **ps-housing** | `resources/[player]/ps-housing/` | Real estate interior layout and wardrobe loading scripts. | Physical entry points. |
| **ps-realtor** | `resources/[player]/ps-realtor/` | Real estate agent management board enabling purchases of player houses. | Accessed by realtors at offices. |
| **radialmenu** | `resources/[player]/radialmenu/` | Main interaction wheel with sub-menus for vehicles (engine, doors, hood), clothing toggles, and job actions. | **Keybind/Command:** `radialmenu` (normally holding `F1`). **UI-Enabled.** |
| **radio** | `resources/[player]/radio/` | Standard handheld radio with dynamic channel entry. | **UI-Enabled:** Using the `radio` item in inventory. |
| **repair-kit** | `resources/[player]/repair-kit/` | Repairs vehicle engines using standard mechanical parts. | Double-clicking `repairkit` inside inventories near car hoods. |
| **tuning-garage** | `resources/[player]/tuning-garage/` | Customize performance engines, cosmetic wraps, neons, and rims. | Driving inside custom tuning garages. |
| **vehicle-interactions** | `resources/[player]/vehicle-interactions/` | Simple commands for managing vehicle compartments. | **Commands:** `/door`, `/frunk`, `/trunk`, `/windows`. |
| **vehicle-keys** | `resources/[player]/vehicle-keys/` | Locks and unlocks vehicles. Features a rotating dial lockpick mini-game. | **Command/Keybind:** `/vehiclelock`. **UI-Enabled.** |
| **vehicle-lock** | `resources/[player]/vehicle-lock/` | Master engine locking algorithms preventing car hotwiring. | **Command/Keybind:** `+vehicleLock` (locks closest vehicle). |

---

## 18. Police Department (`[police]`)

The central policing and community protection systems.

| Resource Name | Path | Description | Activation & How to Trigger |
|---|---|---|---|
| **bodycam** | `resources/[police]/bodycam/` | Police bodycam overlay displaying officer rank, name, and live battery drainage. Logs activities to Discord. | **Command/Keybind:** `+bodycam` on-duty. |
| **bolo-system** | `resources/[police]/bolo-system/` | File and view Be On Look Out entries for vehicles and suspects. | Interacting with MRPD computers. |
| **breathalyzer** | `resources/[police]/breathalyzer/` | Measures blood alcohol content of suspects. | Using a `breathalyzer` on nearby players. |
| **crosshair-toggle** | `resources/[police]/crosshair-toggle/` | Fast command toggle enabling custom shooting crosshairs. | **Command/Keybind:** `+crosshair`. |
| **cuff-system** | `resources/[police]/cuff-system/` | Fast cuffs, animations, and sound effects for detaining suspects. | Context radial menus on targets. |
| **davis-station** | `resources/[police]/davis-station/` | Custom map assets optimizing Davis Police Department. | Map asset. |
| **dna** | `resources/[police]/dna/` | Analyze blood stains or saliva left behind at crime scenes. | Forensic kit collection. |
| **duty-blips** | `resources/[police]/duty-blips/` | Updates colored maps blips of active police (blue) and CID (purple) every five seconds. | Automatic when going on-duty. |
| **field-sobriety** | `resources/[police]/field-sobriety/` | Triggers custom sobriety balance tests for suspects. | **Command/Keybind:** `/sobriety` or radial menu. |
| **fines** | `resources/[police]/fines/` | Directly charge citizens bills or traffic tickets. | Opened from police radial options or MDT. |
| **grapple** | `resources/[police]/grapple/` | Tactical grappling hook allowing SWAT officers to climb up roofs. | **Command/Keybind:** `+grapple` or using `grapple_hook` item. |
| **jail-cutscene** | `resources/[police]/jail-cutscene/` | Interactive booking cutscene running during prison processing. | Triggered automatically when sentencing suspect players at MRPD. |
| **k9-unit** | `resources/[police]/k9-unit/` | Spawns a trained police dog capable of tracking scents and sniffing contraband. | Radial menu options. |
| **lspd-laptop** | `resources/[police]/lspd-laptop/` | Portable laptop for cruisers enabling remote database lookups. | **Command/Keybind:** `+lspdLaptop` or using cruiser computers. |
| **mdt** | `resources/[police]/mdt/` | Complete Mobile Data Terminal tracking warrants, records, and reports. | **Command/Keybind:** `+mdt` on-duty. |
| **mrpd-mlo** | `resources/[police]/mrpd-mlo/` | Coordinates and lightings for Mission Row MLO. | Map asset. |
| **officer-lockers** | `resources/[police]/officer-lockers/` | Stashes for storing officer gear and weaponry safely. | Interacting with lockers inside MRPD. |
| **p-list** | `resources/[police]/p-list/` | Complete online police roster showing ranks and active channels. | **Command/Keybind:** `+plist`. **UI-Enabled.** |
| **panic-button** | `resources/[police]/panic-button/` | Sends emergency backup requests with sound effects and GPS blips. | **Command/Keybind:** `+panic` (normally bound to `P`). |
| **person-search** | `resources/[police]/person-search/` | Interactively search and review items carried by detained players. | **UI-Enabled:** Target option on cuffed players. |
| **police-garage** | `resources/[police]/police-garage/` | Authorized police cruiser, SUV, and interceptor spawner. | Interaction points at MRPD garage gates. |
| **police-uniforms** | `resources/[police]/police-uniforms/` | Quick-duty outfits, tactical gear, vests, and badges. | **Command/Keybind:** `+applyUniform` or interacting with MRPD lockers. |
| **prison** | `resources/[police]/prison/` | Processing booking terminals. | Physical booking desk interactions. |
| **radar-gun** | `resources/[police]/radar-gun/` | Laser speed radar gun measuring speeds of passing vehicles. | **UI-Enabled:** Equipped as a speed radar weapon. |
| **road-deployables** | `resources/[police]/road-deployables/` | Quick placement menu for roadblocks, detours, and pylons. | Selectable via police inventory items. |
| **shields** | `resources/[police]/shields/` | Equips a physical riot shield blockading incoming projectile fire. | **Command/Keybind:** `+shield`. |
| **spike-strips** | `resources/[police]/spike-strips/` | Pop tires of fleeing vehicles by throwing spike strip blocks. | **Command/Keybind:** `+spikestrip` or radial menu. |
| **spotlight** | `resources/[police]/spotlight/` | High-beam steerable helicopter or cruiser searchlights. | **Command/Keybind:** `+spotlight` in police vehicles. |
| **tackle** | `resources/[police]/tackle/` | Tackle fleeing suspects to the ground. | **Command/Keybind:** `+tackle` while running. |
| **taser** | `resources/[police]/taser/` | Conductive taser cartridges with custom screenshake and recovery times. | Equipped and fired as standard stun weapon. |
| **traffic-stop** | `resources/[police]/traffic-stop/` | Standard pull-over indicator lights and siren guides. | **Command/Keybind:** `/trafficstop`. |

---

## 19. Polish & Quality of Life (`[polish]`)

Quality of life, optimizations, security, custom loading screens, and standalone elements.

| Resource Name | Path | Description | Activation & How to Trigger |
|---|---|---|---|
| **admin-menu** | `resources/[polish]/admin-menu/` | Legacy admin menu layout. | Disabled. |
| **advanced-mechanics** | `resources/[polish]/advanced-mechanics/` | Repairing individual components (alternators, radiators, gaskets). | Interaction with vehicle engines. |
| **anticheat** | `resources/[polish]/anticheat/` | Detects health/armor changes, rapid teleports, blacklisted weapons (RPG, Railgun, Minigun), and speed hacks. Uses a 3-strike auto-ban structure. | Constant automatic server-side scans. |
| **cinematic-camera** | `resources/[polish]/cinematic-camera/` | Cinematic camera with overlays for pictures and videos. | **Command/Keybind:** `/cinematic`. |
| **client-optimizer** | `resources/[polish]/client-optimizer/` | Dynamic LOD and asset streaming management. | Runs automatically in the background. |
| **clothing-store** | `resources/[polish]/clothing-store/` | Interactive markers at clothing stores. | Stepping into clothing store markers. |
| **death-screen** | `resources/[polish]/death-screen/` | Interactive respawn timers, cardiac monitors, and EMS alert buttons. | Triggered automatically on player death. |
| **doorlock** | `resources/[polish]/doorlock/` | Lockable doors (police departments, businesses, private warehouses) requiring keycards, passcodes, or lockpicks. | Keybind or targeted interaction on locked doors. |
| **forensics** | `resources/[polish]/forensics/` | Collecting fingerprints, bullet casings, and blood drops at crime scenes. Includes full analysis terminals at CID HQ. | **UI-Enabled:** Physical blue terminal markers at CID HQ (`vec3(-1454.36, -519.81, 29.88)`). |
| **fuel-ui** | `resources/[polish]/fuel-ui/` | Dynamic dashboard fuel display. | Active when driving inside vehicles. |
| **gun-recoil** | `resources/[polish]/gun-recoil/` | Custom camera shake recoil patterns for firearms to balance gunplay. | Automatically applies when firing guns. |
| **headbag** | `resources/[polish]/headbag/` | Hood bag item that can be placed on hostages, blinding their screens during kidnappings. | Double-clicking `headbag` item while behind a bound player. |
| **id-card** | `resources/[polish]/id-card/` | Show physical driving licenses, weapon licenses, and ID cards to nearby players. | Using ID card items from the inventory. |
| **immersion-polish** | `resources/[polish]/immersion-polish/` | Carrying and slinging other players. | **Command/Keybind:** `/releasecarry`. |
| **loading-screen** | `resources/[polish]/loading-screen/` | Basic static loading screen. | Runs on connection. **UI-Enabled.** |
| **loading-screen-new** | `resources/[polish]/loading-screen-new/` | Upgraded loading screen featuring background audio carousel, high-detail videos, and keybind help cards. | Runs on connection. **UI-Enabled.** |
| **mechanic-laptop** | `resources/[polish]/mechanic-laptop/` | Manage repair rosters and parts orders. | **Command/Keybind:** `+mechanicLaptop` or using the `mechanic_laptop` item. |
| **mechanics** | `resources/[polish]/mechanics/` | Main mechanic repair, tire changes, and custom tuning job script. | Located at mechanic bays. Target interactions. |
| **no-wanted** | `resources/[polish]/no-wanted/` | Disables built-in GTA wanted level police so player-controlled cops manage arrests. | Automatically running. |
| **passcode-doors** | `resources/[polish]/passcode-doors/` | Allows setting up doors requiring numeric passcode entries. | Targeted interaction on door handle. |
| **radio** | `resources/[polish]/radio/` | Standard voice communication channel slider. | **Commands/Keybinds:** `+radioToggle`, `+radioCycleUp`, `+radioCycleDown`. |
| **security-cam** | `resources/[polish]/security-cam/` | Allows security guards or police to monitor camera feeds inside major buildings. | Interacting with terminal screens. |
| **server-guide** | `resources/[polish]/server-guide/` | Dynamic menu showcasing server rules, custom keybind layouts, and active staff contacts. | **Command:** `/rules`. **UI-Enabled.** |
| **shops** | `resources/[polish]/shops/` | NPC grocery and hardware stores. | Interacting with shop peds. |
| **speed-camera** | `resources/[polish]/speed-camera/` | Speed cameras ticketing speeding vehicles automatically and charging banking cards. | Automatic when passing active cameras too fast. |
| **tattoo-shop** | `resources/[polish]/tattoo-shop/` | Buy tattoos at specialized ink shops. | Target-based interaction inside tattoo shops. |
| **trash-cans** | `resources/[polish]/trash-cans/` | Allows searching trash cans to find scrap metal and food. | Target option on public garbage cans. |
| **vending-machine** | `resources/[polish]/vending-machine/` | Purchase quick snacks or soda cans. | Interacting with physical vending machines. |

---

## 20. Prison System (`[prison]`)

| Resource Name | Path | Description | Activation & How to Trigger |
|---|---|---|---|
| **prison-system** | `resources/[prison]/prison-system/` | Processing jail times, prisoner jobs (sweeping, cleaning sewers) to reduce jail sentences, contraband smuggling, and breakouts. | Automatically triggers when a player is jailed. |

---

## 21. Shared Resources (`[shared]`)

Core layouts shared globally across multiple scripts. No activations here; they run persistently in the background.

* **building-interiors**: `resources/[shared]/building-interiors/` - Stores interior locations.
* **database**: `resources/[shared]/database/` - Stores `master_schema.sql` (80+ tables).
* **fib-building**: `resources/[shared]/fib-building/` - Replaces FIB building floors and roof elevator terminals.
* **helipads**: `resources/[shared]/helipads/` - Coordinates for standard helipads.
* **libs**: `resources/[shared]/libs/` - Shared globals, tables, math helpers, and libraries.
* **locales**: `resources/[shared]/locales/` - Core translation dictionaries (Arabic and English).
* **nui-theme**: `resources/[shared]/nui-theme/` - CSS rules enabling the glassmorphism visual style for UI interfaces.
* **secret-bunkers**: `resources/[shared]/secret-bunkers/` - Coordinates and markers of hidden bunkers across the map.

---

## 22. Vehicle Packs (`[vehicles]`)

Vehicle asset modifications streaming meta information, handlings, and yft files. No commands, keybinds, or items are directly declared here.

* **bevo**: `resources/[vehicles]/bevo/` - Adds Mercedes G-Wagon Bevo with 32+ custom tuning parts (bumpers, grilles, fenders).
* **dicy**: `resources/[vehicles]/dicy/` - Luxury Dicy 21 S580M sedan.
* **pitd-cars**: `resources/[vehicles]/pitd-cars/` - Tol Car Pack A containing over 50 unbranded sports and supercar models (tol22m5, tol240sx, tolbt62r, and more).
* **police-bikes**: `resources/[vehicles]/police-bikes/` - Adds 5 heavy law-enforcement police motorcycles (BMW 1200RT, Kawasaki Ninja).

---

## 23. Unused/Legacy Overlaps (`_disabled-overlaps`)

These folders contain legacy or redundant resources that have been disabled to prevent overlaps with newer systems. Do not start these resources.

* **cdn-hud**: Replaced by the newer Vue-based `hud`.
* **garage-system**: Replaced by `Renewed-Garages`.
* **linden-outfitbag** / **linden-outfits**: Replaced by `outfit-manager`.
* **qbox-spawn**: Replaced by `spawn-selector`.
* **radio-system**: Replaced by the newer `radio`.

---

## 24. Extra Assets & Sources for Porting

### Folder: `new mlos and vehicles/`
Contains 14 additional asset packs ready to install:
* `borders` (checkpoint MLO)
* `bunker` (MLO)
* `dicy21s580m` (luxury vehicle)
* `DLDebadgedPoliceBikes` (police bikes)
* `energy_luxuryautos` (showroom MLO)
* `fiv3devs_pillbox` (hospital MLO)
* `LuxBunker` (luxury bunker MLO)
* `mt3d_fib` (FIB building)
* `nteammrpdupdate` (MRPD map updates)
* `pitd_unbranded_tol_car_pack_A` (vehicle pack)
* `under ground bunker` (gang tunnel MLO)
* `YouTools_Stores_MLO` (YouTool hardware store MLO)
* `unclejsustsandymedicalv2` (Sandy Shores medical MLO)

### Folder: `new scrpits/` (Original QBCore Source Code)
Used as references for porting to QBox:
* `qb-hud-main`
* `qb-loading-main`
* `qb-radialmenu-main`
* `qb-spawn-main`

---

## 25. Database Schema Quick Guide

The `master_schema.sql` creates approximately 80 tables persistently storing every gameplay layer:
* **Player Data**: `players`, `characters`, `fingerprints`, `dna_records`.
* **Banking**: `bank_accounts`, `loans`, `credit_scores`, `transactions`.
* **CID & Police**: `cid_cases`, `cid_warrants`, `cid_bolos`, `bans`, `admin_logs`.
* **Property & Garages**: `player_properties`, `house_furniture`, `player_vehicles`, `impounded_vehicles`.
* **Criminal**: `gang_renown`, `blackmarket_listings`, `smuggling_events`.

---

## 26. Technical Reference & Internal Workflows

### 1. God Menu Verification Pattern (`isOwner()`)
Every critical administrator callback and event implements two-layer validation:
```lua
-- server/main.lua
local function isOwner(source)
    local identifier = GetPlayerIdentifier(source)
    -- 1. Checks config.lua hardcoded exceptions
    -- 2. Queries cached DB records in `server_owners`
    return hasAccess
end
```

### 2. Auto God Ownership Allocation
On `playerJoining`, the server checks if any active owner exists in the database. If zero records are found, the joining player is assigned as the supreme God Owner (`group_name = 'god'`) instantly, securing the server.

### 3. Anticheat Auto-Ban Escalar
The anticheat monitors telemetry variables per client frame:
* Health changes > 5 HP/tick
* Armour changes > 5 AP/tick
* Teleport movements > 300 meters/tick
* Firing blacklisted weapons (RPG, Minigun)
Detections log strike tallies. Reaching **3 strikes** kicks the target and issues a permanent ban logged to `bans` and Discord.
