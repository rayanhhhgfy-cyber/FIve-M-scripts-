Config = Config or {}

Config.Forensics = {
    collectionRange = 3.0,
    analysisTime = 4000,
    bloodPoolModels = {
        `prop_blood_pool`,
        `prop_blood_pool_dried`,
        `p_bloodpool`,
    },
    casingModels = {
        `prop_shell_casing`,
        `prop_shell_casing_02`,
    },
    terminalLocation = vec3(-1454.36, -519.81, 29.88),
    terminalHeading = 215.0,
    maxEvidenceStorage = 20,
    markers = {
        terminal = { type = 1, color = { r = 0, g = 188, b = 212 }, scale = 1.5 },
        evidence = { type = 27, color = { r = 255, g = 215, b = 0 }, scale = 0.8 },
    },
}
