-- Shahmir Khan August 11 2025
-- Bootlogo Manager v1.0.2 Main File
-- https://github.com/shahmir-k
-- https://linkedin.com/in/shahmir-k

local version = "1.0.2"

defaultWidth, defaultHeight = 640, 480 -- default to 640x480 before full initialization

function love.conf(t)
    t.window.title = "Bootlogo Manager"
    t.window.width = defaultWidth -- default to 640 before full initialization
    t.window.height = defaultHeight -- default to 480 before full initialization
    t.window.resizable = false
    t.window.fullscreen = false
    t.window.vsync = true
    
    t.modules.joystick = true
    t.modules.audio = false
    t.modules.keyboard = true
    t.modules.event = true
    t.modules.image = true
    t.modules.graphics = true
    t.modules.timer = true
    t.modules.mouse = false
    t.modules.sound = false
    t.modules.physics = false
    t.modules.filesystem = true
end 
local love = require("love")

local filebrowser = require("filebrowser") -- File browser UI module
local popup = require("popup") -- Popup UImodule
local bootlogo = require("bootlogoFunctions") -- Bootlogo functions module
local magick = require("imagemagick") -- ImageMagick module (for image processing/conversion)
local fileUtils = require("fileUtils")

local Config = {
    -- Paths
    BOOTLOGO_PATH = "/mnt/boot", -- Path to the bootlogo file
    BOOTLOGO_FILENAME = "bootlogo.bmp", -- Name of the bootlogo file
    THEME_PATH = "/mnt/mmc/MUOS/theme", -- Path to the theme directory
    THEME_EXTENSION = ".muxthm", -- Extension of the theme files
    DOWNLOAD_DIR = "/mnt/mmc/ARCHIVE", -- Path to the download directory
    WORKING_DIR = os.getenv("PWD") or "/", 

    -- ImageMagick Configuration
    MAGICK_AVAILABLE = magick.is_available(), -- check if ImageMagick > version 7.0.0 is available

    -- UI Configuration
    WINDOW_WIDTH = defaultWidth, -- default to 640 before full initialization
    WINDOW_HEIGHT = defaultHeight, -- default to 480 before full initialization
    BUTTON_WIDTH = 400,
    BUTTON_HEIGHT = 32,
    BUTTON_MARGIN = 15,
    PREVIEW_WIDTH = 170,
    PREVIEW_HEIGHT = 160,

    -- Colors
    COLORS = {
        BACKGROUND = {0.078, 0.106, 0.173},
        HEADER_BG = {0.141, 0.141, 0.141},
        BUTTON_BG = {0.2, 0.2, 0.2},
        BUTTON_HOVER = {0, 0, 0},
        BUTTON_TEXT = {1, 1, 1},
        TEXT = {1, 1, 1},
        TEXT_SECONDARY = {0.8, 0.8, 0.8},
        DELETE_BUTTON_BG = {0, 0, 0},
        DELETE_BUTTON_HOVER = {0.6, 0.1, 0.1}
    },

    -- Button positions (will be calculated after window size is set)
    BUTTONS = {}
}
-- BUTTONS ------------------------------------------------------------
    -- Button states
local buttons = {
    {text = "Install Custom Bootlogo", action = "install"},
    {text = "Uninstall Custom Bootlogo", action = "uninstall"},
    {text = "Install Bootlogo to Theme", action = "install_theme"},
    {text = "Uninstall Bootlogo from Theme", action = "uninstall_theme"},
    {text = "Install Bootlogo to All Themes", action = "install_all_themes"},
    {text = "Uninstall Bootlogo from All Themes", action = "uninstall_all_themes"},
    {text = "> Delete Current Bootlogo <", action = "delete"}
}
    -- Button variables
local totalButtons = 7 -- total number of buttons, used for navigation to tell when the user has reached the last button
local selectedButton = 1 -- the button that is currently selected
    -- Button input debounce variables
local lastInputTime = 0 -- the time since the last input was made
local inputDebounceDelay = 0.2 -- 0.2 seconds
-- END BUTTONS ------------------------------------------------------------


-- Global variables
local fontBig, fontSmall, fontBold
local msgLog = ""

-- Current bootlogo preview state
local currentBootlogoPreview = {
    image = nil,
    errorMessage = nil,
    x = 0,
    y = 0
}

-- Update check variables
local updateCheckTimer = 0
local updateCheckInterval = 0.5 -- 0.5 second
local updateChecked = false


function isConnectedToInternet()
    -- Check if interface is actually connected (not just UP)
    local handle = io.popen('cat /sys/class/net/wlan0/operstate 2>/dev/null')
    if handle then
        local result = handle:read("*line")
        handle:close()
        return result == "up"
    end
    return false
end

function checkForUpdates()
    if not isConnectedToInternet() then
        print("DEBUG: No internet connection, skipping update check")
        popup.hide()
        return false
    end



    -- Check for updates by comparing local version with GitHub releases
    local currentVersion = version -- This is defined at the top of the file
    
    -- Get the latest release info from GitHub API with timeout
    local handle = io.popen('timeout 5 curl -s --connect-timeout 2 --max-time 5 "https://api.github.com/repos/shahmir-k/Bootlogo-Manager-muOS/releases/latest" 2>/dev/null')
    if not handle then
        print("DEBUG: Failed to start update check process")
        popup.hide()
        return false
    end
    
    local response = handle:read("*all")
    handle:close()
    
    if not response or response == "" then
        print("DEBUG: No response from GitHub API (likely no internet or timeout)")
        popup.hide()
        return false
    end
    
    -- Extract version from GitHub response (simplified JSON parsing)
    local latestVersion = response:match('"tag_name"%s*:%s*"([^"]+)"')
    if not latestVersion then
        print("DEBUG: Failed to parse version from GitHub response")
        popup.hide()
        return false
    end
    
    -- Remove 'v' prefix if present for comparison
    latestVersion = latestVersion:gsub("^v", "")
    currentVersion = currentVersion:gsub("^v", "")
    
    print("DEBUG: Current version: " .. currentVersion .. ", Latest version: " .. latestVersion)
    
    -- Compare versions
    if latestVersion ~= currentVersion then
        -- Show update popup
        popup.show(
            "Update Available", -- title
            "A new version of Bootlogo Manager is available!", -- message1
            "Current: v" .. currentVersion .. " | Latest: v" .. latestVersion, -- message2
            "Would you like to download the update?", -- warning
            "updateAvailable", -- mode
            {"Yes", "No"}, -- optionText
            "yes" -- defaultOption
        )
        return true
    end
    
    popup.hide()
    return false
end

function downloadLatestVersion()
    msgLog = "Downloading latest release..."
            
    -- Get the latest release download URL (try .muxupd first, then .muxzip)
    local handle = io.popen('timeout 5 curl -s --connect-timeout 2 --max-time 5 "https://api.github.com/repos/shahmir-k/Bootlogo-Manager-muOS/releases/latest" 2>/dev/null | grep -o "https://.*\\.muxupd" | head -1')
    if not handle then
        msgLog = "Failed to get download URL"
        return
    end
    
    local downloadUrl = handle:read("*line")
    handle:close()
    
    -- If no .muxupd file found, try .muxzip
    if not downloadUrl or downloadUrl == "" then
        handle = io.popen('timeout 5 curl -s --connect-timeout 2 --max-time 5 "https://api.github.com/repos/shahmir-k/Bootlogo-Manager-muOS/releases/latest" 2>/dev/null | grep -o "https://.*\\.muxzip" | head -1')
        if handle then
            downloadUrl = handle:read("*line")
            handle:close()
        end
    end
    
    if not downloadUrl or downloadUrl == "" then
        msgLog = "Failed to get download URL"
        return
    end
    
    -- Extract filename from URL (handle both .muxupd and .muxzip)
    local filename = downloadUrl:match("([^/]+%.muxupd)$") or downloadUrl:match("([^/]+%.muxzip)$")
    if not filename then
        msgLog = "Failed to extract filename"
        return
    end
    
    -- Download the file to ARCHIVE directory with timeout
    local downloadCmd = string.format('timeout 30 curl -L --connect-timeout 5 --max-time 30 -o "%s/%s" "%s" 2>/dev/null', Config.DOWNLOAD_DIR, filename, downloadUrl)
    local result = os.execute(downloadCmd)
    
    if result then
        msgLog = "Download completed: " .. filename
        -- Show success popup
        popup.show(
            "Download Completed", -- title
            "The latest version has been downloaded to " .. Config.DOWNLOAD_DIR .. ".", -- message1
            "You can now install it from the Archive Manager.", -- message2
            "File: " .. filename, -- warning
            "success", -- mode
            {"OK"}, -- optionText
            "ok" -- defaultOption
        )
    else
        msgLog = "Download failed"
        -- Show error popup
        popup.show(
            "Download Failed", -- title
            "Failed to download the latest version.", -- message1
            "Please check your internet connection and try again.", -- message2
            "You can manually download from GitHub.", -- warning
            "error", -- mode
            {"OK"}, -- optionText
            "ok" -- defaultOption
        )
    end
end



-- Function to load and update the current bootlogo preview
function loadCurrentBootlogoPreview()
    -- Clear existing preview
    if currentBootlogoPreview.image then
        currentBootlogoPreview.image:release()
        currentBootlogoPreview.image = nil
    end
    
    -- Check if current bootlogo exists
    local bootlogoPath = Config.BOOTLOGO_PATH .. "/" .. Config.BOOTLOGO_FILENAME
    if fileUtils.fileExists(bootlogoPath) then
        print("DEBUG: Current bootlogo exists, creating preview")
        
        -- Generate preview canvas using the same pattern as loadImagePreview
        if Config.MAGICK_AVAILABLE then
            local preview = magick.generatePreviewCanvas(bootlogoPath, Config.PREVIEW_WIDTH, Config.PREVIEW_HEIGHT)
            if preview then
                print("DEBUG: Successfully generated current bootlogo preview canvas")
                currentBootlogoPreview.image = preview
            else
                print("DEBUG: Failed to generate current bootlogo preview canvas")
                currentBootlogoPreview.errorMessage = "Failed to load bootlogo"
            end
        else
            print("DEBUG: ImageMagick is not available, using default preview")
            currentBootlogoPreview.errorMessage = "ImageMagick not available"
        end
    else
        print("DEBUG: No current bootlogo found")
        currentBootlogoPreview.errorMessage = "No bootlogo found"
    end
    
    -- Calculate preview position (bottom right corner)
    currentBootlogoPreview.x = Config.WINDOW_WIDTH - Config.PREVIEW_WIDTH - 30
    currentBootlogoPreview.y = Config.WINDOW_HEIGHT - Config.PREVIEW_HEIGHT - 180
end



function love.load()

    -- CONFIG SETUP ------------------------------------------------------------
    -- Set Screen Size
    local detectedWidth, detectedHeight = love.window.getDesktopDimensions()
    if detectedWidth and detectedHeight and detectedWidth > 0 and detectedHeight > 0 then
        print("Detected screen size: " .. detectedWidth .. "x" .. detectedHeight)
        Config.WINDOW_WIDTH = detectedWidth
        Config.WINDOW_HEIGHT = detectedHeight
        love.window.setMode(Config.WINDOW_WIDTH, Config.WINDOW_HEIGHT)
    else
        print("Failed to detect screen size, using default 640x480")
    end
    
    -- Calculate button positions based on window size
    Config.BUTTONS = {
        INSTALL = {
            x = (Config.WINDOW_WIDTH - Config.BUTTON_WIDTH) / 15,
            y = 60,
            width = Config.BUTTON_WIDTH,
            height = Config.BUTTON_HEIGHT,
            text = "Install Custom Bootlogo"
        },
        UNINSTALL = {
            x = (Config.WINDOW_WIDTH - Config.BUTTON_WIDTH) / 15,
            y = 60 + Config.BUTTON_HEIGHT + Config.BUTTON_MARGIN,
            width = Config.BUTTON_WIDTH,
            height = Config.BUTTON_HEIGHT,
            text = "Uninstall Custom Bootlogo"
        },
        INSTALL_THEME = {
            x = (Config.WINDOW_WIDTH - Config.BUTTON_WIDTH) / 15,
            y = 60 + (Config.BUTTON_HEIGHT + Config.BUTTON_MARGIN) * 2,
            width = Config.BUTTON_WIDTH,
            height = Config.BUTTON_HEIGHT,
            text = "Install Bootlogo to a Single Theme"
        },
        UNINSTALL_THEME = {
            x = (Config.WINDOW_WIDTH - Config.BUTTON_WIDTH) / 15,
            y = 60 + (Config.BUTTON_HEIGHT + Config.BUTTON_MARGIN) * 3,
            width = Config.BUTTON_WIDTH,
            height = Config.BUTTON_HEIGHT,
            text = "Uninstall Bootlogo from a Single Theme"
        },
        INSTALL_ALL_THEMES = {
            x = (Config.WINDOW_WIDTH - Config.BUTTON_WIDTH) / 15,
            y = 60 + (Config.BUTTON_HEIGHT + Config.BUTTON_MARGIN) * 4,
            width = Config.BUTTON_WIDTH,
            height = Config.BUTTON_HEIGHT,
            text = "Install Bootlogo to All Themes"
        },
        UNINSTALL_ALL_THEMES = {
            x = (Config.WINDOW_WIDTH - Config.BUTTON_WIDTH) / 15,
            y = 60 + (Config.BUTTON_HEIGHT + Config.BUTTON_MARGIN) * 5,
            width = Config.BUTTON_WIDTH,
            height = Config.BUTTON_HEIGHT,
            text = "Uninstall Bootlogo from All Themes"
        },
        DELETE = {
            x = (Config.WINDOW_WIDTH - Config.BUTTON_WIDTH) / 15,
            y = 60 + (Config.BUTTON_HEIGHT + Config.BUTTON_MARGIN) * 6,
            width = Config.BUTTON_WIDTH,
            height = Config.BUTTON_HEIGHT,
            text = "Delete Current Bootlogo"
        }
    }

    -- END CONFIG SETUP ------------------------------------------------------------



    -- LOVE SETUP ------------------------------------------------------------
    -- Load fonts
    fontBig = love.graphics.newFont(16)
    fontSmall = love.graphics.newFont(12)
    fontBold = love.graphics.newFont(16)
    
    -- Set default font
    love.graphics.setFont(fontBig)
    
    -- Initialize message log
    msgLog = ""
    -- END LOVE SETUP ------------------------------------------------------------



    -- GLOBAL VARIABLES AND MODULES SETUP ------------------------------------------------------------
    
    -- Set the config
    bootlogo.setConfig(Config)
    filebrowser.setConfig(Config)
    popup.setConfig(Config)
    -- Set up module callbacks
        -- set message log functions
    filebrowser.setMessageLogFunction(function(message) msgLog = message end)
    bootlogo.setMessageLogFunction(function(message) msgLog = message end)
    
    -- Set up preview update callback
    bootlogo.setPreviewUpdateFunction(loadCurrentBootlogoPreview)
    
    -- Set up popup system (for direct popup access)
    bootlogo.setPopupSystem(popup)
    
    -- Load initial current bootlogo preview
    loadCurrentBootlogoPreview()
        -- set selection handlers
    popup.setSelectionHandler(function(selectedOption, mode) handlePopupSelection(selectedOption, mode) end)
    filebrowser.setSelectionHandler(function(selectedItem) handleFileBrowserSelection(selectedItem) end)
    
    -- END GLOBAL VARIABLES AND MODULES SETUP ------------------------------------------------------------

    if not isConnectedToInternet() then
        print("DEBUG: No internet connection, skipping update check")
        updateChecked = true
    else
        popup.show(
            "Checking for Updates", -- title
            "Checking for updates on GitHub...", -- message1
            "Timeout in 5 seconds", -- message2
            "", -- warning
            "updateCheck", -- mode
            {}, -- optionText
            "yes" -- defaultOption
        )
    end

    
end

function love.update(dt)
    -- Handle input
    if popup.state.active then
        lastInputTime = popup.handleInput(dt, lastInputTime, inputDebounceDelay)
    elseif filebrowser.state.active then
        lastInputTime = filebrowser.handleInput(dt, lastInputTime, inputDebounceDelay)
    else
        handleInput(dt)
    end
    
    -- Check for updates after 2 seconds (non-blocking)
    if not updateChecked then
        updateCheckTimer = updateCheckTimer + dt
        if updateCheckTimer >= updateCheckInterval then
            updateChecked = true
            checkForUpdates()
        end
    end
end

function love.draw()
    -- Draw background
    love.graphics.setColor(unpack(Config.COLORS.BACKGROUND))
    love.graphics.rectangle("fill", 0, 0, Config.WINDOW_WIDTH, Config.WINDOW_HEIGHT)
    
    -- Draw header
    drawHeader()
    
    if popup.state.active then
        popup.draw(fontBig, fontSmall)
    elseif filebrowser.state.active then
        filebrowser.draw(fontSmall, fontBig)
    else
        -- Draw buttons
        drawButtons()
    end
    
    -- Draw footer
    drawFooter()
end




-- Function to get battery percentage directly
function getBatteryPercentage()
    -- Common battery capacity file paths based on muOS source code
    local paths = {
        "/sys/class/power_supply/axp2202-battery/capacity",  -- RG devices
        "/sys/class/power_supply/battery/capacity",          -- Generic
        "/proc/acpi/battery/BAT0/state"                      -- ACPI
    }
    
    for _, path in ipairs(paths) do
        local file = io.open(path, "r")
        if file then
            local percentage = file:read("*line")
            file:close()
            if percentage and percentage:match("^%d+$") then
                return tonumber(percentage)
            end
        end
    end
    
    return nil
end

-- Function to get charging state directly
function getChargingState()
    -- Common charger file paths based on muOS source code
    local paths = {
        "/sys/class/power_supply/axp2202-battery/online",    -- RG devices
        "/sys/class/power_supply/battery/online",            -- Generic
        "/sys/class/power_supply/axp2202-battery/status"     -- Alternative
    }
    
    for _, path in ipairs(paths) do
        local file = io.open(path, "r")
        if file then
            local charging = file:read("*line")
            file:close()
            if charging then
                charging = charging:gsub("%s+", "") -- Remove whitespace
                -- Check for various charging indicators
                if charging == "1" or charging == "Charging" or charging == "Full" then
                    return true
                elseif charging == "0" or charging == "Discharging" then
                    return false
                end
            end
        end
    end
    
    return nil
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
    love.graphics.print("Bootlogo Manager v1.0.2", xPos + 20, yPos + 12)
    
    -- Get battery percentage and charging state
    local batteryPercent = getBatteryPercentage()
    local chargingState = getChargingState()
    local batteryText = ""
    
    if batteryPercent then
        batteryText = batteryPercent .. "%"
        -- Add charging indicator if charging
        if chargingState then
            batteryText = batteryText .. " Charging"
        end
    else
        batteryText = "Unknown Battery %"
    end
    
    -- Time and Battery (positioned on the right)
    local now = os.date('*t')
    local formatted_time = string.format("%02d:%02d", tonumber(now.hour), tonumber(now.min))
    
    -- Calculate positions to avoid collision
    local timeText = formatted_time .. " | "
    local batteryText = batteryPercent .. "%"
    
    -- Get text widths for proper spacing
    local timeWidth = fontBold:getWidth(timeText)
    local batteryWidth = fontBold:getWidth(batteryText)
    
    -- Position time on the right, battery to the left of time
    local timeXposition = Config.WINDOW_WIDTH - timeWidth - batteryWidth - 20
    local batteryXposition = Config.WINDOW_WIDTH - batteryWidth - 20
    
    -- Draw time
    love.graphics.print(timeText, timeXposition, yPos + 12)
    
    -- Draw battery percentage in green if charging, white if not
    if chargingState then
        love.graphics.setColor(0, 1, 0, 1) -- Green color
    end
    love.graphics.print(batteryText, batteryXposition, yPos + 12)
    love.graphics.setColor(unpack(Config.COLORS.TEXT)) -- Reset to normal text color
    
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
    
    -- Draw current bootlogo preview
    if currentBootlogoPreview.image or currentBootlogoPreview.errorMessage then
        -- Draw preview background
        love.graphics.setColor(unpack(Config.COLORS.BUTTON_BG))
        love.graphics.rectangle("fill", currentBootlogoPreview.x - 5, currentBootlogoPreview.y - 5, 
                               Config.PREVIEW_WIDTH + 10, Config.PREVIEW_HEIGHT + 10, 4, 4)
        
        -- Draw preview border
        love.graphics.setColor(unpack(Config.COLORS.TEXT))
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", currentBootlogoPreview.x - 5, currentBootlogoPreview.y - 5, 
                               Config.PREVIEW_WIDTH + 10, Config.PREVIEW_HEIGHT + 10, 4, 4)
        
        if currentBootlogoPreview.image then
            -- Draw the preview image
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(currentBootlogoPreview.image, currentBootlogoPreview.x, currentBootlogoPreview.y)
            
            -- Draw preview label
            love.graphics.setColor(unpack(Config.COLORS.TEXT))
            love.graphics.setFont(fontSmall)
            love.graphics.print("Current Bootlogo", currentBootlogoPreview.x - -30, currentBootlogoPreview.y - 30)
        else
            -- Draw error message as placeholder text
            love.graphics.setColor(unpack(Config.COLORS.TEXT_SECONDARY))
            love.graphics.setFont(fontSmall)
            local textWidth = fontSmall:getWidth(currentBootlogoPreview.errorMessage)
            local textX = currentBootlogoPreview.x + (Config.PREVIEW_WIDTH - textWidth) / 2
            local textY = currentBootlogoPreview.y + (Config.PREVIEW_HEIGHT - fontSmall:getHeight()) / 2
            love.graphics.print(currentBootlogoPreview.errorMessage, textX, textY)
        end
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
    
    -- Bottom bar text
    love.graphics.setColor(unpack(Config.COLORS.TEXT))
    love.graphics.setFont(fontSmall)
    love.graphics.print("D-pad +: Navigate | A: Select | B: Quit", xPos + 20, yPos + 15)
	love.graphics.print("by shahmir-k", xPos + 550, yPos + 15)
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
        msgLog = "Choose a bootlogo to install"
        filebrowser.start("file")

    elseif button.action == "uninstall" then
        bootlogo.uninstall()

    elseif button.action == "delete" then
        -- Show confirmation popup for delete
        popup.show(
            "Delete Current Bootlogo", -- title
            "Are you sure you want to delete the current bootlogo?", -- message1
            "This action cannot be undone. You will need to reinstall a bootlogo.", -- message2
            "THIS DOES NOT CREATE A BACKUP", -- warning
            "deleteBootlogo", -- mode
            {"Yes", "No"}, -- optionText
            "no" -- defaultOption
        )
    
    elseif button.action == "install_theme" then
        msgLog = "Choose a theme to install the current bootlogo to"
        filebrowser.start("themeInstall")
    
    elseif button.action == "uninstall_theme" then
        msgLog = "Choose a theme to restore its original bootlogo"
        filebrowser.start("themeUninstall")
    
    elseif button.action == "install_all_themes" then
        msgLog = "Are you sure you want to install the current bootlogo to ALL themes?"
        popup.show(
            "Install to ALL Themes", -- title
            "Are you sure you want to install the current bootlogo to ALL themes?", -- message1
            "", -- message2
            "This may take a while.", -- warning
            "themeInstallAll", -- mode
            {"Yes", "No"}, -- optionText
            "no" -- defaultOption
        )
    
    elseif button.action == "uninstall_all_themes" then
        msgLog = "Are you sure you want to restore original bootlogos to ALL themes?"
        popup.show(
            "Uninstall from ALL Themes", -- title
            "Are you sure you want to restore original bootlogos to ALL themes?", -- message1
            "", -- message2
            "This may take a while.", -- warning
            "themeUninstallAll", -- mode
            {"Yes", "No"}, -- optionText
            "no" -- defaultOption
        )
    
    end
end

function handlePopupSelection(selectedOption, mode)
    if selectedOption == 1 then
        -- Yes - Handle based on popup mode
        if mode == "themeInstallAll" then
            popup.hide()
            bootlogo.processAllThemes("install")
        elseif mode == "themeUninstallAll" then
            popup.hide()
            bootlogo.processAllThemes("uninstall")
        elseif mode == "deleteBootlogo" then
            popup.hide()
            bootlogo.delete()
        elseif mode == "error" then
            popup.hide()
            -- Error popup - just close it
        elseif mode == "success" then
            popup.hide()
            -- Success popup - just close it
        elseif mode == "restartRequired" then
            -- Default restart behavior
            msgLog = "Restarting system..."
            
            -- Execute the proper reboot command for this system
            local result = os.execute("/opt/muos/script/mux/quit.sh reboot frontend")
            if not result then
                popup.hide()
                msgLog = "Failed to restart system"
            end
        elseif mode == "updateCheck" then
            -- do nothing
        elseif mode == "updateAvailable" then
            -- Handle update download Yes confirmation
            popup.hide()
            downloadLatestVersion()
        elseif mode == "Not Set" then
            msgLog = "huh, this shouldn't happen. You mucked up"
            popup.hide()
        else
            popup.hide()
        end
    else
        if mode == "themeInstallAll" or mode == "themeUninstallAll" then
            msgLog = ""
        end
        -- No - Just hide the popup
        if mode ~= "updateCheck" then
            popup.hide()
        end
    end
end

function handleFileBrowserSelection(selectedItem)
    if not selectedItem then return end
    
    if selectedItem.type == "directory" then
        -- Directory navigation is handled in filebrowser.selectItem()
        -- This function only handles file selection
        return
    else
        -- Selected a file
        if filebrowser.state.mode == "themeInstall" then
            bootlogo.installToTheme(selectedItem.path)
        elseif filebrowser.state.mode == "themeUninstall" then
            bootlogo.uninstallFromTheme(selectedItem.path)
        elseif filebrowser.state.mode == "file" then
            bootlogo.install(selectedItem.path)
        else
            filebrowser.close()
        end
    end
end
