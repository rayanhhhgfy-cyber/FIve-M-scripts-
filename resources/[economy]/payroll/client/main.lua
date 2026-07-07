local previousHour = -1
local syncedGameDay = false

CreateThread(function()
    while true do
        Wait(1000)
        local hour = GetClockHours()
        local minute = GetClockMinutes()

        if previousHour ~= -1 then
            if hour == 0 and minute < 5 and previousHour ~= hour then
                TriggerServerEvent('payroll:server:gameDayPassed')
            end
        end

        previousHour = hour

        if not syncedGameDay then
            syncedGameDay = true
            TriggerServerEvent('payroll:server:syncGameTime', hour, minute)
        end
    end
end)

RegisterNetEvent('payroll:client:paydayNotification', function(jobLabel, gradeLabel, amount)
    Wrappers.Notify(('PAYDAY: $%s deposited - %s (%s)'):format(amount, jobLabel, gradeLabel), 'success')
end)
