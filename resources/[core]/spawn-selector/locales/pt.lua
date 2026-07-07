local Translations = {
    ui = {
        last_location = "Última localização",
        confirm = "Confirmar",
        where_would_you_like_to_start = "Onde gostaria de começar?",
    }
}

if GetConvar('qbx_locale', 'en') == 'pt' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true,
        fallbackLang = Lang,
    })
end
