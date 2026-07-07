local activeMenus = {}
local menuStack = {}

function RegisterMenu(menuData)
    local menuId = menuData.id or ('menu_' .. #activeMenus + 1)
    menuData.position = menuData.position or Config.Context.defaultPosition
    menuData.canClose = menuData.canClose or Config.MenuDefaults.canClose
    if Config.Context.closeOnSelect and menuData.options then
        for _, opt in ipairs(menuData.options) do
            local originalOnSelect = opt.onSelect
            if originalOnSelect then
                opt.onSelect = function(...)
                    originalOnSelect(...)
                    exports['ox_lib']:closeContext(menuId)
                end
            end
        end
    end
    exports['ox_lib']:registerContext(menuData)
    activeMenus[menuId] = menuData
    return menuId
end

function ShowMenu(menuId)
    if not activeMenus[menuId] then return end
    table.insert(menuStack, menuId)
    exports['ox_lib']:showContext(menuId)
end

function CloseMenu(menuId)
    if menuId then
        exports['ox_lib']:hideContext(menuId)
        for i, id in ipairs(menuStack) do
            if id == menuId then
                table.remove(menuStack, i)
                break
            end
        end
    else
        exports['ox_lib']:hideContext()
        menuStack = {}
    end
end

function GoBack()
    if #menuStack <= 1 then
        CloseMenu()
        return
    end
    local current = table.remove(menuStack)
    local prev = menuStack[#menuStack]
    if prev then
        ShowMenu(prev)
    end
end

function IsMenuOpen()
    return #menuStack > 0
end

function GetActiveMenuId()
    if #menuStack > 0 then
        return menuStack[#menuStack]
    end
    return nil
end

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[ox-context] Context engine initialized.^7')
end)

exports('RegisterMenu', RegisterMenu)
exports('ShowMenu', ShowMenu)
exports('CloseMenu', CloseMenu)
exports('GoBack', GoBack)
exports('IsMenuOpen', IsMenuOpen)
exports('GetActiveMenuId', GetActiveMenuId)
