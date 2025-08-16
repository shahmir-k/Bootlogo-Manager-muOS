-- Popup Module for Bootlogo Manager
-- Handles popup dialogs and confirmations

local Config = {}

local popup = {}

-- Popup state
popup.state = {
    active = false,
    title = "",
    message1 = "",
    message2 = "",
    warning = "",
    selectedOption = 1, -- 1 = Yes, 2 = No
    optionText = {"Yes", "No"},
    totalOptions = 2,
    mode = "" -- Custom mode for special popups
}

-- Set config function
function popup.setConfig(configObj)
    Config = configObj
end

-- Draw the popup interface
function popup.draw(fontBig, fontSmall)
    if not popup.state.active then return end
    
    -- Draw semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, Config.WINDOW_WIDTH, Config.WINDOW_HEIGHT)
    
    -- Dynamically size popup based on screen size
    local popupWidth = math.min(580, Config.WINDOW_WIDTH - 60)
    local popupHeight = 200
    local popupX = (Config.WINDOW_WIDTH - popupWidth) / 2
    local popupY = (Config.WINDOW_HEIGHT - popupHeight) / 2
    
    -- Popup background
    love.graphics.setColor(unpack(Config.COLORS.HEADER_BG))
    love.graphics.rectangle("fill", popupX, popupY, popupWidth, popupHeight, 8, 8)
    
    -- Popup border
    love.graphics.setColor(unpack(Config.COLORS.TEXT))
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", popupX, popupY, popupWidth, popupHeight, 8, 8)
    
    -- Title with dynamic color based on mode
    love.graphics.setFont(fontBig)
    if popup.state.mode == "success" then
        love.graphics.setColor(0.2, 0.8, 0.2, 1) -- Green for success
    elseif popup.state.mode == "error" then
        love.graphics.setColor(1, 0.4, 0.4, 1) -- Light red (same as warning) for error
    else
        love.graphics.setColor(unpack(Config.COLORS.TEXT)) -- Default white for other modes
    end
    local titleWidth = fontBig:getWidth(popup.state.title)
    local titleX = popupX + (popupWidth - titleWidth) / 2
    love.graphics.print(popup.state.title, titleX, popupY + 20)
    
    -- Calculate dynamic positioning based on content
    local currentY = popupY + 60
    
    -- Message1 (if not empty)
    if popup.state.message1 ~= "" then
        love.graphics.setFont(fontSmall)
        love.graphics.setColor(unpack(Config.COLORS.TEXT))
        local message1Width = fontSmall:getWidth(popup.state.message1)
        local message1X = popupX + (popupWidth - message1Width) / 2
        love.graphics.print(popup.state.message1, message1X, currentY)
        currentY = currentY + 20
    end
    
    -- Message2 (if not empty)
    if popup.state.message2 ~= "" then
        love.graphics.setFont(fontSmall)
        love.graphics.setColor(unpack(Config.COLORS.TEXT))
        local message2Width = fontSmall:getWidth(popup.state.message2)
        local message2X = popupX + (popupWidth - message2Width) / 2
        love.graphics.print(popup.state.message2, message2X, currentY)
        currentY = currentY + 20
    end
    
    -- Warning (if any)
    if popup.state.warning ~= "" then
        love.graphics.setColor(1, 0.4, 0.4, 1) -- Light red color
        --love.graphics.setColor(1, 0.5, 0) -- Orange for warnings
        local warningWidth = fontSmall:getWidth(popup.state.warning)
        local warningX = popupX + (popupWidth - warningWidth) / 2
        love.graphics.print(popup.state.warning, warningX, currentY)
    end
    
    -- Buttons
    local buttonWidth = 100
    local buttonHeight = 40
    local buttonY = popupY + popupHeight - 60
    
    if popup.state.totalOptions > 0 then
        -- Calculate button spacing based on number of options and popup width
        local totalButtonWidth = popup.state.totalOptions * buttonWidth
        local spacing = 20
        local totalSpacing = (popup.state.totalOptions - 1) * spacing
        local totalWidth = totalButtonWidth + totalSpacing
        
        -- Ensure buttons fit within popup width, scale down if needed
        if totalWidth > popupWidth - 40 then
            local scale = (popupWidth - 40) / totalWidth
            buttonWidth = buttonWidth * scale
            spacing = spacing * scale
            totalButtonWidth = popup.state.totalOptions * buttonWidth
            totalSpacing = (popup.state.totalOptions - 1) * spacing
            totalWidth = totalButtonWidth + totalSpacing
        end
        
        -- Calculate starting X position to center all buttons
        local startX = popupX + (popupWidth - totalWidth) / 2
        
        -- Draw each button
        for i = 1, popup.state.totalOptions do
            local buttonX = startX + (i - 1) * (buttonWidth + spacing)
            local optionText = popup.state.optionText[i] or "Option " .. i
            
            -- Button background
            if popup.state.selectedOption == i then
                love.graphics.setColor(unpack(Config.COLORS.BUTTON_HOVER))
            else
                love.graphics.setColor(unpack(Config.COLORS.BUTTON_BG))
            end
            love.graphics.rectangle("fill", buttonX, buttonY, buttonWidth, buttonHeight, 4, 4)
            
            -- Button border
            love.graphics.setColor(unpack(Config.COLORS.TEXT))
            love.graphics.rectangle("line", buttonX, buttonY, buttonWidth, buttonHeight, 4, 4)
            
            -- Button text
            love.graphics.setColor(unpack(Config.COLORS.BUTTON_TEXT))
            local textWidth = fontBig:getWidth(optionText)
            local textX = buttonX + (buttonWidth - textWidth) / 2
            love.graphics.print(optionText, textX, buttonY + 10)
        end
    end
end

-- Show a popup
function popup.show(title, message1, message2, warning, mode, optionText, defaultOption)
    if title ~= nil then
        popup.state.title = title
    end
    if message1 ~= nil then
        popup.state.message1 = message1
    end
    if message2 ~= nil then
        popup.state.message2 = message2
    end
    if warning ~= nil then
        popup.state.warning = warning
    end
    if mode ~= nil then
        popup.state.mode = mode
    end
    if optionText ~= nil then
        popup.state.optionText = optionText
        popup.state.totalOptions = #optionText
    end
    if defaultOption ~= nil then
        if defaultOption == "yes" then
            popup.state.selectedOption = 1
        elseif defaultOption == "no" then
            popup.state.selectedOption = 2
        elseif type(defaultOption) == "number" and defaultOption <= popup.state.totalOptions then
            popup.state.selectedOption = defaultOption
        elseif type(defaultOption) == "string" then
            -- Find the index of the string in optionText
            for i, option in ipairs(optionText) do
                if option == defaultOption then
                    popup.state.selectedOption = i
                    break
                end
            end
        end
    end
    popup.state.active = true
end

-- Hide the popup
function popup.hide()
    popup.state.active = false
    -- popup.state.title = "Title Not Set"
    -- popup.state.message1 = "Message1 Not Set"
    -- popup.state.message2 = "Message2 Not Set"
    -- popup.state.warning = "Warning Not Set"
    -- popup.state.selectedOption = 1
    -- popup.state.optionText = {"Yes", "No"}
    -- popup.state.totalOptions = 2
    -- popup.state.mode = "Not Set"
end

-- Handle popup input
function popup.handleInput(dt, lastInputTime, inputDebounceDelay)
    if not popup.state.active then return lastInputTime end
    
    lastInputTime = lastInputTime + dt
    
    if love.joystick.getJoysticks()[1] then
        local joystick = love.joystick.getJoysticks()[1]
        
        -- Left/Right navigation
        if joystick:isGamepadDown("dpleft") and lastInputTime >= inputDebounceDelay then
            popup.state.selectedOption = popup.state.selectedOption - 1
            if popup.state.selectedOption < 1 then
                popup.state.selectedOption = popup.state.totalOptions
            end
            lastInputTime = 0
        elseif joystick:isGamepadDown("dpright") and lastInputTime >= inputDebounceDelay then
            popup.state.selectedOption = popup.state.selectedOption + 1
            if popup.state.selectedOption > popup.state.totalOptions then
                popup.state.selectedOption = 1
            end
            lastInputTime = 0
        end
        
        -- A button to select
        if joystick:isGamepadDown("a") and lastInputTime >= inputDebounceDelay then
            popup.handleSelection()
            lastInputTime = 0
        end
        
        -- B button to cancel (selects No)
        if joystick:isGamepadDown("b") and lastInputTime >= inputDebounceDelay then
            popup.state.selectedOption = 2
            popup.handleSelection()
            lastInputTime = 0
        end
    end
    
    -- Keyboard fallback
    if love.keyboard.isDown("left") and lastInputTime >= inputDebounceDelay then
        popup.state.selectedOption = popup.state.selectedOption - 1
        if popup.state.selectedOption < 1 then
            popup.state.selectedOption = popup.state.totalOptions
        end
        lastInputTime = 0
    elseif love.keyboard.isDown("right") and lastInputTime >= inputDebounceDelay then
        popup.state.selectedOption = popup.state.selectedOption + 1
        if popup.state.selectedOption > popup.state.totalOptions then
            popup.state.selectedOption = 1
        end
        lastInputTime = 0
    end
    
    if love.keyboard.isDown("return") or love.keyboard.isDown("space") then
        popup.handleSelection()
    end
    
    if love.keyboard.isDown("escape") then
        popup.state.selectedOption = 2
        popup.handleSelection()
    end
    
    return lastInputTime
end

-- Handle popup selection (this will be overridden by the main module)
function popup.handleSelection()
    -- This function will be set by the main module to handle specific actions
    if popup.onSelection then
        popup.onSelection(popup.state.selectedOption, popup.state.mode)
    end
end

-- Set the popup title
function popup.setTitle(title)
    popup.state.title = title
end

-- Set the popup message1
function popup.setMessage1(message1)
    popup.state.message1 = message1
end

-- Set the popup message2
function popup.setMessage2(message2)
    popup.state.message2 = message2
end

-- Set the popup warning
function popup.setWarning(warning)
    popup.state.warning = warning
end

-- Set the popup mode
function popup.setMode(mode)
    popup.state.mode = mode
end

-- Set the popup option text
function popup.setOptionText(optionText)
    popup.state.optionText = optionText
    popup.state.totalOptions = #optionText
end

-- Set the popup default option
function popup.setDefaultOption(defaultOption)
    if defaultOption == "yes" then
        popup.state.selectedOption = 1
    elseif defaultOption == "no" then
        popup.state.selectedOption = 2
    elseif type(defaultOption) == "number" and defaultOption <= popup.state.totalOptions then
        popup.state.selectedOption = defaultOption
    elseif type(defaultOption) == "string" then
        -- Find the index of the string in optionText
        for i, option in ipairs(optionText) do
            if option == defaultOption then
                popup.state.selectedOption = i
                break
            end
        end
    end
end

-- Set the popup total options
function popup.setTotalOptions(totalOptions)
    popup.state.totalOptions = totalOptions
end

-- Set the selection handler
function popup.setSelectionHandler(handler)
    popup.onSelection = handler
end

return popup
