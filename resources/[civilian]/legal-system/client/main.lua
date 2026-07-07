-- Client side provides interaction hooks via ox_target and commands

RegisterNetEvent('legal:client:openCourtApp', function()
  QBox.Functions.TriggerCallback('legal:server:getCourtCases', function(cases)
    local items = {}
    for _, c in ipairs(cases) do
      table.insert(items, {
        title = 'Case #' .. c.id,
        description = c.charges .. ' | Defendant: ' .. c.defendant,
        icon = 'fas fa-gavel',
        onSelect = function()
          local input = Wrappers.InputDialog({
            title = 'Sentence Case #' .. c.id,
            options = {
              { type = 'number', label = 'Fine ($)', placeholder = '0' },
              { type = 'number', label = 'Prison (hours)', placeholder = '0' },
            }
          })
          if input then
            TriggerServerEvent('legal:server:sentence', c.id, tonumber(input[1]), tonumber(input[2]))
          end
        end
      })
    end
    Wrappers.ContextMenu({ id = 'court_cases', title = 'Active Cases', menuItems = items })
  end)
end)

RegisterNetEvent('legal:client:openAuctionHouse', function()
  QBox.Functions.TriggerCallback('legal:server:getActiveAuctions', function(auctions)
    if #auctions == 0 then Wrappers.Notify('No active auctions', 'info') return end
    local items = {}
    for _, a in ipairs(auctions) do
      table.insert(items, {
        title = a.vehicle_plate,
        description = 'Current bid: $' .. (a.current_bid or 1000),
        icon = 'fas fa-car',
        onSelect = function()
          local input = Wrappers.InputDialog({
            title = 'Place Bid',
            options = { { type = 'number', label = 'Your bid ($)', placeholder = tostring((a.current_bid or 1000) + 100) } }
          })
          if input then TriggerServerEvent('legal:server:placeBid', a.id, tonumber(input[1])) end
        end
      })
    end
    Wrappers.ContextMenu({ id = 'auctions', title = 'Seized Asset Auctions', menuItems = items })
  end)
end)
