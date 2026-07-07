Config = Config or {}
Config.CuffSystem = Config.CuffSystem or {}

Config.CuffSystem = {
    maxCuffDistance = 2.5,
    unlockpickChance = 70,
    lockpickTime = 8000,
    escapeAttemptCooldown = 30,
    allowCuffedPassenger = true,
    cuffedWalkSpeed = 0.35,
    cuffAnim = { dict = 'mp_arresting', idle = 'idle', cuff = 'cuff' },
    uncuffAnim = { dict = 'mp_arresting', clip = 'uncuff' },
    lockpickAnim = { dict = 'mini@repair', clip = 'fixing_a_ped' },
    allowedCuffJobs = { 'police', 'sheriff', 'state_police', 'cid' },
    adminGroups = { 'admin', 'superadmin', 'god' },
}
