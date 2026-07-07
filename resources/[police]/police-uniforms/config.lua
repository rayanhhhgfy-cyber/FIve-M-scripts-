Config = Config or {}
Config.Uniforms = Config.Uniforms or {}

Config.Uniforms.Presets = {
    -- LSPD — Mission Row
    ['lspd_cadet_uniform'] = {
        label = 'LSPD Cadet',
        components = {
            { componentId = 3, drawable = 0, texture = 0 },  -- torso
            { componentId = 4, drawable = 1, texture = 0 },  -- pants
            { componentId = 6, drawable = 2, texture = 0 },  -- shoes
            { componentId = 8, drawable = 0, texture = 0 },  -- undershirt
            { componentId = 11, drawable = 1, texture = 0 }, -- hat
        },
        props = {},
    },
    ['lspd_officer_uniform'] = {
        label = 'LSPD Officer',
        components = {
            { componentId = 3, drawable = 0, texture = 1 },
            { componentId = 4, drawable = 1, texture = 0 },
            { componentId = 6, drawable = 2, texture = 0 },
            { componentId = 8, drawable = 0, texture = 1 },
            { componentId = 11, drawable = 1, texture = 1 },
        },
        props = {},
    },
    ['lspd_sgt_uniform'] = {
        label = 'LSPD Sergeant',
        components = {
            { componentId = 3, drawable = 0, texture = 2 },
            { componentId = 4, drawable = 1, texture = 0 },
            { componentId = 6, drawable = 2, texture = 0 },
            { componentId = 8, drawable = 0, texture = 2 },
            { componentId = 11, drawable = 1, texture = 2 },
        },
        props = {},
    },
    ['lspd_lt_uniform'] = {
        label = 'LSPD Lieutenant',
        components = {
            { componentId = 3, drawable = 0, texture = 3 },
            { componentId = 4, drawable = 1, texture = 1 },
            { componentId = 6, drawable = 2, texture = 1 },
            { componentId = 8, drawable = 0, texture = 3 },
            { componentId = 11, drawable = 1, texture = 3 },
        },
        props = {},
    },
    ['lspd_chief_uniform'] = {
        label = 'LSPD Chief',
        components = {
            { componentId = 3, drawable = 0, texture = 4 },
            { componentId = 4, drawable = 1, texture = 1 },
            { componentId = 6, drawable = 2, texture = 1 },
            { componentId = 8, drawable = 0, texture = 4 },
            { componentId = 11, drawable = 2, texture = 0 },
        },
        props = {},
    },

    -- CID — Headquarters
    ['cid_agent_uniform'] = {
        label = 'CID Agent',
        components = {
            { componentId = 3, drawable = 1, texture = 0 },
            { componentId = 4, drawable = 2, texture = 0 },
            { componentId = 6, drawable = 2, texture = 0 },
            { componentId = 8, drawable = 1, texture = 0 },
            { componentId = 11, drawable = 0, texture = 0 },
        },
        props = {},
    },
    ['cid_director_uniform'] = {
        label = 'CID Director',
        components = {
            { componentId = 3, drawable = 1, texture = 1 },
            { componentId = 4, drawable = 2, texture = 1 },
            { componentId = 6, drawable = 2, texture = 1 },
            { componentId = 8, drawable = 1, texture = 1 },
            { componentId = 11, drawable = 0, texture = 1 },
        },
        props = {},
    },
}
