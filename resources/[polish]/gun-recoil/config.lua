Config = Config or {}
Config.GunRecoil = {
    enabled = true,
    recoilMultiplier = 1.0,
    weaponClasses = {
        PISTOL = { recoil = 0.5, spread = 0.1, shake = 0.3 },
        SMG = { recoil = 0.8, spread = 0.2, shake = 0.5 },
        RIFLE = { recoil = 1.0, spread = 0.3, shake = 0.7 },
        SHOTGUN = { recoil = 1.5, spread = 0.5, shake = 1.0 },
        MG = { recoil = 0.6, spread = 0.4, shake = 0.6 },
        SNIPER = { recoil = 2.0, spread = 0.05, shake = 1.5 },
    },
}
