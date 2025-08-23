-- File Browser Module for Bootlogo Manager
-- Handles file browsing functionality

local lfs = require("lfs")
local fileUtils = require("fileUtils")
local magick = require("imagemagick")
local filebrowser = {}
local Config = {}

-- File browser state
filebrowser.state = {
    active = false,
    mode = "file", -- "file" or "themeInstall" or "themeUninstall"
    currentPath = "/mnt/mmc",
    files = {},
    selectedIndex = 1,
    scrollOffset = 0,
    -- Image preview state
    previewImage = nil,
    previewErrorMessage = nil,
    previewX = 0,
    previewY = 0
}

-- Set the config
function filebrowser.setConfig(config)
    Config = config
end

-- Set the selection handler
function filebrowser.setSelectionHandler(handler)
    filebrowser.onSelection = handler
end

-- Set the message log function
function filebrowser.setMessageLogFunction(callback)
    filebrowser.setMessageLog = callback
end

-- Load image preview for selected file
function filebrowser.loadImagePreview()
    -- Clear existing preview
    if filebrowser.state.previewImage then
        filebrowser.state.previewImage:release()
        filebrowser.state.previewImage = nil
    end
    filebrowser.state.previewErrorMessage = nil
    
    -- Check if we have files and a valid selection
    if #filebrowser.state.files == 0 or filebrowser.state.selectedIndex > #filebrowser.state.files then
        print("DEBUG: No files or invalid selection")
        return
    end
    
    local selectedItem = filebrowser.state.files[filebrowser.state.selectedIndex]
    print("DEBUG: Selected item: " .. selectedItem.name .. " (type: " .. selectedItem.type .. ")")
    
    -- Only show preview for image files
    if selectedItem.type == "file" and filebrowser.isImageFile(selectedItem.name) then
        print("DEBUG: Image file detected: " .. selectedItem.name)
        
        if Config.MAGICK_AVAILABLE then
            local preview = magick.generatePreviewCanvas(selectedItem.path, Config.PREVIEW_WIDTH, Config.PREVIEW_HEIGHT)
            if preview then
                filebrowser.state.previewImage = preview
            else
                print("DEBUG: Failed to generate preview canvas")
                filebrowser.state.previewErrorMessage = "Failed to load image"
            end
        else
            print("DEBUG: ImageMagick is not available, using error message as preview")
            filebrowser.state.previewErrorMessage = "ImageMagick not available"
        end
    elseif selectedItem.type == "file" and filebrowser.isThemeFile(selectedItem.name) then
        print("DEBUG: Theme file detected: " .. selectedItem.name)

        local currentResolution = Config.WINDOW_WIDTH .. "x" .. Config.WINDOW_HEIGHT

        local preview = magick.generateThemePreviewCanvas(selectedItem.path, Config.PREVIEW_WIDTH, Config.PREVIEW_HEIGHT, currentResolution, Config.BOOTLOGO_FILENAME)
        if preview then
            filebrowser.state.previewImage = preview
        else
            print("DEBUG: Failed to generate theme preview canvas")
            filebrowser.state.previewErrorMessage = "No ".. currentResolution .. " bootlogo"
        end
    end
    
    -- Calculate preview position (bottom right corner)
    filebrowser.state.previewX = Config.WINDOW_WIDTH - Config.PREVIEW_WIDTH - 30
    filebrowser.state.previewY = Config.WINDOW_HEIGHT - Config.PREVIEW_HEIGHT - 180
end

-- Draw the file browser interface
function filebrowser.draw(fontSmall, fontBig)
    local xPos = 20
    local yPos = 70
    local width = Config.WINDOW_WIDTH - 40
    local height = Config.WINDOW_HEIGHT - 180
    
    -- File browser background
    love.graphics.setColor(unpack(Config.COLORS.HEADER_BG))
    love.graphics.rectangle("fill", xPos, yPos, width, height, 8, 8)
    
    -- Current path
    love.graphics.setColor(unpack(Config.COLORS.TEXT))
    love.graphics.setFont(fontSmall)
    love.graphics.print("Path: " .. filebrowser.state.currentPath, xPos + 10, yPos + 10)
    
    -- File list
    yPos = yPos + 40
    local itemHeight = 25
    local maxItems = math.floor((height - 40) / itemHeight)
    
    for i = 1, math.min(maxItems, #filebrowser.state.files) do
        local itemIndex = i + filebrowser.state.scrollOffset
        if itemIndex <= #filebrowser.state.files then
            local item = filebrowser.state.files[itemIndex]
            local itemY = yPos + (i - 1) * itemHeight
            
            -- Selection highlight
            if itemIndex == filebrowser.state.selectedIndex then
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
    if #filebrowser.state.files > maxItems then
        love.graphics.setColor(unpack(Config.COLORS.TEXT_SECONDARY))
        love.graphics.print("Scroll: " .. (filebrowser.state.scrollOffset + 1) .. "-" .. math.min(filebrowser.state.scrollOffset + maxItems, #filebrowser.state.files) .. " of " .. #filebrowser.state.files, xPos + 10, yPos + maxItems * itemHeight + 10)
    end
    
    -- Draw image preview
    if filebrowser.state.previewImage or filebrowser.state.previewErrorMessage then
        -- Draw preview background
        love.graphics.setColor(unpack(Config.COLORS.BUTTON_BG))
        love.graphics.rectangle("fill", filebrowser.state.previewX - 5, filebrowser.state.previewY - 5, 
                               Config.PREVIEW_WIDTH + 10, Config.PREVIEW_HEIGHT + 10, 4, 4)
        
        -- Draw preview border
        love.graphics.setColor(unpack(Config.COLORS.TEXT))
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", filebrowser.state.previewX - 5, filebrowser.state.previewY - 5, 
                               Config.PREVIEW_WIDTH + 10, Config.PREVIEW_HEIGHT + 10, 4, 4)
        
        if filebrowser.state.previewImage then
            -- Draw the preview image
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(filebrowser.state.previewImage, filebrowser.state.previewX, filebrowser.state.previewY)
            
        else
            -- Draw error message as placeholder text
            love.graphics.setColor(unpack(Config.COLORS.TEXT_SECONDARY))
            love.graphics.setFont(fontSmall)
            local textWidth = fontSmall:getWidth(filebrowser.state.previewErrorMessage)
            local textX = filebrowser.state.previewX + (Config.PREVIEW_WIDTH - textWidth) / 2
            local textY = filebrowser.state.previewY + (Config.PREVIEW_HEIGHT - fontSmall:getHeight()) / 2
            love.graphics.print(filebrowser.state.previewErrorMessage, textX, textY)
        end
    end
end

-- Start the file browser
function filebrowser.start(mode)
    filebrowser.state.active = true
    filebrowser.state.mode = mode
    filebrowser.state.selectedIndex = 1
    filebrowser.state.scrollOffset = 0
    
    -- Set appropriate starting directory based on mode
    if mode == "themeInstall" or mode == "themeUninstall" then
        filebrowser.state.currentPath = Config.THEME_PATH
    elseif mode == "file" then
        -- Use the working directory from Config
        filebrowser.state.currentPath = Config.WORKING_DIR
    else
        -- Use the working directory from Config
        filebrowser.state.currentPath = Config.WORKING_DIR
    end
    
    filebrowser.loadDirectoryContents()
    -- Load initial preview
    filebrowser.loadImagePreview()
end

-- Close the file browser
function filebrowser.close()
    filebrowser.state.active = false
    -- Clear preview when closing
    if filebrowser.state.previewImage then
        filebrowser.state.previewImage:release()
        filebrowser.state.previewImage = nil
    end
end

-- Load directory contents
function filebrowser.loadDirectoryContents()

    -- Debug: Print current path
    print("Trying to read directory: " .. filebrowser.state.currentPath)


    filebrowser.state.files = {}
    
    -- Add parent directory option
    if filebrowser.state.currentPath ~= "/" then
        table.insert(filebrowser.state.files, {
            name = "..",
            type = "directory",
            path = filebrowser.getParentPath(filebrowser.state.currentPath)
        })
    end
    
    -- Get directory contents using lfs
    local success, err = pcall(function()
        for file in lfs.dir(filebrowser.state.currentPath) do
            -- Skip . and .. entries
            if file ~= "." and file ~= ".." then
                local fullPath = filebrowser.state.currentPath .. "/" .. file
                local itemType = "file"
                
                -- Check if it's a directory using lfs
                local attr = lfs.attributes(fullPath)
                if attr and attr.mode == "directory" then
                    itemType = "directory"
                end
                
                -- Always add directories, but only add files that are supported
                if itemType == "directory" or filebrowser.isSupportedFile(file) then
                    table.insert(filebrowser.state.files, {
                        name = file,
                        type = itemType,
                        path = fullPath
                    })
                    print("Found: " .. file .. " (type: " .. itemType .. ")")
                end
            end
        end
    end)
    
    if not success then
        print("Error: Failed to read directory contents of " .. filebrowser.state.currentPath .. ": " .. (err or "Unknown error"))
        msgLog = "Cannot access directory: " .. filebrowser.state.currentPath
    end

    print("Total files/folders to display: " .. #filebrowser.state.files)

    -- Sort: directories first, then files
    table.sort(filebrowser.state.files, function(a, b)
        if a.type == "directory" and b.type ~= "directory" then
            return true
        elseif a.type ~= "directory" and b.type == "directory" then
            return false
        else
            return a.name < b.name
        end
    end)

end

-- Get parent path
function filebrowser.getParentPath(path)
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

-- Check if file is supported
function filebrowser.isSupportedFile(filename)
    if filebrowser.state.mode == "themeInstall" or filebrowser.state.mode == "themeUninstall" then
        return filebrowser.isThemeFile(filename)
    else
        return filebrowser.isImageFile(filename)
    end
end

-- Check if file is an image
function filebrowser.isImageFile(filename)
    local magick = require("imagemagick")
    local extensions = magick.supportedFormats()
    local lowerName = filename:lower()
    for _, ext in ipairs(extensions) do
        if lowerName:match(ext .. "$") then
            return true
        end
    end
    return false
end

-- Check if file is a theme file
function filebrowser.isThemeFile(filename)
    local extensions = {Config.THEME_EXTENSION}
    local lowerName = filename:lower()
    for _, ext in ipairs(extensions) do
        if lowerName:match(ext .. "$") then
            return true
        end
    end
    return false
end

-- Handle file browser input
function filebrowser.handleInput(dt, lastInputTime, inputDebounceDelay)
    if not filebrowser.state.active then return lastInputTime end
    
    lastInputTime = lastInputTime + dt
    
    -- Calculate visible items
    local height = Config.WINDOW_HEIGHT - 200
    local itemHeight = 25
    local maxItems = math.floor((height - 40) / itemHeight)
    
    if love.joystick.getJoysticks()[1] then
        local joystick = love.joystick.getJoysticks()[1]
        
        -- Navigation
        if joystick:isGamepadDown("dpup") and lastInputTime >= inputDebounceDelay then
            filebrowser.state.selectedIndex = filebrowser.state.selectedIndex - 1
            if filebrowser.state.selectedIndex < 1 then
                filebrowser.state.selectedIndex = #filebrowser.state.files
                -- Reset scroll to end when wrapping from top to bottom
                filebrowser.state.scrollOffset = math.max(0, #filebrowser.state.files - maxItems)
            else
                -- Update scroll offset if selection is outside visible area
                if filebrowser.state.selectedIndex <= filebrowser.state.scrollOffset then
                    filebrowser.state.scrollOffset = math.max(0, filebrowser.state.selectedIndex - 1)
                end
            end
            
            -- Load preview for new selection
            filebrowser.loadImagePreview()
            lastInputTime = 0
        elseif joystick:isGamepadDown("dpdown") and lastInputTime >= inputDebounceDelay then
            filebrowser.state.selectedIndex = filebrowser.state.selectedIndex + 1
            if filebrowser.state.selectedIndex > #filebrowser.state.files then
                filebrowser.state.selectedIndex = 1
                -- Reset scroll to beginning when wrapping from bottom to top
                filebrowser.state.scrollOffset = 0
            else
                -- Update scroll offset if selection is outside visible area
                if filebrowser.state.selectedIndex > filebrowser.state.scrollOffset + maxItems then
                    filebrowser.state.scrollOffset = filebrowser.state.selectedIndex - maxItems
                end
            end
            
            -- Load preview for new selection
            filebrowser.loadImagePreview()
            lastInputTime = 0
        end
        
        -- A button to select
        if joystick:isGamepadDown("a") and lastInputTime >= inputDebounceDelay then
            filebrowser.selectItem()
            lastInputTime = 0
        end
        
        -- B button to go back
        if joystick:isGamepadDown("b") and lastInputTime >= inputDebounceDelay then
            filebrowser.close()
            if filebrowser.setMessageLog then
                filebrowser.setMessageLog("")
            end
            lastInputTime = 0
        end
    end
    
    -- Keyboard fallback
    if love.keyboard.isDown("up") and lastInputTime >= inputDebounceDelay then
        filebrowser.state.selectedIndex = filebrowser.state.selectedIndex - 1
        if filebrowser.state.selectedIndex < 1 then
            filebrowser.state.selectedIndex = #filebrowser.state.files
            -- Reset scroll to end when wrapping from top to bottom
            filebrowser.state.scrollOffset = math.max(0, #filebrowser.state.files - maxItems)
        else
            -- Update scroll offset if selection is outside visible area
            if filebrowser.state.selectedIndex <= filebrowser.state.scrollOffset then
                filebrowser.state.scrollOffset = math.max(0, filebrowser.state.selectedIndex - 1)
            end
        end
        
        -- Load preview for new selection
        filebrowser.loadImagePreview()
        lastInputTime = 0
    elseif love.keyboard.isDown("down") and lastInputTime >= inputDebounceDelay then
        filebrowser.state.selectedIndex = filebrowser.state.selectedIndex + 1
        if filebrowser.state.selectedIndex > #filebrowser.state.files then
            filebrowser.state.selectedIndex = 1
            -- Reset scroll to beginning when wrapping from bottom to top
            filebrowser.state.scrollOffset = 0
        else
            -- Update scroll offset if selection is outside visible area
            if filebrowser.state.selectedIndex > filebrowser.state.scrollOffset + maxItems then
                filebrowser.state.scrollOffset = filebrowser.state.selectedIndex - maxItems
            end
        end
        
        -- Load preview for new selection
        filebrowser.loadImagePreview()
        lastInputTime = 0
    end
    
    if love.keyboard.isDown("return") or love.keyboard.isDown("space") then
        filebrowser.selectItem()
    end
    
    if love.keyboard.isDown("escape") then
        filebrowser.close()
        if filebrowser.setMessageLog then
            filebrowser.setMessageLog("")
        end
    end
    
    return lastInputTime
end

-- Handle file browser selection
function filebrowser.selectItem()
    if #filebrowser.state.files == 0 then return end
    
    local selectedItem = filebrowser.state.files[filebrowser.state.selectedIndex]
    
    if selectedItem.type == "directory" then
        if selectedItem.name == ".." then
            filebrowser.state.currentPath = selectedItem.path
        else
            filebrowser.state.currentPath = selectedItem.path
        end
        filebrowser.state.selectedIndex = 1
        filebrowser.state.scrollOffset = 0
        filebrowser.loadDirectoryContents()
        -- Load preview for new directory
        filebrowser.loadImagePreview()
    else
        -- File selected - call the selection handler if set
        if filebrowser.onSelection then
            filebrowser.onSelection(selectedItem)
        end
        -- Close the file browser
        filebrowser.close()
    end
end




return filebrowser
