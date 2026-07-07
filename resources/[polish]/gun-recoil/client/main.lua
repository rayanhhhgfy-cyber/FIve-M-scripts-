local recoilActive = false
local currentClass = nil

CreateThread(function()
    while true do
        Wait(50)
        if Config.GunRecoil.enabled then
            local ped = PlayerPedId()
            if IsPedArmed(ped, 4) or IsPedArmed(ped, 2) then
                local _, weapon = GetCurrentPedWeapon(ped, true)
                local weaponClass = GetWeapontypeGroup(weapon)
                local class = 'PISTOL'
                if weaponClass == 1 then class = 'PISTOL' end
                if weaponClass == 2 then class = 'SMG' end
                if weaponClass == 3 then class = 'RIFLE' end
                if weaponClass == 4 then class = 'MG' end
                if weaponClass == 5 then class = 'SHOTGUN' end
                if weaponClass == 6 then class = 'SNIPER' end
                local settings = Config.GunRecoil.weaponClasses[class]
                if settings and IsPedShooting(ped) then
                    local camRot = GetGameplayCamRot()
                    local recoil = settings.recoil * Config.GunRecoil.recoilMultiplier
                    local shake = settings.shake * Config.GunRecoil.recoilMultiplier
                    SetGameplayCamRelativePitch(camRot.x - recoil, 1.0)
                    ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', shake)
                end
            end
        end
    end
end)

function GetWeapontypeGroup(weaponHash)
    local groups = {
        { min = 0x0, max = 0x20000, class = 1 },
        { min = 0x20000, max = 0x40000, class = 2 },
        { min = 0x40000, max = 0x60000, class = 3 },
        { min = 0x60000, max = 0x80000, class = 4 },
        { min = 0x80000, max = 0xA0000, class = 5 },
        { min = 0xA0000, max = 0xC0000, class = 6 },
    }
    for _, g in ipairs(groups) do
        if weaponHash >= g.min and weaponHash < g.max then return g.class end
    end
    return 1
end
