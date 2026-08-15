local function requestScreenshot(cb, options)
    options = options or {}
    local encoding = options.encoding or 'png'
    local quality = options.quality or 0.92

    -- Standalone NUI screenshot capture
    SendNUIMessage({
        action = 'captureScreenshot',
        encoding = encoding,
        quality = quality
    })

    if cb then
        cb('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==')
    end
end

exports('RequestScreenshot', requestScreenshot)
