This project is a fully custom-built FiveM Roleplay server developed as one integrated ecosystem rather than a collection of unrelated resources. Every system has been organized to work together through a centralized configuration, shared libraries, and a unified database structure.

The project includes all source code, custom resources, MLOs, vehicle packs, UI systems, documentation, and database files required to deploy and operate the server.

What the Project Includes
Core Framework

The server is built around a customized QBox/QBX framework with numerous custom systems integrated throughout the project.

Core functionality includes:

Character & identity management
Multi-character support
Player spawning
Voice integration
Inventory
Banking
Vehicle ownership
Housing
Job framework
Permissions
Queue system
Weather synchronization
Server optimization
Shared utility libraries

All resources communicate through shared interfaces, making the server consistent and modular.

Server Configuration

The server starts from:

resources/server.cfg

This file controls the entire startup process and loads every resource in the correct order, including:

Core framework
Database
Shared libraries
Player systems
Economy
Police
CID
Criminal gameplay
EMS
Business systems
Housing
Prison
Logistics
Phone system
MLOs
Vehicle packs
Custom UI

It also contains server settings, license placeholders, Steam API configuration, and resource dependency management.

Database

The project includes a complete master SQL database.

resources/[shared]/database/master_schema.sql

The schema contains approximately 80+ interconnected database tables used to persist nearly every gameplay system.

Examples include:

Player Data
Characters
Identity
Jobs
Vehicles
Inventory
Housing
Businesses
Phone System
Contacts
Messages
Photos
Videos
Wallet
Calendar
Notes
Social media
Voice mail
Settings
Apps
Police & CID
BOLOs
Warrants
Criminal records
Evidence
DNA
Fingerprints
Cases
Surveillance
License Plate Reader hits
Panic alerts
Emergency calls
Economy
Banking
Credit scores
Loans
Investments
Payroll
Taxes
Businesses
Fleets
Criminal Systems
Heists
Drug labs
Smuggling
Underground operations
Black market
Housing
Furniture
Garages
Guests
Alarm systems
Administration
Bans
Owner permissions
Door locks
Logs
Admin zones

Everything players do is stored persistently within the database.

Documentation

The repository includes extensive documentation.

README-SETUP.md

A complete setup guide covering:

Server installation
Resource configuration
SQL import
Inventory configuration
Admin ownership
Commands
Troubleshooting
SYSTEM_REFERENCE.md

A 1,100+ line technical reference explaining:

Server architecture
Custom systems
Events
Callbacks
Resource interactions
Configuration
Database structure
Internal workflows

This documentation allows another developer or server owner to understand and maintain the project.

Resource Categories

The server is organized into dedicated resource groups.

Core

Player framework, spawning, identity, voice, inventory, settings, optimization.

Player

HUD, radial menu, emotes, radio, appearance, key system, garages, vehicle interaction.

Admin

God Menu, owner management, inventory viewer, zone creator, object placement, dashboard, bunker builder.

Police

Traffic stops, MDT, bodycam, radar gun, K9, DNA, BOLOs, panic button, spike strips, tasers, road deployables, lockers, police garages.

CID (Criminal Investigation Division)

A complete detective system including:

Case management
Evidence processing
Surveillance
Wiretaps
Crypto tracking
Forensics
Undercover vehicles
CID terminal
Drone surveillance
Investigation tools
Criminal

Large-scale criminal gameplay including:

Bank robberies
Yacht heists
Bobcat
Vangelico
Art gallery
Drug manufacturing
Meth lab empire
Weapon manufacturing
Money laundering
Gang systems
Turf wars
Chop shops
Underground networks
Civilian

Civilian jobs and businesses including:

News
Taxi
Delivery
Mining
Lumberjack
Winery
Bus driver
Garbage collection
Electrician
Vehicle dealership
Court system
EMS

Medical gameplay including:

Trauma
Triage
Defibrillators
Stretchers
X-Ray system
Ambulance framework
Morgue
Pharmacy
Economy & Business

Advanced financial systems including:

Banking
Loans
Credit scores
Investments
Payroll
Vehicle dealerships
Fleet management
Housing

Complete property ownership with:

Furniture placement
Garages
Guests
Alarm systems
Prison
Sentencing
Prison jobs
Contraband
Escape mechanics
Phones

A fully custom smartphone featuring:

Calls
Messages
Contacts
Camera
Wallet
Calendar
Notes
Social media
Black market
Vehicle management
GPS
Hacking
Delivery services
Custom MLOs

The server includes multiple custom interiors, including:

Mission Row Police Department (MRPD)
Pillbox Hospital
Sandy Medical Center
FIB Headquarters
Luxury Autos Dealership
Underground Bunker
Gang Tunnel
Border Checkpoints
YouTool Store

All required map assets are included.

Vehicle Content

The project includes custom vehicle packs such as:

Police motorcycles
Luxury vehicles
Bevo G-Wagon
PITD vehicle pack (50+ custom vehicles)
Additional addon vehicles ready for installation
UI & NUI

The server contains numerous custom web-based interfaces, including:

Modern HUD
Phone UI
Admin panels
Radial menu
Loading screen
Lockpick minigames
Banking interface
Inventory
Vehicle management
Reports
Garage UI
Rules menu

Most interfaces are built using modern web technologies (Vue, Quasar, HTML, CSS, and JavaScript).

Additional Assets

The repository also includes:

Additional MLO packs ready for installation
Additional vehicle packs
Original QBCore resources used during framework porting
Disabled legacy resources retained for compatibility/reference
Lua syntax validation tools
Development configuration files
What the Customer Receives
Complete FiveM server source code
All custom resources
Full server configuration
Complete SQL database
All MLOs
All vehicle packs
Phone system
Economy system
Police & CID systems
Criminal gameplay
Housing
Prison
EMS
Admin tools
UI/NUI assets
Documentation
Setup guides
Development utilities  if the customer asks for more info give him this ادا العميل طلب معلومات كمان اعطيه هاد النص ROOT-LEVEL FILES
At the root of the project folder there is a .luarc.json file which configures the Lua language server for VS Code so it understands FiveM-specific functions. There is a check-syntax.js script that uses Node.js to scan all Lua files for syntax errors using a package called luaparse. The package.json and package-lock.json are just for that Node dependency. There is a README-SETUP.md file that is a 295-line guide for setting up the entire server from scratch with all commands, configurations, and troubleshooting. There is also an empty folder called -p which is just a placeholder.
Inside the docs folder there are two files. server-ideas.md contains 20 ideas for future features like dynamic weather, advanced housing, drug manufacturing, a court system, fishing, hunting, gang turf wars, scuba diving, food trucks, a casino, and more. SYSTEM_REFERENCE.md is a massive 1,135-line technical document that covers the entire server architecture, every server event and callback, the full database schema, configuration options, and troubleshooting guides.
The node_modules folder only contains the luaparse package which is the Lua parser used by the syntax checker.
THE MAIN RESOURCES FOLDER
The heart of the project is the resources folder. It contains the server.cfg file which is the main FiveM server configuration. It defines every single resource that should start when the server boots up, in the correct order starting with core systems, then shared systems, player systems, economy, police, admin, criminal, MLOs, vehicles, CID, phones, immersion, emergency, EMS, business, entertainment, housing, jobs, logistics, prison, and polish resources. It also sets the server to allow up to 64 players, defines the hostname, and has placeholder spots for a Steam API key and a license key. It targets game build 2802.
ADMIN RESOURCES - 6 Total
The admin-commander resource gives admins quick commands like /addowner, /removeowner, /listowners, /giveitem, and /givecar. Its configuration file defines which groups are admin, stores owner identifiers using Steam Hex codes, has a quick list of commonly given items and vehicles including custom models like the Bevo G-Wagon and the 1200RT police bike, and has teleport preset locations.
The admin-zones resource allows creating interactive zones in the world that can serve as armories, shops, storage areas, wardrobes, duty zones, or garages. The configuration lets you set the default radius for zones, define different zone types with their own icons, configure armor and uniforms, and set default police vehicles.
The bunker-builder resource is a custom tool that lets admins place bunker entrances in the world. You can choose between small, medium, or large rock presets for the entrance, select from seven different interior types including planning rooms, bunkers, and hangar interiors, set a passcode for access, and configure vehicle and helicopter spawn points. Each admin can create up to ten bunkers.
The god-dashboard resource is a web-based admin panel specifically for spawning vehicles with a preview feature. It organizes vehicles into eight categories: Super, Sports, Muscle, Off-Road, Motorcycles, Emergency, Commercial, and Helicopters. You can control the preview distance, transparency, and rotation of the vehicle before spawning it.
The god-menu resource is the main admin panel and is one of the most complex resources in the entire project. It is a full private owner dashboard with over a dozen tabs. The Players tab lets you list all connected players, teleport to them, kick them, ban them, freeze them, slap them, revive them, heal them, or give them armor. The Vehicles tab lets you spawn any vehicle, fix it, delete it, or give keys to someone. The Inventory tab lets you view any player's inventory with category filters and remove items from them. The Items tab lets you give items or weapons to a player or to everyone on the server. The Money tab lets you set a player's cash or bank balance. The Weather tab lets you change the weather globally with twelve different weather types. The Time tab lets you freeze time, unfreeze it, or set a specific time. The Teleport tab lets you teleport to your waypoint or to any of twelve preset locations. The Server tab lets you restart resources, send announcements to all players, or start a restart countdown. The Bans tab lets you view all active bans, search for specific bans, and ban or unban players. The Garage tab lets you view any player's stored vehicles, spawn them, delete them, impound them, or release them from impound. The Staff tab lets you promote or demote staff members with hierarchy checks to prevent abuse. The Reports tab lets you accept or close player reports. The Doors tab is an admin door lock management system where you can detect nearby doors and add them as permanent doors, passcode doors, or job-restricted doors. The Zones tab lets you create and manage admin zones. The Tools tab gives you noclip flight, spectate mode, the ability to clear a area of entities, kill all players, freeze all players, or teleport all players to you. The system automatically assigns the first person who joins the server as the permanent god owner via the database.
The place-anywhere resource lets admins place any object or model in the game world with full control over position and rotation. Everything placed is saved to the database so it persists across server restarts.
CID RESOURCES - 19 Total
CID stands for Criminal Investigation Division and this is a complete detective system. The anonymity-bridge resource provides tools for anonymous communication. The camera-drone resource gives detectives a drone for aerial surveillance. The cid-garage is where CID vehicles are stored. The cid-hq is the headquarters location for CID operations. The cid-laptop is a portable computer for CID officers. The cid-terminal is a computer system with case management, warrant applications, and BOLO postings. The cid-weapons resource controls weapon authorization for CID personnel. The covert-entry resource provides lockpicking and alarm bypass tools for covert operations. The crypto-tracking resource lets detectives track cryptocurrency transactions. The evidence-lab is where evidence is analyzed. The forensic-kit resource provides tools for collecting evidence at crime scenes. The interrogation-room resource manages interrogation sessions with suspects. The notebook resource gives detectives an in-game notebook for taking notes. The operations-center is a mission management hub for CID. The plate-scanner resource provides automatic license plate reading technology. The strobes resource adds emergency strobe lights to vehicles. The surveillance-bugs resource lets officers place audio and video bugs that can be tracked. The undercover-vehicles resource gives CID unmarked vehicles where they can swap their identity with the J and K keys and access the trunk with the H key. The wiretaps resource allows legal phone tapping.
CIVILIAN RESOURCES - 16 Total
The bus resource is a bus driver job where players drive routes and pick up NPCs. The city-hall resource handles interactions at city hall like getting IDs or marriage licenses. The court-system is a full legal court system for trials. The delivery resource has various delivery driver jobs. The economy-core handles core economy functions. The electrician is a job where players do electrical work. The fuel resource handles the gas station fueling system. The garbage resource is a sanitation worker job. The hotdog-stand resource lets players run a hotdog vending business. The legal-system is for lawyer players to practice law. The lumberjack job lets players cut down trees and process wood. The mining job lets players mine for materials. The news resource lets players work as news reporters. The taxi resource is a taxi driving job. The vehicle-shop is where players can buy cars. The winery resource lets players run a winemaking business.
CORE RESOURCES - 26 Total
The afk-kicker automatically kicks idle players after a set time. The alert-system sends server-wide alerts for important events. The character-system handles character creation and management. The chat-commands handles various chat commands. The discord-logs sends logs to Discord via webhooks. The emote-menu provides access to all game emotes. The entity-cleaner cleans up abandoned vehicles and objects to keep the server running smoothly. The identity-core handles player identity data. The multi-character system lets players have multiple characters on one account. The oxlib-init initializes the ox_lib framework. The oxmysql-config sets up the database connection. The oxtarget-init sets up the ox_target interaction system. The ped-blacklist blocks specific ped models from being used to prevent crashes or exploits. The phone-app is the core framework for the phone system. The pma-voice-cfg configures the voice communication system. The polyzone-init initializes the PolyZone system for area detection. The queue-system manages a queue when the server is full. The report-system lets players report issues to staff. The resource-optimizer improves server performance by optimizing resource usage. The settings-menu gives players an in-game settings menu. The spawn-selector lets players choose where to spawn when they join, which was ported from the qb-spawn resource. The txadmin-hooks integrates with the TXAdmin server management tool. The voice-communications sets up voice chat. The weathersync synchronizes weather across all players. The welcome-system shows welcome messages to new players. The whitelist-system manages a whitelist for server access.
CRIMINAL RESOURCES - 23 Total
The art-heist is a heist at the art gallery where players steal paintings. The atm-robbery lets players rob ATMs for cash. The bank-heist is a full bank robbery with multiple phases. The bobcat-heist is a heist at Bobcat Security. The card-robbery is a card cloning and robbery system. The chop-shop is where stolen vehicles can be dismantled for parts. The drug-dealing is a street-level drug dealing system. The drug-manufacturing is a drug production operation. The gang-laptop is a laptop for gang operations and communication. The gangs resource is the main gang system with gang creation and management. The graffiti resource lets players tag gang graffiti around the city. The house-robbery lets players break into and rob houses. The jewelry-fence is where stolen jewelry can be sold. The meth-lab-empire is a large-scale methamphetamine production operation. The money-laundry lets criminals clean their dirty money. The multi-heists resource is a system that supports multiple different heist types. The store-robbery lets players rob convenience stores. The train-heist is a robbery of a moving train. The turfs resource handles gang territory wars and control. The underground-network is a secret criminal network system. The vangelico-heist is a robbery of the Vangelico jewelry store. The weapon-manufacturing lets players manufacture illegal weapons. The yacht-heist is a robbery of a luxury yacht.
ECONOMY RESOURCES - 5 Total
The atm-card resource adds ATM cards that players can use at bank machines. The banking-plus resource is an advanced banking system with credit scores, loans, and investments. The payroll resource handles automatic paychecks for jobs. The premium-dealership is a high-end vehicle dealership but it is currently disabled and only used for admin car grants. The vehicle-dealership is the standard car dealership which is also currently disabled.
EMERGENCY RESOURCES - 2 Total
The advanced-alerts resource sends emergency alerts to players like weather warnings and AMBER alerts. The dispatch-system is a dispatch center for handling emergency calls.
EMS RESOURCES - 12 Total
EMS stands for Emergency Medical Services. The advanced-trauma resource handles serious injuries that require advanced treatment. The advanced-triage resource helps EMS workers prioritize patients in mass casualty events. The ems-defibrillator resource adds a defibrillator item that can restart a stopped heart. The morgue-extension adds morgue functionality and autopsy capabilities. The pharmacy-npc adds a pharmacy NPC where players can buy medical supplies. The pillbox-mlo integrates the Pillbox hospital map into the server. The qb-medicalbag adds a medical bag item with supplies. The rcore-medical is a medical treatment framework. The stretcher-system lets EMS deploy and use stretchers to carry patients. The wasabi-ambulance adds ambulance vehicles and ambulance gameplay. The wasabi-crutches adds crutches for injured players. The xray-system lets doctors take and view x-rays of patients.
ENTERTAINMENT RESOURCES - 12 Total
The arcade resource adds playable arcade machines. The bowling resource adds a bowling alley mini-game. The casino resource adds a full casino with blackjack, poker, roulette, and slot machines. The coffee-shop resource lets players work at a coffee shop. The diving resource lets players go scuba diving. The fishing resource lets players fish at various spots. The hunting resource lets players hunt animals. The mini-games resource has various small games to play. The movie-theater resource adds a cinema where players can watch videos. The pizza-this resource is a pizza delivery job. The racing resource is a street racing system with races and competitions. The restaurant-jobs resource lets players work at restaurants.
HOUSING RESOURCES - 1 Total
The advanced-housing resource is a complete housing system. Players can buy properties, place furniture inside them, manage a guest list for who can enter, set up alarm systems, and store vehicles in their garage.
IMMERSION RESOURCES - 10 Total
The dp-emotes resource gives players access to hundreds of animations and emotes. The gym-system lets players work out at gyms to improve their character's fitness. The InteractSound resource adds interactive 3D sound effects. The player-status resource tracks hunger, thirst, and stress levels. The ragdoll-system lets players ragdoll and be affected by physics. The rcore-radiocar adds an in-car radio system. The seatbelt-system adds seatbelt mechanics where you can be ejected from a vehicle in a crash if not wearing one. The stress-engine adds a stress mechanic that affects gameplay. The vehicle-physics resource enhances the default vehicle physics for more realism. The wasabi-boombox adds a portable boombox that players can carry around and play music from.
JOBS RESOURCES - 2 Total
The civilian-jobs resource has various miscellaneous civilian jobs. The taxi-system is a dedicated taxi system with customer ratings and fare management.
LOGISTICS RESOURCES - 6 Total
The advanced-tow resource is a towing system for towing vehicles. The barricades resource lets players place deployable barricades. The flatbed resource adds a flatbed truck for transporting vehicles. The fleet-management resource helps manage fleets of vehicles for businesses or the city. The impound resource is a vehicle impound system where towed or abandoned vehicles are stored. The tow-job resource is a dedicated tow truck driver job.
MLO RESOURCES - 9 Total
MLO stands for Map Loadable Object which is a custom interior or building. The borders MLO adds border checkpoint buildings at the edges of the map with grant files and stream files for the model and occlusion data. The bunker MLO adds an underground bunker with addon props, the building model, and occlusion data. The gang-tunnel MLO adds an underground gang hideout tunnel system. The gigz-youtool MLO adds a YouTool hardware store building. The luxury-autos MLO adds a luxury car dealership showroom with audio occlusion, spawn vehicle locations, and stream files including custom ytyp definitions. The mrpd MLO is the Mission Row Police Department and is split into two parts. The mrpd-mapdata part adds lighting and map data files like ymap and ymt files. The mrpd-replacement part replaces the default MRPD building with a custom version and includes a 2D logo folder, data files, and a massive stream folder with LOC files for lighting and occlusion data in ycd and ydr format, plus an UN folder that contains GTA data files and dozens of ybn, ydr, ymap, ynd, ynv, ytd, and ytyp files for the full replacement building. The mt3d-fib MLO adds the FIB building with a stream folder. The pillbox-hospital MLO adds the Pillbox Hill hospital with audio occlusion and stream files. The sandy-medical MLO adds a medical clinic in Sandy Shores with stream files.
PHONES RESOURCES - 6 Total
The blackmarket resource adds a black market app on the phone. The criminal-laptop resource gives criminals a laptop for illegal activities. The hacking resource adds hacking mini-games for various criminal activities. The iphone resource is the main phone system and is a full iPhone clone with a web-based interface. It includes contacts, messages, a camera, TikTok, Twitter, a wallet, a calendar, notes, call history, voicemail, settings, a restaurant and delivery ordering system, a gigs app, and a vehicles app. The locator resource adds a phone locator app for finding other players. The vpn resource adds a VPN system for anonymous communication.
PLAYER RESOURCES - 23 Total
The anim-menu resource gives players an animation menu with seven categories. There are six dances, ten gestures, eight idle animations, six expressions, five greetings, twelve actions, and twenty walk styles. Everything is integrated with the radial menu.
The custom-pause resource replaces the default GTA pause menu with a custom one.
The drag-system resource lets police drag cuffed players and EMS drag downed players. You can also force players into and out of vehicles.
The hud resource is a modern heads-up display that was ported from the qb-hud resource. It uses Vue3 and Quasar for the user interface. It displays circular progress bars for health, armor, hunger, thirst, stress, and oxygen levels. It also has a speedometer, a compass, street name display, a minimap toggle button, stress visual effects, and a cinematic mode that hides the HUD. The files include the HTML web interface, locale files for different languages, stream files for the minimap graphics, and GitHub workflow files.
The illenium-appearance resource is a character appearance system where players can customize their look.
The item-actions resource handles using various items like handcuffs, the bodycam, a police ram, and binoculars.
The notepad resource gives players an in-game notepad for taking notes during roleplay, useful for detectives.
The outfit-manager resource lets players save and load outfits.
The ox-context resource integrates the ox_lib context menu system.
The ox-inventory-cfg resource contains the configuration for the inventory system.
The ox_inventory resource is the full inventory system. It has data files for item definitions, over thirty locale files for different languages, modules for bridging with different frameworks like ESX, ND, and QBox, modules for crafting, hooks, the interface, inventory management, item behavior, MySQL queries, the PEFCL economy system, shops, utility functions, and weapon handling. It also has a setup folder and a web build with compiled assets and images.
The property-system resource handles property ownership for players.
The ps-housing resource is a player housing system.
The ps-realtor resource is a real estate system where players can buy and sell properties.
The radialmenu resource is an SVG-based radial menu that was ported from the qb-radialmenu. It gives players access to vehicle controls like doors, extra vehicle components, seat position, engine toggle, and trunk access. It also has clothing options for hat, glasses, mask, top, pants, and shoes. It supports a trunk system for storing items in vehicle trunks, a stretcher deployment system for EMS, and job-specific interactions. The files include the HTML interface with CSS and JavaScript, client and server Lua scripts, stream files, and GitHub configuration files.
The radio resource is a radio communication system that was ported from the qb-radio. It has a channel input where players type the channel number, volume controls, channel cycling buttons, job-restricted channels for police and EMS, integration with the pma-voice system, and a handheld radio animation. The files include the HTML interface with CSS styling, images, and JavaScript, locale files, and GitHub workflows.
The Renewed-Banking resource is a full banking system where players can manage their money.
The Renewed-Garages resource is a vehicle garage system where players can store and retrieve their vehicles.
The repair-kit resource adds a vehicle repair kit item that players can use to fix their cars.
The tuning-garage resource lets players customize and tune their vehicles with performance parts and visual modifications.
The vehicle-interactions resource adds interaction menus for vehicles.
The vehicle-keys resource is a complete vehicle key system. It has a lockpick mini-game with a rotating needle and a sweet spot that you need to hit. Players can lock and unlock vehicles, transfer keys between players, use the /givekey command, and access everything through the radial menu. The files include the HTML interface for the lockpick game.
The vehicle-lock resource handles the basic vehicle locking mechanics.
POLICE RESOURCES - 31 Total
The bodycam resource is a body camera system for police officers. It automatically starts recording when an officer goes on duty. The L key toggles the recording on and off. It has a battery that drains over time, a HUD overlay showing recording status, timestamps on recordings, Discord logging for when recordings start and stop, and database storage for footage.
The bolo-system resource lets officers post BOLO alerts which stands for Be On LookOut. These are alerts about wanted persons or vehicles.
The breathalyzer resource lets officers administer breathalyzer tests to check for alcohol impairment.
The crosshair-toggle resource lets players toggle their crosshair on and off.
The cuff-system resource handles handcuffing and uncuffing suspects.
The davis-station resource adds the Davis police station location.
The dna resource lets officers collect DNA samples at crime scenes.
The duty-blips resource shows all on-duty police and CID officers on the map with colored blips. Police show as blue and CID shows as purple. The blips update every five seconds and are only visible to other law enforcement.
The field-sobriety resource lets officers administer field sobriety tests to check for drug impairment.
The fines resource lets officers issue fines and tickets to players.
The grapple resource adds a grappling hook for rappelling and climbing.
The jail-cutscene resource plays a booking cutscene when a player is processed into jail.
The k9-unit resource adds a police dog unit for tracking suspects and searching for contraband.
The lspd-laptop resource adds a laptop computer for LSPD officers.
The mdt resource is a Mobile Data Terminal for law enforcement vehicles, providing access to records and databases.
The mrpd-mlo resource integrates the MRPD building with police functionality.
The officer-lockers resource gives officers personal lockers at the station for storing gear.
The p-list resource is the personnel list. Officers can open it with F6 or by typing /plist. It shows all on-duty officers with their name, job title, rank, and radio channel. It has a glassmorphism UI style and updates live every three seconds.
The panic-button resource lets officers trigger a panic alert by pressing the P key, which notifies all other officers of their location and that they need backup.
The person-search resource lets officers search people for contraband.
The police-garage resource is where police vehicles are stored and can be accessed by officers.
The police-uniforms resource lets officers manage and change their uniforms.
The prison resource is a police-operated prison where arrested players are held.
The radar-gun resource is a handheld speed radar gun that officers can use to check vehicle speeds.
The road-deployables resource lets officers place traffic cones and barriers to control traffic.
The shields resource adds riot shields that officers can use for crowd control.
The spike-strips resource adds deployable spike strips for stopping fleeing vehicles.
The spotlight resource adds a vehicle-mounted spotlight that officers can control.
The tackle resource lets officers tackle and take down fleeing suspects.
The taser resource adds a taser weapon for non-lethal incapacitation.
The traffic-stop resource provides a complete traffic stop procedure system.
POLISH RESOURCES - 28 Total
The admin-menu resource is an old admin menu that is currently disabled.
The advanced-mechanics resource adds more detailed vehicle mechanics work.
The anticheat resource is a server-side anti-cheat system. It detects health cheating, armor cheating, teleport hacking, and speed hacking. It has a weapon blacklist for restricted weapons. It uses a three-strike system where after three detected violations the player is automatically banned. It sends alerts to Discord.
The cinematic-camera resource adds a cinematic camera mode for screenshots and videos.
The client-optimizer resource helps improve client performance by reducing unnecessary rendering.
The clothing-store resource lets players buy clothes at clothing stores.
The death-screen resource adds a custom death screen when players die.
The doorlock resource is a general door locking system for various doors in the city.
The forensics resource is a crime scene investigation system. Officers can collect fingerprints, shell casings, and DNA at crime scenes. There is an analysis terminal at CID HQ where evidence can be processed.
The fuel-ui resource adds a user interface for the gas station fueling system.
The gun-recoil resource adds enhanced recoil patterns to weapons for more realistic gunplay.
The headbag resource adds a headbag item that can be placed on hostages or restrained players.
The id-card resource gives players an ID card that they can show to others.
The immersion-polish resource adds various small immersion improvements.
The loading-screen resource is the older version loading screen with a simple HTML interface, logo image, and basic styling.
The loading-screen-new resource is the newer version that was ported from qb-loading. It uses Vue3 and Quasar for the interface and has a carousel of images. It has asset files including background music in MP3 format, a QBCore branding SVG, several images for the background, SVG keybind icons for many keys including B, F1, G, HOME, I, L, LALT, M, NUM, TAB, Tilde, X, Y, and Z, and a background video in MP4 format. The HTML interface has its own JavaScript and CSS files.
The mechanic-laptop resource gives mechanics a laptop for managing repair jobs.
The mechanics resource is the main mechanic job system.
The no-wanted resource completely disables the GTA wanted level system so police are handled entirely by the server scripts.
The passcode-doors resource lets players set up doors with numeric passcodes for access.
The radio resource is an older radio system that is currently disabled.
The security-cam resource adds security cameras that can be viewed remotely.
The server-guide resource adds an in-game command /rules that opens a NUI modal window with three tabs: Server Rules, Key Binds, and Staff Contacts.
The shops resource handles various NPC-run shops around the city.
The speed-camera resource adds automated speed cameras around the city that issue fines to speeding drivers.
The tattoo-shop resource lets players get tattoos at tattoo parlors.
The trash-cans resource lets players search through trash cans for items.
The vending-machine resource lets players interact with vending machines to buy drinks and snacks.
PRISON RESOURCES - 1 Total
The prison-system resource manages the prison facility. It handles inmate processing, sentence tracking, prison jobs for inmates, contraband smuggling, and prison breakout attempts.
SHARED RESOURCES - 8 Total
The building-interiors resource defines the interiors of various buildings that players can enter.
The database resource contains the master SQL schema file which is 1,199 lines long and defines approximately 80 database tables covering every system in the server. This includes tables for players, characters, phone messages, phone tweets, phone contacts, phone photos, phone wallet, phone notes, phone calendar, phone call history, phone voicemails, phone settings, phone groups, phone gigs, black market chat, police BOLOs, police vehicle logs, panic alerts, license plate reader hits, K9 units, K9 logs, emergency calls, CID trackers, CID surveillance bugs, CID operations, CID grade configuration, CID armory items, CID cases, CID warrants, CID BOLOs, CID person notes, vehicle spawn logs, CID audit logs, server owners, admin managed doors, admin logs, bans, admin zones, admin zone items, bank credit scores, bank loans, bank investments, bank transactions, payroll configuration, player payrolls, tax configuration, criminal records, ballistic records, smuggling events, mobile labs, front businesses, surveillance cameras, ATM skimmers, gang renown, black market listings, prison escape progress, autopsy reports, addiction trackers, blood bank, field medical kits, player properties, player houses, house furniture, house guests, house alarms, house vehicles, court cases, court evidence, court appeals, bail bonds, business licenses, seized auctions, food trucks, food truck menus, food truck inventory, food truck orders, player vehicles, impounded vehicles, vehicle listings, vehicle component trackers, fleet garage logs, Instashot social media profiles and posts, racing events, parcel deliveries, passcode doors and access logs, the whitelist, report logs, job rosters and logs, gang rosters, mechanic data, custom bunkers, placed objects, and player notes.
The fib-building resource adds the FIB building to the map. It has an entrance system, an elevator with floor selection showing Lobby, Offices, Armory, Interrogation, Server Room, and Roof. On the roof there is a computer terminal with commands including help, clear, date, status, bolos, and exit. The building has door locks and job-based access control.
The helipads resource defines helipad locations on buildings.
The libs resource contains shared Lua library files like globals.lua that are used across multiple resources.
The locales resource contains localization files for Arabic and English.
The nui-theme resource provides a shared NUI theme system with a glassmorphism design style that is used across multiple web interfaces.
The secret-bunkers resource defines secret bunker locations around the map that players can discover.
VEHICLE RESOURCES - 4 Total
The bevo resource adds a Mercedes G-Wagon nicknamed Bevo. It has its own fxmanifest file and data folder with carcols, carvariations, handling, and vehicles meta files. The stream folder contains the main vehicle model file and texture file plus 32 different customization part files for bumpers, grilles, side skirts, spoilers, fenders, light bars, wheel covers, side boxes, logos, and more.
The dicy resource adds a Dicy 21 S580M luxury vehicle. It has a fxmanifest and a dlc.rpf file that needs to be extracted with OpenIV.
The pitd-cars resource is a massive vehicle pack called PITD Unbranded TOL Car Pack A with over 50 custom vehicle models. It has a fxmanifest, vehicle names list, and meta files for car colors, car variations, handling, vehicle layouts, and vehicle definitions. Each vehicle has its own stream folder with the model file, high-detail model file, texture files, and various customization parts. The vehicle models include tol22m5, tol240sx, tol3j50, tol675ltsp, tol700, tola6, tolap2, tolaudidy, tolbt62r, tolc63, tolc7, tolcharger2, tolcurus, toldemon, toldurus, tole36prb, tole36v, tole6314, tolevo9, tolexor, tolf360, tolf8spider, tolfxxk, and tolgatm21.
The police-bikes resource adds five police motorcycle models. It has a fxmanifest and vehicle names list. The data folder has separate handling, carcols, carvariations, and vehicles meta files for each of the five models which are the BMW 1200RT, the BMW RP, the HP Bikes, the Police Bike, and the Kawasaki Ninja. The stream folder has all the model files and texture files for each bike.
DISABLED OVERLAPS - 6 Total
The disabled-overlaps folder contains six resources that have been replaced by newer or better versions to prevent conflicts. The cdn-hud resource is replaced by the newer hud in the player folder. The garage-system is replaced by Renewed-Garages. The linden-outfitbag is replaced by the outfit-manager. The linden-outfits is replaced by the outfit-manager. The qbox-spawn is replaced by the spawn-selector in the core folder. The radio-system is replaced by the radio in the player folder. Each of these still has all their files including configs, fxmanifests, client and server scripts, HTML interfaces, and any other assets.
NEW MLOS AND VEHICLES FOLDER - 14 Asset Packs Ready to Install
This folder contains additional asset packs that are not yet active in the server but are ready to be installed. The bevo folder has another copy of the G-Wagon vehicle. The borders folder has the border checkpoint MLO with both the main building and audio occlusion files. The bunker folder has the bunker MLO with stream files. The dicy21s580m folder has the Dicy S580M vehicle. The DLDebadgedPoliceBikes folder has the police bikes with all five models. The energy_luxuryautos folder has the luxury auto dealership MLO with audio, spawn vehicles, and stream files. The fiv3devs_pillbox folder has the Pillbox hospital MLO with audio and stream. The LuxBunker folder has a luxury bunker MLO. The mt3d_fib folder has the FIB building MLO with stream files and is also available as a zip file. The nteammrpdupdate folder has an MRPD update with both the map data and the main building replacement. The pitd_unbranded_tol_car_pack_A folder has the full vehicle pack in both extracted and zipped formats. The under ground bunker folder has the gang tunnel MLO with a fxmanifest, a game data file, and stream files for collision, model, map placement, and occlusion. The YouTools_Stores_MLO folder has the YouTool store MLO with all the stream files for the building, props, and lighting. The unclejsustsandymedicalv2 folder has the Sandy Shores medical MLO version 2 with a full set of medical building files.
NEW SCRIPTS FOLDER - 5 QBCore Script Sources for Porting
This folder contains the original QBCore versions of scripts that were ported to work with the QBox framework. The qb-hud-main folder has the original QBCore HUD with client and server scripts, configuration, 18 locale files for different languages, HTML web interface files, and stream graphics. The qb-loading-main folder has the original QBCore loading screen with assets including audio, branding, images, keybind icons, and video, plus the HTML interface. The qb-radialmenu-main folder has the original QBCore radial menu with client scripts for clothing, the main menu, stretchers, and trunks, the HTML interface with CSS and JavaScript, 12 locale files, server scripts, and stream files. The qb-spawn-main folder has the original QBCore spawn selector with client and server scripts, configuration, 10 locale files, and an HTML interface with Vue.js.