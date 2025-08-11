-- Shahmir Khan August 11 2025
-- Bootlogo Manager v1.0.1 Main File
-- https://github.com/shahmir-k
-- https://linkedin.com/in/shahmir-k

local love = require("love")
local Config = require("config")

-- Global variables
local fontBig, fontSmall, fontBold
local selectedButton = 1
local totalButtons = 7
local msgLog = "Bootlogo Manager - Use D-pad to navigate, A to select"

-- Input debounce variables
local lastInputTime = 0
local inputDebounceDelay = 0.2 -- 0.2 seconds

-- File browser variables
local fileBrowser = {
    active = false,
    mode = "file", -- "file" or "themeInstall" or "themeUninstall"
    currentPath = "/mnt/mmc",
    files = {},
    selectedIndex = 1,
    scrollOffset = 0,
    maxVisibleFiles = 8
}

-- Popup variables
local popup = {
    active = false,
    title = "",
    message = "",
    warning = "",
    selectedOption = 1, -- 1 = Yes, 2 = No
    totalOptions = 2,
    mode = "" -- Custom mode for special popups
}

-- Button states
local buttons = {
    {text = "Install Custom Bootlogo", action = "install"},
    {text = "Uninstall Custom Bootlogo", action = "uninstall"},
    {text = "Install Bootlogo to Theme", action = "install_theme"},
    {text = "Uninstall Bootlogo from Theme", action = "uninstall_theme"},
    {text = "Install Bootlogo to All Themes", action = "install_all_themes"},
    {text = "Uninstall Bootlogo from All Themes", action = "uninstall_all_themes"},
    {text = "Delete Current Bootlogo", action = "delete"}
}

function love.load()
    -- Load fonts
    fontBig = love.graphics.newFont(16)
    fontSmall = love.graphics.newFont(12)
    fontBold = love.graphics.newFont(16)
    
    -- Set default font
    love.graphics.setFont(fontBig)
    
    -- Initialize message log
    msgLog = "Bootlogo Manager - Use D-pad to navigate, A to select"
    
    -- Debug: Test direct filesystem access
    print("=== Direct Filesystem Debug ===")
    
    -- Get current working directory using system command
    local handle = io.popen("pwd")
    if handle then
        local pwd = handle:read("*a"):gsub("%s+$", "")  -- Remove trailing whitespace
        handle:close()
        print("Current working directory: " .. pwd)
    end
    
    -- List current directory contents using ls
    print("Current directory contents:")
    local handle2 = io.popen("ls -la")
    if handle2 then
        local result = handle2:read("*a")
        handle2:close()
        for line in result:gmatch("[^\r\n]+") do
            print("  " .. line)
        end
    end
    
    print("=== End Direct Filesystem Debug ===")
end

function love.update(dt)
    -- Handle input
    if popup.active then
        handlePopupInput(dt)
    elseif fileBrowser.active then
        handleFileBrowserInput(dt)
    else
        handleInput(dt)
    end
end

function love.draw()
    -- Draw background
    love.graphics.setColor(unpack(Config.COLORS.BACKGROUND))
    love.graphics.rectangle("fill", 0, 0, Config.WINDOW_WIDTH, Config.WINDOW_HEIGHT)
    
    -- Draw header
    drawHeader()
    
    if popup.active then
        drawPopup()
    elseif fileBrowser.active then
        drawFileBrowser()
    else
        -- Draw buttons
        drawButtons()
    end
    
    -- Draw footer
    drawFooter()
end

function drawHeader()
    local xPos = 0
    local yPos = 0
    
    -- Header background
    love.graphics.setColor(unpack(Config.COLORS.HEADER_BG))
    love.graphics.rectangle("fill", xPos, yPos, Config.WINDOW_WIDTH, 48)
    
    -- Header text
    love.graphics.setColor(unpack(Config.COLORS.TEXT))
    love.graphics.setFont(fontBold)
    love.graphics.print("Bootlogo Manager v1.0.1 by shahmir-k", xPos + 20, yPos + 12)
    
    -- Time
    local now = os.date('*t')
    local formatted_time = string.format("%02d:%02d", tonumber(now.hour), tonumber(now.min))
    love.graphics.print(formatted_time, Config.WINDOW_WIDTH - 80, yPos + 12)
    
    love.graphics.setFont(fontBig)
end

function drawButtons()
    for i, button in ipairs(buttons) do
        local buttonConfig
        if i == 1 then
            buttonConfig = Config.BUTTONS.INSTALL
        elseif i == 2 then
            buttonConfig = Config.BUTTONS.UNINSTALL
        elseif i == 3 then
            buttonConfig = Config.BUTTONS.INSTALL_THEME
        elseif i == 4 then
            buttonConfig = Config.BUTTONS.UNINSTALL_THEME
        elseif i == 5 then
            buttonConfig = Config.BUTTONS.INSTALL_ALL_THEMES
        elseif i == 6 then
            buttonConfig = Config.BUTTONS.UNINSTALL_ALL_THEMES
        elseif i == 7 then
            buttonConfig = Config.BUTTONS.DELETE
        end
        
        -- Button background - use red colors for delete button (button 7)
        if i == selectedButton then
            if i == 7 then
                love.graphics.setColor(unpack(Config.COLORS.DELETE_BUTTON_HOVER))
            else
                love.graphics.setColor(unpack(Config.COLORS.BUTTON_HOVER))
            end
        else
            if i == 7 then
                love.graphics.setColor(unpack(Config.COLORS.DELETE_BUTTON_BG))
            else
                love.graphics.setColor(unpack(Config.COLORS.BUTTON_BG))
            end
        end
        
        love.graphics.rectangle("fill", buttonConfig.x, buttonConfig.y, buttonConfig.width, buttonConfig.height, 8, 8)
        
        -- Button border
        love.graphics.setColor(unpack(Config.COLORS.TEXT))
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", buttonConfig.x, buttonConfig.y, buttonConfig.width, buttonConfig.height, 8, 8)
        
        -- Button text
        love.graphics.setColor(unpack(Config.COLORS.BUTTON_TEXT))
        local textWidth = fontBig:getWidth(button.text)
        local textX = buttonConfig.x + (buttonConfig.width - textWidth) / 2
        local textY = buttonConfig.y + (buttonConfig.height - fontBig:getHeight()) / 2
        love.graphics.print(button.text, textX, textY)
    end
end

function drawFooter()
    local xPos = 8
    local yPos = Config.WINDOW_HEIGHT - 90
    
    -- Message log background
    love.graphics.setColor(unpack(Config.COLORS.HEADER_BG))
    love.graphics.rectangle("fill", xPos, yPos, Config.WINDOW_WIDTH - 16, 40, 4, 4)
    
    -- Message log text
    love.graphics.setColor(unpack(Config.COLORS.TEXT))
    love.graphics.setFont(fontSmall)
    love.graphics.print(msgLog, xPos + 5, yPos + 8)
    
    -- Bottom bar
    xPos = 0
    yPos = Config.WINDOW_HEIGHT - 45
    love.graphics.setColor(unpack(Config.COLORS.HEADER_BG))
    love.graphics.rectangle("fill", xPos, yPos, Config.WINDOW_WIDTH, 45)
    
    -- Control hints
    love.graphics.setColor(unpack(Config.COLORS.TEXT))
    love.graphics.setFont(fontSmall)
    if fileBrowser.active then
        love.graphics.print("D-pad: Navigate | A: Select | B: Back", xPos + 10, yPos + 15)
    else
        love.graphics.print("D-pad: Navigate | A: Select | B: Back", xPos + 10, yPos + 15)
    end
end

function drawPopup()
    -- Draw semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, Config.WINDOW_WIDTH, Config.WINDOW_HEIGHT)
    
    -- Popup background
    local popupWidth = 580
    local popupHeight = 200
    local popupX = (Config.WINDOW_WIDTH - popupWidth) / 2
    local popupY = (Config.WINDOW_HEIGHT - popupHeight) / 2
    
    love.graphics.setColor(unpack(Config.COLORS.HEADER_BG))
    love.graphics.rectangle("fill", popupX, popupY, popupWidth, popupHeight, 8, 8)
    
    -- Popup border
    love.graphics.setColor(unpack(Config.COLORS.TEXT))
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", popupX, popupY, popupWidth, popupHeight, 8, 8)
    
    -- Title
    love.graphics.setColor(unpack(Config.COLORS.TEXT))
    love.graphics.setFont(fontBold)
    local titleWidth = fontBold:getWidth(popup.title)
    local titleX = popupX + (popupWidth - titleWidth) / 2
    love.graphics.print(popup.title, titleX, popupY + 20)
    
    -- Message
    love.graphics.setFont(fontBig)
    love.graphics.setColor(unpack(Config.COLORS.TEXT))
    local messageWidth = fontBig:getWidth(popup.message)
    local messageX = popupX + (popupWidth - messageWidth) / 2
    love.graphics.print(popup.message, messageX, popupY + 60)
    
    -- Warning (in light red)
    love.graphics.setColor(1, 0.4, 0.4, 1) -- Light red color
    local warningWidth = fontSmall:getWidth(popup.warning)
    local warningX = popupX + (popupWidth - warningWidth) / 2
    love.graphics.setFont(fontSmall)
    love.graphics.print(popup.warning, warningX, popupY + 90)
    
    -- Buttons
    local buttonWidth = 100
    local buttonHeight = 40
    local buttonY = popupY + popupHeight - 60
    
    -- Yes button
    local yesX = popupX + (popupWidth / 2) - buttonWidth - 20
    if popup.selectedOption == 1 then
        love.graphics.setColor(unpack(Config.COLORS.BUTTON_HOVER))
    else
        love.graphics.setColor(unpack(Config.COLORS.BUTTON_BG))
    end
    love.graphics.rectangle("fill", yesX, buttonY, buttonWidth, buttonHeight, 4, 4)
    love.graphics.setColor(unpack(Config.COLORS.TEXT))
    love.graphics.rectangle("line", yesX, buttonY, buttonWidth, buttonHeight, 4, 4)
    love.graphics.setColor(unpack(Config.COLORS.BUTTON_TEXT))
    local yesTextWidth = fontBig:getWidth("Yes")
    local yesTextX = yesX + (buttonWidth - yesTextWidth) / 2
    love.graphics.print("Yes", yesTextX, buttonY + 10)
    
    -- No button
    local noX = popupX + (popupWidth / 2) + 20
    if popup.selectedOption == 2 then
        love.graphics.setColor(unpack(Config.COLORS.BUTTON_HOVER))
    else
        love.graphics.setColor(unpack(Config.COLORS.BUTTON_BG))
    end
    love.graphics.rectangle("fill", noX, buttonY, buttonWidth, buttonHeight, 4, 4)
    love.graphics.setColor(unpack(Config.COLORS.TEXT))
    love.graphics.rectangle("line", noX, buttonY, buttonWidth, buttonHeight, 4, 4)
    love.graphics.setColor(unpack(Config.COLORS.BUTTON_TEXT))
    local noTextWidth = fontBig:getWidth("No")
    local noTextX = noX + (buttonWidth - noTextWidth) / 2
    love.graphics.print("No", noTextX, buttonY + 10)
end

function drawFileBrowser()
    local xPos = 20
    local yPos = 80
    local width = Config.WINDOW_WIDTH - 40
    local height = Config.WINDOW_HEIGHT - 200
    
    -- File browser background
    love.graphics.setColor(unpack(Config.COLORS.HEADER_BG))
    love.graphics.rectangle("fill", xPos, yPos, width, height, 8, 8)
    
    -- Current path
    love.graphics.setColor(unpack(Config.COLORS.TEXT))
    love.graphics.setFont(fontSmall)
    love.graphics.print("Path: " .. fileBrowser.currentPath, xPos + 10, yPos + 10)
    
    -- File list
    yPos = yPos + 40
    local itemHeight = 25
    local maxItems = math.floor((height - 40) / itemHeight)
    
    for i = 1, math.min(maxItems, #fileBrowser.files) do
        local itemIndex = i + fileBrowser.scrollOffset
        if itemIndex <= #fileBrowser.files then
            local item = fileBrowser.files[itemIndex]
            local itemY = yPos + (i - 1) * itemHeight
            
            -- Selection highlight
            if itemIndex == fileBrowser.selectedIndex then
                love.graphics.setColor(unpack(Config.COLORS.BUTTON_HOVER))
                love.graphics.rectangle("fill", xPos + 5, itemY, width - 10, itemHeight - 2, 4, 4)
            end
            
            -- Item text
            love.graphics.setColor(unpack(Config.COLORS.TEXT))
            local icon = item.type == "directory" and "[DIR] " or "[FILE] "
            local text = icon .. item.name
            love.graphics.print(text, xPos + 10, itemY + 5)
        end
    end
    
    -- Scroll indicator
    if #fileBrowser.files > maxItems then
        love.graphics.setColor(unpack(Config.COLORS.TEXT_SECONDARY))
        love.graphics.print("Scroll: " .. (fileBrowser.scrollOffset + 1) .. "-" .. math.min(fileBrowser.scrollOffset + maxItems, #fileBrowser.files) .. " of " .. #fileBrowser.files, xPos + 10, yPos + maxItems * itemHeight + 10)
    end
end

function handleInput(dt)
    -- Update input timer
    lastInputTime = lastInputTime + dt
    
    -- D-pad navigation
    if love.joystick.getJoysticks()[1] then
        local joystick = love.joystick.getJoysticks()[1]
        
        -- Up/Down navigation with debounce
        if joystick:isGamepadDown("dpup") and lastInputTime >= inputDebounceDelay then
            selectedButton = selectedButton - 1
            if selectedButton < 1 then
                selectedButton = totalButtons
            end
            lastInputTime = 0 -- Reset timer after input
        elseif joystick:isGamepadDown("dpdown") and lastInputTime >= inputDebounceDelay then
            selectedButton = selectedButton + 1
            if selectedButton > totalButtons then
                selectedButton = 1
            end
            lastInputTime = 0 -- Reset timer after input
        end
        
        -- A button to select (no debounce needed for action buttons)
        if joystick:isGamepadDown("a") and lastInputTime >= inputDebounceDelay then
            handleButtonPress(selectedButton)
            lastInputTime = 0
        end
        
        -- B button to go back/quit (no debounce needed for action buttons)
        if joystick:isGamepadDown("b") and lastInputTime >= inputDebounceDelay then
            lastInputTime = 0 -- Reset timer after input, don't need to reset it but makes me feel better
            love.event.quit()
        end
    end
    
    -- Keyboard fallback with debounce
    if love.keyboard.isDown("up") and lastInputTime >= inputDebounceDelay then
        selectedButton = selectedButton - 1
        if selectedButton < 1 then
            selectedButton = totalButtons
        end
        lastInputTime = 0 -- Reset timer after input
    elseif love.keyboard.isDown("down") and lastInputTime >= inputDebounceDelay then
        selectedButton = selectedButton + 1
        if selectedButton > totalButtons then
            selectedButton = 1
        end
        lastInputTime = 0 -- Reset timer after input
    end
    
    -- Action buttons (no debounce needed)
    if love.keyboard.isDown("return") or love.keyboard.isDown("space") then
        handleButtonPress(selectedButton)
    end
    
    if love.keyboard.isDown("escape") then
        love.event.quit()
    end
end

function handleButtonPress(buttonIndex)
    local button = buttons[buttonIndex]
    
    if button.action == "install" then
        startFileBrowser("file")
    elseif button.action == "uninstall" then
        uninstallBootlogo()
    elseif button.action == "delete" then
        --deleteCurrentBootlogo()

        -- Show confirmation popup for delete
        popup.active = true
        popup.title = "Delete Current Bootlogo"
        popup.message = "Are you sure you want to delete the current bootlogo?"
        popup.warning = "This action cannot be undone. You will need to reinstall a bootlogo."
        popup.selectedOption = 2 -- Default to "No" for safety
        popup.mode = "deleteBootlogo" -- Custom mode for this popup
    elseif button.action == "install_theme" then
        startFileBrowser("themeInstall")
    elseif button.action == "uninstall_theme" then
        startFileBrowser("themeUninstall")
    elseif button.action == "install_all_themes" then
        installBootlogoToAllThemes()
    elseif button.action == "uninstall_all_themes" then
        uninstallBootlogoFromAllThemes()
    end
end

function startFileBrowser(mode)
    fileBrowser.active = true
    fileBrowser.mode = mode or "file"
    
    if fileBrowser.mode == "file" then
        -- Get current working directory using io library
        local handle = io.popen("pwd")
        if handle then
            fileBrowser.currentPath = handle:read("*a"):gsub("%s+$", "")  -- Remove trailing whitespace
            handle:close()
            msgLog = "File Browser - Navigate to select bootlogo file (.bmp)"
        else
            msgLog = "Failed to get current directory"
            fileBrowser.currentPath = "."  -- Fallback to current directory
        end
    elseif fileBrowser.mode == "themeInstall" or fileBrowser.mode == "themeUninstall" then

        local themeExistsHandle = io.popen("test -d /mnt/mmc/MUOS/theme && echo 'exists' || echo 'not_exists'")
        local themeExists = themeExistsHandle:read("*a"):gsub("%s+$", "")
        themeExistsHandle:close()

        if themeExists == "exists" then
            fileBrowser.currentPath = "/mnt/mmc/MUOS/theme"
            msgLog = "Theme Browser - Navigate to select theme file (.muxthm)"
        else
            msgLog = "Failed to find theme directory"
        end
    end
    
    fileBrowser.selectedIndex = 1
    fileBrowser.scrollOffset = 0
    loadDirectoryContents()
    
    
end

function loadDirectoryContents()
    fileBrowser.files = {}
    
    -- Don't show parent directory option when in root directory
    if fileBrowser.currentPath ~= "/" then
        table.insert(fileBrowser.files, {name = "..", type = "directory", path = getParentPath(fileBrowser.currentPath)})
    end
    
    -- Debug: Print current path
    print("Trying to read directory: " .. fileBrowser.currentPath)
    
    -- Use system command to list directory contents
    local command = "ls -la '" .. fileBrowser.currentPath .. "'"
    local handle = io.popen(command)
    if handle then
        local result = handle:read("*a")
        handle:close()
        
        -- Parse the ls output
        for line in result:gmatch("[^\r\n]+") do
            -- Skip total line and . and .. entries
            if not line:match("^total") and not line:match("^d.*%.$") and not line:match("^d.*%.%.$") then
                -- Parse ls -la output format: "drwxr-xr-x 2 user group 4096 date filename"
                local permissions, links, user, group, size, month, day, time, filename = line:match("^([%w-]+)%s+(%d+)%s+(%S+)%s+(%S+)%s+(%d+)%s+(%S+)%s+(%d+)%s+(%S+)%s+(.+)$")
                
                if filename then
                    local fileType = "file"
                    if permissions and permissions:sub(1,1) == "d" then
                        fileType = "directory"
                    end
                    
                    -- Only show directories and supported files based on mode
                    if fileType == "directory" or isSupportedFile(filename) then
                        local itemPath = fileBrowser.currentPath .. "/" .. filename
                        table.insert(fileBrowser.files, {
                            name = filename,
                            type = fileType,
                            path = itemPath
                        })
                        print("Found: " .. filename .. " (type: " .. fileType .. ")")
                    end
                end
            end
        end
    else
        print("Failed to execute ls command")
        msgLog = "Cannot access directory: " .. fileBrowser.currentPath
    end
    
    print("Total files/folders to display: " .. #fileBrowser.files)
    
    -- Sort: directories first, then files
    table.sort(fileBrowser.files, function(a, b)
        if a.type == "directory" and b.type ~= "directory" then
            return true
        elseif a.type ~= "directory" and b.type == "directory" then
            return false
        else
            return a.name < b.name
        end
    end)
end

function getParentPath(path)
    local parts = {}
    for part in path:gmatch("[^/]+") do
        table.insert(parts, part)
    end
    table.remove(parts)
    if #parts == 0 then
        return "/"
    else
        return "/" .. table.concat(parts, "/")
    end
end

function isImageFile(filename)
    local extensions = {".bmp"} --{".png", ".jpg", ".jpeg", ".bmp", ".gif", ".tga"}
    local lowerName = filename:lower()
    for _, ext in ipairs(extensions) do
        if lowerName:match(ext .. "$") then
            return true
        end
    end
    return false
end

function isThemeFile(filename)
    local extensions = {".muxthm"}
    local lowerName = filename:lower()
    for _, ext in ipairs(extensions) do
        if lowerName:match(ext .. "$") then
            return true
        end
    end
    return false
end

function isSupportedFile(filename)
    if fileBrowser.mode == "themeInstall" or fileBrowser.mode == "themeUninstall" then
        return isThemeFile(filename)
    else
        return isImageFile(filename)
    end
end

function handlePopupInput(dt)
    if not popup.active then return end
    
    lastInputTime = lastInputTime + dt
    
    if love.joystick.getJoysticks()[1] then
        local joystick = love.joystick.getJoysticks()[1]
        
        -- Left/Right navigation
        if joystick:isGamepadDown("dpleft") and lastInputTime >= inputDebounceDelay then
            popup.selectedOption = popup.selectedOption - 1
            if popup.selectedOption < 1 then
                popup.selectedOption = popup.totalOptions
            end
            lastInputTime = 0
        elseif joystick:isGamepadDown("dpright") and lastInputTime >= inputDebounceDelay then
            popup.selectedOption = popup.selectedOption + 1
            if popup.selectedOption > popup.totalOptions then
                popup.selectedOption = 1
            end
            lastInputTime = 0
        end
        
        -- A button to select
        if joystick:isGamepadDown("a") and lastInputTime >= inputDebounceDelay then
            handlePopupSelection()
            lastInputTime = 0
        end
        
        -- B button to cancel (selects No)
        if joystick:isGamepadDown("b") and lastInputTime >= inputDebounceDelay then
            popup.selectedOption = 2
            handlePopupSelection()
            lastInputTime = 0
        end
    end
    
    -- Keyboard fallback
    if love.keyboard.isDown("left") and lastInputTime >= inputDebounceDelay then
        popup.selectedOption = popup.selectedOption - 1
        if popup.selectedOption < 1 then
            popup.selectedOption = popup.totalOptions
        end
        lastInputTime = 0
    elseif love.keyboard.isDown("right") and lastInputTime >= inputDebounceDelay then
        popup.selectedOption = popup.selectedOption + 1
        if popup.selectedOption > popup.totalOptions then
            popup.selectedOption = 1
        end
        lastInputTime = 0
    end
    
    if love.keyboard.isDown("return") or love.keyboard.isDown("space") then
        handlePopupSelection()
    end
    
    if love.keyboard.isDown("escape") then
        popup.selectedOption = 2
        handlePopupSelection()
    end
end

function handlePopupSelection()
    if popup.selectedOption == 1 then
        -- Yes - Handle based on popup mode
        if popup.mode == "themeInstallAll" then
            -- popup.active = false
            
            -- -- create loading popup
            -- popup.active = true
            -- popup.title = "Installing bootlogo to ALL themes"
            -- popup.message = "This may take a while, please wait..."
            -- popup.warning = ""
            -- popup.selectedOption = 1
            -- popup.totalOptions = 0
            processAllThemes("install")

        elseif popup.mode == "themeUninstallAll" then
            -- popup.active = false
            
            -- -- create loading popup
            -- popup.active = true
            -- popup.title = "Uninstalling bootlogo from ALL themes"
            -- popup.message = "This may take a while, please wait..."
            -- popup.warning = ""
            -- popup.selectedOption = 1
            -- popup.totalOptions = 0
            processAllThemes("uninstall")
        elseif popup.mode == "deleteBootlogo" then
            popup.active = false
            deleteCurrentBootlogo()
        else
            -- Default restart behavior
            msgLog = "Restarting system..."
            
            -- Execute the proper reboot command for this system
            local result = os.execute("/opt/muos/script/mux/quit.sh reboot frontend")
            if not result then
                popup.active = false
                msgLog = "Bootlogo installed. Restart command failed. Please restart manually."
            end
        end
    else
        -- No - Close popup
        popup.active = false
        if popup.mode == "themeInstallAll" or popup.mode == "themeUninstallAll" or popup.mode == "deleteBootlogo" then
            msgLog = "Operation cancelled."
        else
            msgLog = "Bootlogo changed. Restart when ready to apply changes."
        end
    end
end

function handleFileBrowserInput(dt)
    if not fileBrowser.active then return end
    
    lastInputTime = lastInputTime + dt
    
    -- Calculate visible items
    local height = Config.WINDOW_HEIGHT - 200
    local itemHeight = 25
    local maxItems = math.floor((height - 40) / itemHeight)
    
    if love.joystick.getJoysticks()[1] then
        local joystick = love.joystick.getJoysticks()[1]
        
        -- Navigation
        if joystick:isGamepadDown("dpup") and lastInputTime >= inputDebounceDelay then
            fileBrowser.selectedIndex = fileBrowser.selectedIndex - 1
            if fileBrowser.selectedIndex < 1 then
                fileBrowser.selectedIndex = #fileBrowser.files
                -- Reset scroll to end when wrapping from top to bottom
                fileBrowser.scrollOffset = math.max(0, #fileBrowser.files - maxItems)
            else
                -- Update scroll offset if selection is outside visible area
                if fileBrowser.selectedIndex <= fileBrowser.scrollOffset then
                    fileBrowser.scrollOffset = math.max(0, fileBrowser.selectedIndex - 1)
                end
            end
            
            lastInputTime = 0
        elseif joystick:isGamepadDown("dpdown") and lastInputTime >= inputDebounceDelay then
            fileBrowser.selectedIndex = fileBrowser.selectedIndex + 1
            if fileBrowser.selectedIndex > #fileBrowser.files then
                fileBrowser.selectedIndex = 1
                -- Reset scroll to beginning when wrapping from bottom to top
                fileBrowser.scrollOffset = 0
            else
                -- Update scroll offset if selection is outside visible area
                if fileBrowser.selectedIndex > fileBrowser.scrollOffset + maxItems then
                    fileBrowser.scrollOffset = fileBrowser.selectedIndex - maxItems
                end
            end
            
            lastInputTime = 0
        end
        
        -- A button to select
        if joystick:isGamepadDown("a") and lastInputTime >= inputDebounceDelay then
            selectFileBrowserItem()
            lastInputTime = 0
        end
        
        -- B button to go back
        if joystick:isGamepadDown("b") and lastInputTime >= inputDebounceDelay then
            fileBrowser.active = false
            msgLog = "Bootlogo Manager - Use D-pad to navigate, A to select"
            lastInputTime = 0
        end
    end
    
    -- Keyboard fallback
    if love.keyboard.isDown("up") and lastInputTime >= inputDebounceDelay then
        fileBrowser.selectedIndex = fileBrowser.selectedIndex - 1
        if fileBrowser.selectedIndex < 1 then
            fileBrowser.selectedIndex = #fileBrowser.files
            -- Reset scroll to end when wrapping from top to bottom
            fileBrowser.scrollOffset = math.max(0, #fileBrowser.files - maxItems)
        else
            -- Update scroll offset if selection is outside visible area
            if fileBrowser.selectedIndex <= fileBrowser.scrollOffset then
                fileBrowser.scrollOffset = math.max(0, fileBrowser.selectedIndex - 1)
            end
        end
        
        lastInputTime = 0
    elseif love.keyboard.isDown("down") and lastInputTime >= inputDebounceDelay then
        fileBrowser.selectedIndex = fileBrowser.selectedIndex + 1
        if fileBrowser.selectedIndex > #fileBrowser.files then
            fileBrowser.selectedIndex = 1
            -- Reset scroll to beginning when wrapping from bottom to top
            fileBrowser.scrollOffset = 0
        else
            -- Update scroll offset if selection is outside visible area
            if fileBrowser.selectedIndex > fileBrowser.scrollOffset + maxItems then
                fileBrowser.scrollOffset = fileBrowser.selectedIndex - maxItems
            end
        end
        
        lastInputTime = 0
    end
    
    if love.keyboard.isDown("return") or love.keyboard.isDown("space") then
        selectFileBrowserItem()
    end
    
    if love.keyboard.isDown("escape") then
        fileBrowser.active = false
        msgLog = "Bootlogo Manager - Use D-pad to navigate, A to select"
    end
end

function selectFileBrowserItem()
    if #fileBrowser.files == 0 then return end
    
    local selectedItem = fileBrowser.files[fileBrowser.selectedIndex]
    
    if selectedItem.type == "directory" then
        if selectedItem.name == ".." then
            fileBrowser.currentPath = selectedItem.path
        else
            fileBrowser.currentPath = selectedItem.path
        end
        fileBrowser.selectedIndex = 1
        fileBrowser.scrollOffset = 0
        loadDirectoryContents()
    else
        -- Selected a file
        if fileBrowser.mode == "themeInstall" then
            installBootlogoToTheme(selectedItem.path)
        elseif fileBrowser.mode == "themeUninstall" then
            uninstallBootlogoFromTheme(selectedItem.path)
        else
            installBootlogo(selectedItem.path)
        end
    end
end

function installBootlogo(filePath)
    msgLog = "Installing bootlogo: " .. filePath:match("([^/]+)$")

    local logoInstalled = false
    
    -- Check if /mnt/boot exists
    local bootExistsHandle = io.popen("test -d /mnt/boot && echo 'exists' || echo 'not_exists'")
    local bootExists = bootExistsHandle:read("*a"):gsub("%s+$", "")
    bootExistsHandle:close()
    
    if bootExists == "exists" then
        print("✓ /mnt/boot directory exists")
        
        -- Check if bootlogo.bmp exists in /mnt/boot
        local bootlogoExistsHandle = io.popen("test -f /mnt/boot/bootlogo.bmp && echo 'exists' || echo 'not_exists'")
        local bootlogoExists = bootlogoExistsHandle:read("*a"):gsub("%s+$", "")
        bootlogoExistsHandle:close()

        local originalExistsHandle = io.popen("test -f /mnt/boot/bootlogo.bmp.original && echo 'exists' || echo 'not_exists'")
        local originalExists = originalExistsHandle:read("*a"):gsub("%s+$", "")
        originalExistsHandle:close()
        
        if bootlogoExists == "exists" then
            print("✓ Found existing bootlogo.bmp")
            
            if originalExists == "not_exists" then
                print("Creating backup: bootlogo.bmp → bootlogo.bmp.original")
                -- Rename bootlogo.bmp to bootlogo.bmp.original
                local renameHandle = io.popen("mv /mnt/boot/bootlogo.bmp /mnt/boot/bootlogo.bmp.original 2>&1")
                local renameResult = renameHandle:read("*a")
                renameHandle:close()
                
                if renameResult == "" then
                    print("✓ Backup created successfully")
                    msgLog = "Backup created: bootlogo.bmp.original"
                else
                    print("✗ Backup failed: " .. renameResult)
                    msgLog = "Backup failed: " .. renameResult
                end

                -- Copy the new bootlogo.bmp to /mnt/boot
                print("Copying new bootlogo: " .. filePath .. " → /mnt/boot/bootlogo.bmp")
                local copyHandle = io.popen("cp '" .. filePath .. "' /mnt/boot/bootlogo.bmp 2>&1")
                local copyResult = copyHandle:read("*a")
                copyHandle:close()
                
                if copyResult == "" then
                    print("✓ New bootlogo copied successfully")
                    msgLog = "New bootlogo installed: " .. filePath:match("([^/]+)$")
                    logoInstalled = true
                else
                    print("✗ Copy failed: " .. copyResult)
                    msgLog = "Copy failed: " .. copyResult
                end
            else
                print("✓ Backup already exists: bootlogo.bmp.original")
                msgLog = "Backup already exists: bootlogo.bmp.original"

                -- Copy the new bootlogo.bmp to /mnt/boot
                print("Copying new bootlogo: " .. filePath .. " → /mnt/boot/bootlogo.bmp")
                local copyHandle = io.popen("cp '" .. filePath .. "' /mnt/boot/bootlogo.bmp 2>&1")
                local copyResult = copyHandle:read("*a")
                copyHandle:close()
                
                if copyResult == "" then
                    print("✓ New bootlogo copied successfully")
                    msgLog = "New bootlogo installed: " .. filePath:match("([^/]+)$")
                    logoInstalled = true
                else
                    print("✗ Copy failed: " .. copyResult)
                    msgLog = "Copy failed: " .. copyResult
                end
            end
        else
            print("No existing bootlogo.bmp found")
            msgLog = "No existing bootlogo to backup"
            
            -- Copy the new bootlogo.bmp to /mnt/boot
            print("Copying new bootlogo: " .. filePath .. " → /mnt/boot/bootlogo.bmp")
            local copyHandle = io.popen("cp '" .. filePath .. "' /mnt/boot/bootlogo.bmp 2>&1")
            local copyResult = copyHandle:read("*a")
            copyHandle:close()
            
            if copyResult == "" then
                print("✓ New bootlogo copied successfully")
                msgLog = "New bootlogo installed: " .. filePath:match("([^/]+)$")
                logoInstalled = true
            else
                print("✗ Copy failed: " .. copyResult)
                msgLog = "Copy failed: " .. copyResult
            end
        end
    else
        print("✗ /mnt/boot directory does not exist")
        msgLog = "Error: /mnt/boot directory not found"
    end
    
    fileBrowser.active = false

    if logoInstalled then
        -- Show restart popup
        popup.active = true
        popup.mode = "restartRequired"
        popup.title = "Restart Required"
        popup.message = "A clean restart is required to apply these changes, Restart now?"
        popup.warning = "A hard reset or power off right now will result in a blank bootlogo"
        popup.selectedOption = 1
    end
end

function uninstallBootlogo()
    msgLog = "Uninstalling bootlogo..."
    
    -- Check if /mnt/boot exists
    local bootExistsHandle = io.popen("test -d /mnt/boot && echo 'exists' || echo 'not_exists'")
    local bootExists = bootExistsHandle:read("*a"):gsub("%s+$", "")
    bootExistsHandle:close()

    if bootExists == "exists" then
        print("✓ /mnt/boot directory exists")
        
        -- Check if bootlogo.bmp exists in /mnt/boot
        local bootlogoExistsHandle = io.popen("test -f /mnt/boot/bootlogo.bmp && echo 'exists' || echo 'not_exists'")
        local bootlogoExists = bootlogoExistsHandle:read("*a"):gsub("%s+$", "")
        bootlogoExistsHandle:close()

        local originalExistsHandle = io.popen("test -f /mnt/boot/bootlogo.bmp.original && echo 'exists' || echo 'not_exists'")
        local originalExists = originalExistsHandle:read("*a"):gsub("%s+$", "")
        originalExistsHandle:close()

        if originalExists == "exists" then
            print("✓ Found bootlogo.bmp.original to restore")
            
            if bootlogoExists == "exists" then
                print("✓ Found bootlogo.bmp to delete")
                -- Delete the current bootlogo.bmp
                print("Deleting: /mnt/boot/bootlogo.bmp")
                local deleteHandle = io.popen("rm /mnt/boot/bootlogo.bmp 2>&1")
                local deleteResult = deleteHandle:read("*a")

                if deleteResult == "" then
                    print("✓ Custom bootlogo deleted successfully")
                    msgLog = "Custom bootlogo deleted successfully"
                else
                    print("✗ Delete failed: " .. deleteResult)
                    msgLog = "Delete failed: " .. deleteResult
                    return
                end
            end

            -- Restore the original bootlogo.bmp
            print("Restoring: /mnt/boot/bootlogo.bmp.original")
            local restoreHandle = io.popen("mv /mnt/boot/bootlogo.bmp.original /mnt/boot/bootlogo.bmp 2>&1")
            local restoreResult = restoreHandle:read("*a")
            restoreHandle:close()

            if restoreResult == "" then
                if bootlogoExists == "exists" then
                    print("✓ Original bootlogo restored successfully. Custom bootlogo removed.")
                    msgLog = "Original bootlogo restored successfully. Custom bootlogo removed."

                else
                    print("✓ Original bootlogo restored successfully. No custom bootlogo found.")
                    msgLog = "Original bootlogo restored successfully. No custom bootlogo found."
                end
                -- Show restart popup
                popup.active = true
                popup.mode = "restartRequired"
                popup.title = "Restart Required"
                popup.message = "A clean restart is required to apply these changes, Restart now?"
                popup.warning = "A hard reset or power off right now will result in a blank bootlogo"
                popup.selectedOption = 1
            else
                print("✗ Restore failed: " .. restoreResult)
                msgLog = "Restore failed: " .. restoreResult
            end

        else
            print("✗ No backup found to restore")
            msgLog = "No backup found to restore"
        end


    else
        print("✗ /mnt/boot directory does not exist")
        msgLog = "Error: /mnt/boot directory not found"
    end
end

function deleteCurrentBootlogo()
    msgLog = "Deleting current bootlogo..."
    
    -- Check if /mnt/boot exists
    local bootExistsHandle = io.popen("test -d /mnt/boot && echo 'exists' || echo 'not_exists'")
    local bootExists = bootExistsHandle:read("*a"):gsub("%s+$", "")
    bootExistsHandle:close()
    
    if bootExists == "exists" then
        print("✓ /mnt/boot directory exists")
        
        -- Check if bootlogo.bmp exists in /mnt/boot
        local bootlogoExistsHandle = io.popen("test -f /mnt/boot/bootlogo.bmp && echo 'exists' || echo 'not_exists'")
        local bootlogoExists = bootlogoExistsHandle:read("*a"):gsub("%s+$", "")
        bootlogoExistsHandle:close()
        
        if bootlogoExists == "exists" then
            print("✓ Found bootlogo.bmp to delete")
            
            -- Delete the current bootlogo.bmp
            print("Deleting: /mnt/boot/bootlogo.bmp")
            local deleteHandle = io.popen("rm /mnt/boot/bootlogo.bmp 2>&1")
            local deleteResult = deleteHandle:read("*a")
            deleteHandle:close()
            
            if deleteResult == "" then
                print("✓ Bootlogo deleted successfully")
                msgLog = "Current bootlogo deleted successfully"
            else
                print("✗ Delete failed: " .. deleteResult)
                msgLog = "Delete failed: " .. deleteResult
            end
        else
            print("No bootlogo.bmp found to delete")
            msgLog = "No bootlogo found to delete"
        end
    else
        print("✗ /mnt/boot directory does not exist")
        msgLog = "Error: /mnt/boot directory not found"
    end
end

function installBootlogoToTheme(themePath, silent)
    if not silent then
        msgLog = "Installing bootlogo to theme: " .. themePath:match("([^/]+)$")
    end
    
    -- Create temporary directory for extraction
    local tempDir = "/tmp/theme_extract_" .. os.time() .. "_" .. math.random(1000, 9999)
    local counter = 1
    local originalTempDir = tempDir
    
    -- Check if directory exists and append number until we find a unique name
    -- YES I KNOW THIS IS OVERKILL, IT MAKES ME FEEL BETTER
    while true do
        local existsHandle = io.popen("test -d '" .. tempDir .. "' && echo 'exists' || echo 'not_exists'")
        local exists = existsHandle:read("*a"):gsub("%s+$", "")
        existsHandle:close()
        
        if exists == "not_exists" then
            break -- Directory doesn't exist, we can use this name
        else
            tempDir = originalTempDir .. "_" .. counter
            counter = counter + 1
        end
    end
    
    local extractCmd = "mkdir -p " .. tempDir .. " && cd " .. tempDir .. " && unzip -q '" .. themePath .. "'"
    
    if not silent then
        print("Extracting theme file...")
    end
    local extractResult = os.execute(extractCmd)
    
    if not extractResult then
        if not silent then
            msgLog = "Failed to extract theme file"
            fileBrowser.active = false
        end
        os.execute("rm -rf " .. tempDir)
        return false
    end
    
    if not silent then
        print("✓ Theme extracted successfully")
    end
    
    -- Search for bootlogo files in the extracted theme
    local bootlogoPath = nil
    local bootlogoOriginalPath = nil
    
    -- Search for bootlogo.bmp and bootlogo.bmp.original recursively
    local findCmd = "find " .. tempDir .. " -name 'bootlogo.bmp' -o -name 'bootlogo.bmp.original'"
    local findHandle = io.popen(findCmd)
    if findHandle then
        local findResult = findHandle:read("*a")
        findHandle:close()
        
        for line in findResult:gmatch("[^\r\n]+") do
            if line:match("bootlogo%.bmp$") then
                bootlogoPath = line
                if not silent then
                    print("Found bootlogo.bmp: " .. line)
                end
            elseif line:match("bootlogo%.bmp%.original$") then
                bootlogoOriginalPath = line
                if not silent then
                    print("Found bootlogo.bmp.original: " .. line)
                end
            end
        end
    end
    
    if not bootlogoPath then
        if not silent then
            msgLog = "No bootlogo.bmp found in theme"
            fileBrowser.active = false
        end
        os.execute("rm -rf " .. tempDir)
        return false
    end
    
    -- Check if we have a current bootlogo to install
    local currentBootlogoExists = io.popen("test -f /mnt/boot/bootlogo.bmp && echo 'exists' || echo 'not_exists'")
    local currentBootlogoResult = currentBootlogoExists:read("*a"):gsub("%s+$", "")
    currentBootlogoExists:close()
    
    if currentBootlogoResult == "not_exists" then
        if not silent then
            msgLog = "No current bootlogo to install to theme"
            fileBrowser.active = false
        end
        os.execute("rm -rf " .. tempDir)
        return false
    end
    
    -- Backup original bootlogo in theme if it exists
    if bootlogoOriginalPath then
        if not silent then
            print("Original bootlogo already exists in theme")
        end
    else
        -- Create backup of current theme bootlogo
        local backupCmd = "cp '" .. bootlogoPath .. "' '" .. bootlogoPath .. ".original'"
        local backupResult = os.execute(backupCmd)
        if backupResult and not silent then
            print("✓ Created backup of theme bootlogo")
        elseif not backupResult and not silent then
            print("✗ Failed to create backup")
        end
    end
    
    -- Copy current bootlogo to theme
    local copyCmd = "cp /mnt/boot/bootlogo.bmp '" .. bootlogoPath .. "'"
    local copyResult = os.execute(copyCmd)
    
    if not copyResult then
        if not silent then
            msgLog = "Failed to copy bootlogo to theme"
            fileBrowser.active = false
        end
        os.execute("rm -rf " .. tempDir)
        return false
    end
    
    if not silent then
        print("✓ Bootlogo copied to theme")
    end
    
    -- Repack the theme file
    local themeDir = tempDir
    local themeName = themePath:match("([^/]+)%.muxthm$")
    local repackCmd = "cd " .. themeDir .. " && zip -r -q '" .. themePath .. ".new' ."
    
    if not silent then
        print("Repacking theme file...")
    end
    local repackResult = os.execute(repackCmd)
    
    if not repackResult then
        if not silent then
            msgLog = "Failed to repack theme file"
        end
        os.execute("rm -rf " .. tempDir)
        os.execute("rm -f '" .. themePath .. ".new'")
        if not silent then
            fileBrowser.active = false
        end
        return false
    end
    
    -- Replace original theme file with new one
    local replaceCmd = "mv '" .. themePath .. ".new' '" .. themePath .. "'"
    local replaceResult = os.execute(replaceCmd)
    
    if not replaceResult then
        if not silent then
            msgLog = "Failed to replace theme file"
        end
        -- Clean up both temp directory and the .new file
        os.execute("rm -rf " .. tempDir)
        os.execute("rm -f '" .. themePath .. ".new'")
        if not silent then
            fileBrowser.active = false
        end
        return false
    end
    
    -- Clean up temporary directory
    os.execute("rm -rf " .. tempDir)
    
    if not silent then
        print("✓ Theme updated successfully")
        if bootlogoOriginalPath then
            msgLog = "Bootlogo installed to theme: " .. themePath:match("([^/]+)$") .. " (Backup was already present)"
        else
            msgLog = "Bootlogo installed to theme: " .. themePath:match("([^/]+)$") .. " (Backup was created)"
        end
        fileBrowser.active = false
    end
    
    return true
end

function uninstallBootlogoFromTheme(themePath, silent)
    if not silent then
        msgLog = "Uninstalling bootlogo from theme: " .. themePath:match("([^/]+)$")
    end
    
    -- Create temporary directory for extraction
    local tempDir = "/tmp/theme_extract_" .. os.time() .. "_" .. math.random(1000, 9999)
    local counter = 1
    local originalTempDir = tempDir
    
    -- Check if directory exists and append number until we find a unique name
    -- YES I KNOW THIS IS OVERKILL, IT MAKES ME FEEL BETTER
    while true do
        local existsHandle = io.popen("test -d '" .. tempDir .. "' && echo 'exists' || echo 'not_exists'")
        local exists = existsHandle:read("*a"):gsub("%s+$", "")
        existsHandle:close()
        
        if exists == "not_exists" then
            break -- Directory doesn't exist, we can use this name
        else
            tempDir = originalTempDir .. "_" .. counter
            counter = counter + 1
        end
    end
    
    local extractCmd = "mkdir -p " .. tempDir .. " && cd " .. tempDir .. " && unzip -q '" .. themePath .. "'"
    
    if not silent then
        print("Extracting theme file...")
    end
    local extractResult = os.execute(extractCmd)
    
    if not extractResult then
        if not silent then
            msgLog = "Failed to extract theme file"
            fileBrowser.active = false
        end
        os.execute("rm -rf " .. tempDir)
        return false
    end
    
    if not silent then
        print("✓ Theme extracted successfully")
    end
    
    -- Search for bootlogo files in the extracted theme
    local bootlogoPath = nil
    local bootlogoOriginalPath = nil
    
    -- Search for bootlogo.bmp and bootlogo.bmp.original recursively
    local findCmd = "find " .. tempDir .. " -name 'bootlogo.bmp' -o -name 'bootlogo.bmp.original'"
    local findHandle = io.popen(findCmd)
    if findHandle then
        local findResult = findHandle:read("*a")
        findHandle:close()
        
        for line in findResult:gmatch("[^\r\n]+") do
            if line:match("bootlogo%.bmp$") then
                bootlogoPath = line
                if not silent then
                    print("Found bootlogo.bmp: " .. line)
                end
            elseif line:match("bootlogo%.bmp%.original$") then
                bootlogoOriginalPath = line
                if not silent then
                    print("Found bootlogo.bmp.original: " .. line)
                end
            end
        end
    end
    
    if not bootlogoPath then
        if not silent then
            msgLog = "No bootlogo.bmp found in theme"
            fileBrowser.active = false
        end
        os.execute("rm -rf " .. tempDir)
        return false
    end
    
    if not bootlogoOriginalPath then
        if not silent then
            msgLog = "No bootlogo.bmp.original found in theme to restore"
            fileBrowser.active = false
        end
        os.execute("rm -rf " .. tempDir)
        return false
    end
    
    -- Restore original bootlogo from backup
    local restoreCmd = "cp '" .. bootlogoOriginalPath .. "' '" .. bootlogoPath .. "'"
    local restoreResult = os.execute(restoreCmd)
    
    if not restoreResult then
        if not silent then
            msgLog = "Failed to restore original bootlogo"
            fileBrowser.active = false
        end
        os.execute("rm -rf " .. tempDir)
        return false
    end
    
    if not silent then
        print("✓ Original bootlogo restored")
    end
    
    -- Remove the backup file since we've restored it
    local removeBackupCmd = "rm '" .. bootlogoOriginalPath .. "'"
    local removeBackupResult = os.execute(removeBackupCmd)
    
    if removeBackupResult and not silent then
        print("✓ Removed backup file")
    elseif not removeBackupResult and not silent then
        print("✗ Failed to remove backup file")
    end
    
    -- Repack the theme file
    local themeDir = tempDir
    local themeName = themePath:match("([^/]+)%.muxthm$")
    local repackCmd = "cd " .. themeDir .. " && zip -r -q '" .. themePath .. ".new' ."
    
    if not silent then
        print("Repacking theme file...")
    end
    local repackResult = os.execute(repackCmd)
    
    if not repackResult then
        if not silent then
            msgLog = "Failed to repack theme file"
        end
        os.execute("rm -rf " .. tempDir)
        os.execute("rm -f '" .. themePath .. ".new'")
        if not silent then
            fileBrowser.active = false
        end
        return false
    end
    
    -- Replace original theme file with new one
    local replaceCmd = "mv '" .. themePath .. ".new' '" .. themePath .. "'"
    local replaceResult = os.execute(replaceCmd)
    
    if not replaceResult then
        if not silent then
            msgLog = "Failed to replace theme file"
        end
        -- Clean up both temp directory and the .new file
        os.execute("rm -rf " .. tempDir)
        os.execute("rm -f '" .. themePath .. ".new'")
        if not silent then
            fileBrowser.active = false
        end
        return false
    end
    
    -- Clean up temporary directory
    os.execute("rm -rf " .. tempDir)
    
    if not silent then
        print("✓ Theme updated successfully")
        msgLog = "Original bootlogo restored in theme: " .. themePath:match("([^/]+)$")
        fileBrowser.active = false
    end
    
    return true
end

function installBootlogoToAllThemes()
    -- Show confirmation popup
    popup.active = true
    popup.title = "Install to All Themes"
    popup.message = "This will install current bootlogo to ALL installed themes. Continue?"
    --popup.warning = "This action can be undone by uninstalling the bootlogo from all themes."
    popup.warning = "This action may take a while to complete. Please be patient."
    popup.selectedOption = 2 -- Default to "No" for safety
    popup.mode = "themeInstallAll" -- Custom mode for this popup
end

function uninstallBootlogoFromAllThemes()
    -- Show confirmation popup
    popup.active = true
    popup.title = "Uninstall from All Themes"
    popup.message = "This will restore original bootlogos in ALL installed themes. Continue?"
    --popup.warning = "This action cannot be undone easily."
    popup.warning = "This action may take a while to complete. Please be patient."
    popup.selectedOption = 2 -- Default to "No" for safety
    popup.mode = "themeUninstallAll" -- Custom mode for this popup
end

function processAllThemes(operation)
    --popup.active = false
    msgLog = "Processing all themes..."
    
    local themeDir = "/mnt/mmc/MUOS/theme"
    local successCount = 0
    local errorCount = 0
    local totalThemes = 0
    
    -- Check if theme directory exists
    local themeExistsHandle = io.popen("test -d " .. themeDir .. " && echo 'exists' || echo 'not_exists'")
    local themeExists = themeExistsHandle:read("*a"):gsub("%s+$", "")
    themeExistsHandle:close()
    
    if themeExists == "not_exists" then
        msgLog = "Theme directory not found: " .. themeDir
        return
    end
    
    -- Find all .muxthm files in the theme directory
    local findCmd = "find " .. themeDir .. " -maxdepth 1 -name '*.muxthm'"
    local findHandle = io.popen(findCmd)
    if findHandle then
        local findResult = findHandle:read("*a")
        findHandle:close()
        
        local themes = {}
        for line in findResult:gmatch("[^\r\n]+") do
            table.insert(themes, line)
            totalThemes = totalThemes + 1
        end
        
        if totalThemes == 0 then
            msgLog = "No .muxthm files found in theme directory"
            return
        end
        
        print("Found " .. totalThemes .. " themes to process")
        
        -- Process each theme
        for i, themePath in ipairs(themes) do
            local themeName = themePath:match("([^/]+)%.muxthm$")
            print("Processing theme " .. i .. "/" .. totalThemes .. ": " .. themeName)
            
            if operation == "install" then
                -- Call installBootlogoToTheme function in silent mode
                local success = installBootlogoToTheme(themePath, true)
                if success then
                    successCount = successCount + 1
                else
                    errorCount = errorCount + 1
                end
            elseif operation == "uninstall" then
                -- Call uninstallBootlogoFromTheme function in silent mode
                local success = uninstallBootlogoFromTheme(themePath, true)
                if success then
                    successCount = successCount + 1
                else
                    errorCount = errorCount + 1
                end
            end
        end
        
        -- Show final results
        if operation == "install" then
            msgLog = "Install complete: " .. successCount .. " successful, " .. errorCount .. " failed"
        else
            msgLog = "Uninstall complete: " .. successCount .. " successful, " .. errorCount .. " failed"
        end
    else
        msgLog = "Failed to scan theme directory"
    end

    popup.active = false
end

 