-- ============================================================================
-- ox_inventory Item Definitions
-- Drop this file into ox_inventory/data/items.lua to register all custom items
-- ============================================================================

return {
    ['radio'] = {
        label = 'Radio',
        weight = 200,
        stack = true,
        description = 'Handheld radio for communication',
    },
    ['gps_tracker'] = {
        label = 'GPS Tracker',
        weight = 50,
        stack = true,
        description = 'Magnetic GPS tracker for undercover vehicle deployment. Attach to any vehicle to track its location.',
        client = {
            export = 'undercover-vehicles.deployTracker',
        }
    },
    ['tracker_sweeper'] = {
        label = 'Tracker Sweeper',
        weight = 300,
        stack = false,
        description = 'RF scanner that detects hidden GPS trackers. Use near vehicles to sweep for bugs.',
        client = {
            export = 'undercover-vehicles.sweepTrackers',
        }
    },
    ['covert_lockpick'] = {
        label = 'Covert Lockpick Set',
        weight = 200,
        stack = false,
        description = 'Advanced ceramic lockpick set. Silent entry for doors and vehicles. Leaves minimal trace.',
        client = {
            export = 'covert-entry.lockpick',
        }
    },
    ['alarm_bypass'] = {
        label = 'Alarm Bypass Module',
        weight = 150,
        stack = true,
        description = 'Electronic bypass module for vehicle and property alarm systems. Single-use.',
        client = {
            export = 'covert-entry.bypassAlarm',
        }
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
        client = {
            export = 'surveillance-bugs.deployCamera',
        }
    },
    ['audio_bug'] = {
        label = 'Audio Bug',
        weight = 50,
        stack = true,
        description = 'Covert audio listening device. 72-hour battery. Live audio feed to CID surveillance console.',
        client = {
            export = 'surveillance-bugs.deployAudio',
        }
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
}
