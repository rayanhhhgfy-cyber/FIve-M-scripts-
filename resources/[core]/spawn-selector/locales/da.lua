local Translations = {
    ui = {
        last_location = "Seneste Placering",
        confirm = "Bekræft",
        where_would_you_like_to_start = "Hvor vil du gerne starte?",
    }
}

if GetConvar('qbx_locale', 'en') == 'da' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true,
        fallbackLang = Lang,
    })
end