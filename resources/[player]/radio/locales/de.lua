local Translations ={
    ["not_on_radio"] = "Du bist nicht mit einem Signal verbunden",
    ["joined_to_radio"] = "Du bist verbunden mit: %{channel}",
    ["restricted_channel_error"] = "Du kannst dich nicht mit diesem Signal verbinden!",
    ["invalid_radio"] = "Diese Frequenz ist nicht verfügbar.",
    ["you_on_radio"] = "Du bist bereits mit diesem Kanal verbunden",
    ["you_leave"] = "Du hast den Kanal verlassen.",
    ['volume_radio'] = 'Neue Lautstärke %{value}',
    ['decrease_radio_volume'] = 'Das Radio ist bereits auf maximaler Lautstärke eingestellt',
    ['increase_radio_volume'] = 'Das Radio ist bereits auf der niedrigsten Lautstärke eingestellt',
}

if GetConvar('qbx_locale', 'en') == 'de' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true,
        fallbackLang = Lang,
    })
end
