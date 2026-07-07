return {
	['bandage'] = {
		label = 'Bandage',
		weight = 115,
		client = {
			anim = { dict = 'missheistdockssetup1clipboard@idle_a', clip = 'idle_a', flag = 49 },
			prop = { model = `prop_rolled_sock_02`, pos = vec3(-0.14, -0.14, -0.08), rot = vec3(-50.0, -50.0, -0.0) },
			disable = { move = true, car = true, combat = true },
			usetime = 2500,
		}
	},

	['black_money'] = {
		label = 'Dirty Money',
	},

	['burger'] = {
		label = 'Burger',
		weight = 220,
		client = {
			status = { hunger = 200000 },
			anim = 'eating',
			prop = 'burger',
			usetime = 2500,
			notification = 'You ate a delicious burger'
		},
	},

	['sprunk'] = {
		label = 'Sprunk',
		weight = 350,
		client = {
			status = { thirst = 200000 },
			anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
			prop = { model = `prop_ld_can_01`, pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
			usetime = 2500,
			notification = 'You quenched your thirst with a sprunk'
		}
	},

	['parachute'] = {
		label = 'Parachute',
		weight = 8000,
		stack = false,
		client = {
			anim = { dict = 'clothingshirt', clip = 'try_shirt_positive_d' },
			usetime = 1500
		}
	},

	['garbage'] = {
		label = 'Garbage',
	},

	['paperbag'] = {
		label = 'Paper Bag',
		weight = 1,
		stack = false,
		close = false,
		consume = 0
	},

	['identification'] = {
		label = 'Identification',
		client = {
			image = 'card_id.png'
		}
	},

	['panties'] = {
		label = 'Knickers',
		weight = 10,
		consume = 0,
		client = {
			status = { thirst = -100000, stress = -25000 },
			anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
			prop = { model = `prop_cs_panties_02`, pos = vec3(0.03, 0.0, 0.02), rot = vec3(0.0, -13.5, -1.5) },
			usetime = 2500,
		}
	},

	['lockpick'] = {
		label = 'Lockpick',
		weight = 160,
		stack = false,
		description = 'Used to hotwire vehicles. Breakable on failed attempt.',
		client = {
			image = 'lockpick.png',
		}
	},

	['vehicle_key'] = {
		label = 'Vehicle Key',
		weight = 10,
		stack = false,
		description = 'Electronic key for a specific vehicle. Shows plate in metadata.',
		client = {
			image = 'carkey.png',
		}
	},

	['phone'] = {
		label = 'Phone',
		weight = 190,
		stack = false,
		consume = 0,
		client = {
			add = function(total)
				if total > 0 then
					pcall(function() return exports.npwd:setPhoneDisabled(false) end)
				end
			end,
			remove = function(total)
				if total < 1 then
					pcall(function() return exports.npwd:setPhoneDisabled(true) end)
				end
			end
		}
	},

	-- Heist Items
	['drill'] = {
		label = 'Industrial Drill',
		weight = 3000,
		stack = false,
		description = 'Heavy-duty industrial drill for vault doors and safes.',
	},
	['hack_usb'] = {
		label = 'Hack USB',
		weight = 50,
		stack = true,
		description = 'USB loaded with bypass software for security terminals. Single-use.',
	},
	['c4_charge'] = {
		label = 'C4 Charge',
		weight = 2500,
		stack = false,
		description = 'Explosive charge with remote detonator. Breaches reinforced doors and walls.',
	},
	['heist_loot'] = {
		label = 'Valuable Loot',
		weight = 500,
		stack = false,
		description = 'Assorted valuables from a heist. Needs laundering before use.',
	},
	['heist_mask'] = {
		label = 'Heist Mask',
		weight = 100,
		stack = false,
		consume = 0,
		description = 'Disposable mask for concealing identity during heists.',
		client = {
			export = 'multi-heists.wearMask',
		}
	},

	['money'] = {
		label = 'Money',
	},

	['mustard'] = {
		label = 'Mustard',
		weight = 500,
		client = {
			status = { hunger = 25000, thirst = 25000 },
			anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
			prop = { model = `prop_food_mustard`, pos = vec3(0.01, 0.0, -0.07), rot = vec3(1.0, 1.0, -1.5) },
			usetime = 2500,
			notification = 'You.. drank mustard'
		}
	},

	['water'] = {
		label = 'Water',
		weight = 500,
		client = {
			status = { thirst = 200000 },
			anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
			prop = { model = `prop_ld_flow_bottle`, pos = vec3(0.03, 0.03, 0.02), rot = vec3(0.0, 0.0, -1.5) },
			usetime = 2500,
			cancel = true,
			notification = 'You drank some refreshing water'
		}
	},

	['radio'] = {
		label = 'Radio',
		weight = 200,
		stack = true,
		description = 'Handheld radio for communication',
	},

	['armour'] = {
		label = 'Bulletproof Vest',
		weight = 3000,
		stack = false,
		client = {
			anim = { dict = 'clothingshirt', clip = 'try_shirt_positive_d' },
			usetime = 3500
		}
	},

	['clothing'] = {
		label = 'Clothing',
		consume = 0,
	},

	['mastercard'] = {
		label = 'Fleeca Card',
		stack = false,
		weight = 10,
		client = {
			image = 'card_bank.png'
		}
	},

	['scrapmetal'] = {
		label = 'Scrap Metal',
		weight = 80,
	},

	-- CID Custom Items

	['gps_tracker'] = {
		label = 'GPS Tracker',
		weight = 50,
		stack = true,
		description = 'Magnetic GPS tracker for undercover vehicle deployment. Attach to any vehicle to track its location.',
	},

	['tracker_sweeper'] = {
		label = 'Tracker Sweeper',
		weight = 300,
		stack = false,
		description = 'RF scanner that detects hidden GPS trackers. Use near vehicles to sweep for bugs.',
	},

	['covert_lockpick'] = {
		label = 'Covert Lockpick Set',
		weight = 200,
		stack = false,
		description = 'Advanced ceramic lockpick set. Silent entry for doors and vehicles. Leaves minimal trace.',
	},

	['alarm_bypass'] = {
		label = 'Alarm Bypass Module',
		weight = 150,
		stack = true,
		description = 'Electronic bypass module for vehicle and property alarm systems. Single-use.',
	},

	['plant_evidence'] = {
		label = 'Plant Evidence Kit',
		weight = 250,
		stack = true,
		description = 'Pre-packaged evidence kit for covert operations. Includes DNA swab, fake IDs, and trace materials.',
	},

	['surveillance_camera'] = {
		label = 'Pen Camera',
		weight = 80,
		stack = true,
		description = 'Covert pen camera with 48-hour battery. Streams live footage to CID surveillance console.',
	},

	['audio_bug'] = {
		label = 'Audio Bug',
		weight = 50,
		stack = true,
		description = 'Covert audio listening device. 72-hour battery. Live audio feed to CID surveillance console.',
	},

	-- LSPD Uniforms & Armor
	['lspd_cadet_uniform'] = {
		label = 'LSPD Cadet Uniform',
		weight = 500,
		stack = false,
		consume = 0,
		description = 'Standard LSPD Cadet uniform — Mission Row PD',
		client = {
			export = 'police-uniforms.applyUniform',
		}
	},
	['lspd_officer_uniform'] = {
		label = 'LSPD Officer Uniform',
		weight = 500,
		stack = false,
		consume = 0,
		description = 'Standard LSPD Officer uniform — Mission Row PD',
		client = {
			export = 'police-uniforms.applyUniform',
		}
	},
	['lspd_sgt_uniform'] = {
		label = 'LSPD Sergeant Uniform',
		weight = 550,
		stack = false,
		consume = 0,
		description = 'LSPD Sergeant uniform — Mission Row PD',
		client = {
			export = 'police-uniforms.applyUniform',
		}
	},
	['lspd_lt_uniform'] = {
		label = 'LSPD Lieutenant Uniform',
		weight = 550,
		stack = false,
		consume = 0,
		description = 'LSPD Lieutenant uniform — Mission Row PD',
		client = {
			export = 'police-uniforms.applyUniform',
		}
	},
	['lspd_chief_uniform'] = {
		label = 'LSPD Chief Uniform',
		weight = 600,
		stack = false,
		consume = 0,
		description = 'LSPD Chief of Police uniform — Mission Row PD',
		client = {
			export = 'police-uniforms.applyUniform',
		}
	},
	['lspd_patrol_vest'] = {
		label = 'LSPD Patrol Vest',
		weight = 2000,
		stack = false,
		description = 'Standard issue LSPD patrol vest — ballistic protection',
		client = {
			anim = { dict = 'clothingshirt', clip = 'try_shirt_positive_d' },
			usetime = 3500,
			armor = 50,
		}
	},
	['lspd_heavy_vest'] = {
		label = 'LSPD Heavy Vest',
		weight = 3500,
		stack = false,
		description = 'Heavy-duty LSPD tactical vest — maximum protection',
		client = {
			anim = { dict = 'clothingshirt', clip = 'try_shirt_positive_d' },
			usetime = 5000,
			armor = 100,
		}
	},

	-- CID Uniforms & Armor
	['cid_agent_uniform'] = {
		label = 'CID Agent Uniform',
		weight = 500,
		stack = false,
		consume = 0,
		description = 'CID Agent field uniform — CID Headquarters',
		client = {
			export = 'police-uniforms.applyUniform',
		}
	},
	['cid_director_uniform'] = {
		label = 'CID Director Uniform',
		weight = 600,
		stack = false,
		consume = 0,
		description = 'CID Director command uniform — CID Headquarters',
		client = {
			export = 'police-uniforms.applyUniform',
		}
	},
	['cid_tactical_vest'] = {
		label = 'CID Tactical Vest',
		weight = 2500,
		stack = false,
		description = 'CID tactical vest — lightweight ballistic protection',
		client = {
			anim = { dict = 'clothingshirt', clip = 'try_shirt_positive_d' },
			usetime = 3500,
			armor = 60,
		}
	},
	['cid_heavy_armor'] = {
		label = 'CID Heavy Armor',
		weight = 4000,
		stack = false,
		description = 'CID heavy armor rig — full tactical protection',
		client = {
			anim = { dict = 'clothingshirt', clip = 'try_shirt_positive_d' },
			usetime = 5000,
			armor = 120,
		}
	},

	-- Forensics Items
	['evidence_bag'] = {
		label = 'Evidence Bag',
		weight = 20,
		stack = false,
		consume = 0,
		description = 'Sterile evidence bag for storing collected evidence.',
	},
	['fingerprint_kit'] = {
		label = 'Fingerprint Kit',
		weight = 200,
		stack = false,
		description = 'Forensic fingerprint collection kit. Use on surfaces to lift prints.',
		client = {
			export = 'forensics.collectFingerprint',
		}
	},
	['casing_kit'] = {
		label = 'Casing Collection Kit',
		weight = 250,
		stack = false,
		description = 'Forensic casing collection kit. Use near recent gunfire to collect shell casings.',
		client = {
			export = 'forensics.collectCasing',
		}
	},
	['dna_swab'] = {
		label = 'DNA Swab Kit',
		weight = 150,
		stack = false,
		description = 'Sterile DNA swab kit. Use on blood pools to collect DNA samples.',
		client = {
			export = 'forensics.collectDNA',
		}
	},

	['repair_kit'] = {
		label = 'Repair Kit',
		weight = 2000,
		stack = false,
		description = 'Professional vehicle repair kit. Fully restores engine and body health.',
		client = {
			export = 'repair-kit.useRepairKit',
		}
	},

	['handcuffs'] = {
		label = 'Metal Handcuffs',
		weight = 200,
		stack = false,
		description = 'Standard issue metal handcuffs. More durable than zip ties.',
		client = {
			export = 'item-actions.useHandcuffs',
		}
	},

	['bodycam'] = {
		label = 'Body Camera',
		weight = 150,
		stack = false,
		consume = 0,
		description = 'Chest-mounted body camera with recording indicator.',
		client = {
			export = 'item-actions.useBodycam',
		}
	},

	['police_ram'] = {
		label = 'Breaching Ram',
		weight = 5000,
		stack = false,
		description = 'Heavy breaching ram for forced entry through locked doors.',
		client = {
			export = 'item-actions.usePoliceRam',
		}
	},

	['binoculars'] = {
		label = 'Binoculars',
		weight = 500,
		stack = false,
		description = 'High-powered binoculars for surveillance. Use to zoom and mark waypoints.',
		client = {
			export = 'item-actions.useBinoculars',
		}
	},

	['spikestrip'] = {
		label = 'Spike Strip',
		weight = 3000,
		stack = false,
		description = 'Police spike strip for deploying on roads to puncture vehicle tires.',
		client = {
			image = 'spikestrip.png',
		}
	},

	['roadflare'] = {
		label = 'Road Flare',
		weight = 200,
		stack = true,
		description = 'Bright red road flare for traffic control and emergency signaling.',
		client = {
			image = 'roadflare.png',
		}
	},

	['sandwich'] = {
		label = 'Sandwich',
		weight = 200,
		client = {
			status = { hunger = 150000 },
			anim = 'eating',
			prop = 'burger',
			usetime = 2500,
			notification = 'You ate a sandwich'
		},
	},

	['coffee'] = {
		label = 'Coffee',
		weight = 200,
		client = {
			status = { thirst = 100000, stress = -15000 },
			anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
			prop = { model = `prop_fib_coffee`, pos = vec3(0.01, 0.0, 0.02), rot = vec3(0.0, 0.0, -1.5) },
			usetime = 2500,
			notification = 'You drank a hot coffee'
		},
	},

	['backpack'] = {
		label = 'Backpack',
		weight = 800,
		stack = false,
		consume = 0,
		description = 'Durable backpack. Increases inventory carrying capacity.',
		client = {
			image = 'backpack.png',
		}
	},

	['tunerchip'] = {
		label = 'Tuner Chip',
		weight = 50,
		stack = false,
		description = 'Illegal ECU tuning chip. Boosts vehicle performance when installed.',
		client = {
			image = 'tunerchip.png',
		}
	},

	['lighter'] = {
		label = 'Lighter',
		weight = 30,
		stack = false,
		consume = 0,
		description = 'Standard disposable lighter. Useful for various purposes.',
		client = {
			image = 'lighter.png',
		}
	},

	['medikit'] = {
		label = 'Medical Kit',
		weight = 500,
		stack = false,
		description = 'Standard medical kit for treating injuries. Heals 50 health.',
		client = {
			anim = { dict = 'missheistdockssetup1clipboard@idle_a', clip = 'idle_a', flag = 49 },
			prop = { model = `prop_medikit_01`, pos = vec3(0.0, 0.0, 0.01), rot = vec3(0.0, 0.0, 0.0) },
			usetime = 5000,
			status = { health = 50000 },
		}
	},

	['cid_laptop'] = {
		label = 'CID Laptop',
		weight = 1500,
		stack = false,
		consume = 0,
		description = 'CID-issued field laptop with encrypted database access and surveillance software.',
		client = {
			image = 'cid_laptop.png',
		}
	},

	['drone'] = {
		label = 'Surveillance Drone',
		weight = 2000,
		stack = false,
		description = 'Covert surveillance drone with night vision. Deploy for aerial reconnaissance.',
		client = {
			image = 'drone.png',
		}
	},

	['cid_badge'] = {
		label = 'CID Badge',
		weight = 50,
		stack = false,
		consume = 0,
		description = 'CID identification badge. Display to identify yourself as CID personnel.',
		client = {
			image = 'cid_badge.png',
		}
	},

	['cid_radio'] = {
		label = 'CID Encrypted Radio',
		weight = 250,
		stack = false,
		description = 'Encrypted CID radio with secure channel access and scrambler.',
		client = {
			image = 'cid_radio.png',
		}
	},

	['cid_tablet'] = {
		label = 'CID Field Tablet',
		weight = 800,
		stack = false,
		consume = 0,
		description = 'CID field tablet with encrypted database access, case files, and surveillance feeds.',
		client = {
			image = 'cid_tablet.png',
		}
	},

	['wiretap_kit'] = {
		label = 'Wiretap Kit',
		weight = 500,
		stack = false,
		description = 'Advanced wiretap kit for court-authorized telephone surveillance. Includes recording interface.',
		client = {
			image = 'wiretap_kit.png',
		}
	},

	-- New Items
	['radar_gun'] = {
		label = 'Radar Gun',
		weight = 800,
		stack = false,
		description = 'Handheld radar speed gun. Aim at traffic to capture speed readings.',
		client = {
			export = 'radar-gun.useRadarGun',
		}
	},
	['traffic_cone'] = {
		label = 'Traffic Cone',
		weight = 500,
		stack = true,
		description = 'Reflective traffic cone for road safety and crowd control.',
		client = {
			export = 'road-deployables.useTrafficCone',
		}
	},
	['barrier'] = {
		label = 'Road Barrier',
		weight = 3000,
		stack = false,
		description = 'Portable road barrier for blocking traffic and securing perimeters.',
		client = {
			export = 'road-deployables.useBarrier',
		}
	},
	['stretcher'] = {
		label = 'EMS Stretcher',
		weight = 8000,
		stack = false,
		description = 'Wheeled medical stretcher. Deploy to transport injured patients.',
		client = {
			export = 'stretcher-system.useStretcher',
		}
	},
	['notepad'] = {
		label = 'Notepad',
		weight = 100,
		stack = false,
		consume = 0,
		description = 'A notepad for taking notes and case reports. Use with a pen.',
		client = {
			export = 'notepad.useNotepad',
		}
	},
	['pen'] = {
		label = 'Pen',
		weight = 10,
		stack = false,
		consume = 0,
		description = 'A ballpoint pen. Required to write in your notepad.',
	},
	['hammer'] = {
		label = 'Hammer',
		weight = 800,
		stack = false,
		description = 'Standard claw hammer. Useful for light demolition and repairs.',
		client = {
			export = 'item-actions.useHammer',
		}
	},
	['wrench'] = {
		label = 'Wrench',
		weight = 600,
		stack = false,
		description = 'Adjustable wrench for mechanical work and vehicle repairs.',
		client = {
			export = 'item-actions.useWrench',
		}
	},
}
