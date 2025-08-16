-- Bootlogo Functions Module for Bootlogo Manager
-- Handles all bootlogo installation, uninstallation, and management functions

local Config = {}
local magick = require("imagemagick")
local lfs = require("lfs")
local fileUtils = require("fileUtils")
local zip = require("brimworks.zip") -- brimworks lua-zip

local bootlogo = {}

-- Set config function
function bootlogo.setConfig(configObj)
    Config = configObj
end

-- Set message log function
function bootlogo.setMessageLogFunction(func)
    bootlogo.setMsgLog = func
end

-- Set preview update function
function bootlogo.setPreviewUpdateFunction(func)
    bootlogo.updatePreview = func
end

-- Set popup system (for direct popup access)
function bootlogo.setPopupSystem(popupObj)
    bootlogo.popup = popupObj
end

-- Set filebrowser system (for direct filebrowser access)
function bootlogo.setFilebrowserSystem(filebrowserObj)
    bootlogo.filebrowser = filebrowserObj
end







-- Install bootlogo
function bootlogo.install(filePath)
    bootlogo.setMsgLog("Installing bootlogo: " .. filePath:match("([^/]+)$"))

    local logoInstalled = false

    if bootlogo.filebrowser then
        bootlogo.filebrowser.close()
    end
    
    -- Check if /mnt/boot exists
    if fileUtils.dirExists(Config.BOOTLOGO_PATH) then
        print("✓ " .. Config.BOOTLOGO_PATH .. " directory exists")
        
        local bootlogoFile = Config.BOOTLOGO_PATH .. "/" .. Config.BOOTLOGO_FILENAME
        local originalBootlogoFile = Config.BOOTLOGO_PATH .. "/" .. Config.BOOTLOGO_FILENAME .. ".original"

        -- Check if bootlogo.bmp exists in /mnt/boot
        local bootlogoExists = fileUtils.fileExists(bootlogoFile)
        local originalExists = fileUtils.fileExists(originalBootlogoFile)

        if not originalExists then
            print("Creating backup: " .. Config.BOOTLOGO_FILENAME .. " → " .. Config.BOOTLOGO_FILENAME .. ".original")
            -- Rename bootlogo.bmp to bootlogo.bmp.original
            local success, err = fileUtils.renameFile(bootlogoFile, originalBootlogoFile)
            
            if success then
                print("✓ Backup created successfully")
                bootlogo.setMsgLog("Backup created: " .. Config.BOOTLOGO_FILENAME .. ".original")
            else
                print("✗ Backup failed: " .. (err or "Unknown error"))
                bootlogo.setMsgLog("Backup failed: " .. (err or "Unknown error"))
                if bootlogo.popup then
                    bootlogo.popup.show(
                        "Error", -- title
                        "Backup failed to create", -- message1
                        "", -- message2
                        (err or "Unknown error"), -- warning
                        "error", -- mode
                        {"OK"}, -- optionText
                        "yes" -- defaultOption
                    )
                end
                -- Update preview if callback is set
                if bootlogo.updatePreview then
                    bootlogo.updatePreview()
                end
                return logoInstalled
            end
        else
            print("✓ Backup already exists: " .. Config.BOOTLOGO_FILENAME .. ".original")
            bootlogo.setMsgLog("Backup already exists: " .. Config.BOOTLOGO_FILENAME .. ".original")
        end

        local file_ext = filePath:match("%.([^%.]+)$"):lower()
        local destPath = Config.BOOTLOGO_PATH .. "/" .. Config.BOOTLOGO_FILENAME
        local copySuccess, copyErr = nil, nil

        if file_ext == "bmp" then
            -- Copy the new bootlogo.bmp to /mnt/boot
            print("Copying new bootlogo: " .. filePath .. " → " .. destPath)
            copySuccess, copyErr = fileUtils.copyFile(filePath, destPath, true)
        elseif Config.MAGICK_AVAILABLE then
            -- Convert the new bootlogo to bmp
            print("Converting new bootlogo to bmp: " .. filePath .. " → " .. destPath)
            copySuccess, copyErr = magick.convert_to_bmp(filePath, destPath, Config.WINDOW_WIDTH, Config.WINDOW_HEIGHT)
        else
            print("✗ ImageMagick is not available, cannot convert to bmp")
            bootlogo.setMsgLog("Error: ImageMagick is not available, cannot convert to bmp")
            copyErr = "ImageMagick is not available, cannot convert to bmp"
        end
        
        if copySuccess then
            print("✓ New bootlogo copied successfully")
            if originalExists then
                bootlogo.setMsgLog("New bootlogo installed: " .. filePath:match("([^/]+)$") .. " (Backup already present)")
            else
                bootlogo.setMsgLog("New bootlogo installed: " .. filePath:match("([^/]+)$") .. " (Backup created)")
            end
            logoInstalled = true
        else
            print("✗ Copy failed: " .. (copyErr or "Unknown error"))
            bootlogo.setMsgLog("Copy failed: " .. (copyErr or "Unknown error"))
            if bootlogo.popup then
                bootlogo.popup.show(
                    "Error", -- title
                    "Copying new bootlogo failed", -- message1
                    "", -- message2
                    (copyErr or "Unknown error"), -- warning
                    "error", -- mode
                    {"OK"}, -- optionText
                    "yes" -- defaultOption
                )
            end
        end
    else
        print("✗ " .. Config.BOOTLOGO_PATH .. " directory does not exist")
        bootlogo.setMsgLog("Error: " .. Config.BOOTLOGO_PATH .. " directory not found")
        
        -- Show error popup if popup object is available
        if bootlogo.popup then
            bootlogo.popup.show(
                "Error", -- title
                "Boot directory not found", -- message1
                "", -- message2
                "The " .. Config.BOOTLOGO_PATH .. " directory does not exist on this system", -- warning
                "error", -- mode
                {"OK"}, -- optionText
                "yes" -- defaultOption
            )
        end
        -- Update preview if callback is set
        if bootlogo.updatePreview then
            bootlogo.updatePreview()
        end
        return logoInstalled
    end
    
    -- Update preview if callback is set
    if bootlogo.updatePreview then
        bootlogo.updatePreview()
    end

    
    -- Show restart popup if installation was successful
    if logoInstalled and bootlogo.popup then
        bootlogo.popup.show(
            "Restart Required", -- title
            "A clean restart is required to apply these changes, Restart now?", -- message1
            "", -- message2
            "A hard reset or power off right now will result in a blank bootlogo", -- warning
            "restartRequired", -- mode
            {"Yes", "No"}, -- optionText
            "yes" -- defaultOption
        )
    end
    
    return logoInstalled
end

-- Uninstall bootlogo
function bootlogo.uninstall()
    bootlogo.setMsgLog("Uninstalling bootlogo...")
    
    local uninstallSuccess = false
    
    local bootlogoFile = Config.BOOTLOGO_PATH .. "/" .. Config.BOOTLOGO_FILENAME
    local originalBootlogoFile = Config.BOOTLOGO_PATH .. "/" .. Config.BOOTLOGO_FILENAME .. ".original"

    -- Check if /mnt/boot exists
    if fileUtils.dirExists(Config.BOOTLOGO_PATH) then
        print("✓ " .. Config.BOOTLOGO_PATH .. " directory exists")
        
        -- Check if bootlogo.bmp.original and bootlogo.bmp exist
        local bootlogoExists = fileUtils.fileExists(bootlogoFile)
        local originalExists = fileUtils.fileExists(originalBootlogoFile)
        
        if originalExists then
            print("✓ Found backup: " .. Config.BOOTLOGO_FILENAME .. ".original to restore")

            if bootlogoExists then
                print("✓ Found " .. Config.BOOTLOGO_FILENAME .. " to delete")

                -- Delete the current bootlogo.bmp
                print("Deleting: " .. bootlogoFile)
                local removeSuccess, removeErr = fileUtils.removeFile(bootlogoFile)
                
                if removeSuccess then
                    print("✓ Current bootlogo removed")
                else
                    print("✗ Remove failed: " .. (removeErr or "Unknown error"))
                    bootlogo.setMsgLog("Remove failed: " .. (removeErr or "Unknown error"))
                    if bootlogo.popup then
                        bootlogo.popup.show(
                            "Error", -- title
                            "Deleting current bootlogo failed", -- message1
                            "", -- message2
                            (removeErr or "Unknown error"), -- warning
                            "error", -- mode
                            {"OK"}, -- optionText
                            "yes" -- defaultOption
                        )
                    end
                    -- Update preview if callback is set
                    if bootlogo.updatePreview then
                        bootlogo.updatePreview()
                    end
                    return uninstallSuccess
                end
            end


            -- Restore original bootlogo
            print("Restoring: " .. originalBootlogoFile)
            local restoreSuccess, restoreErr = fileUtils.renameFile(originalBootlogoFile, bootlogoFile)
            
            if restoreSuccess then
                if bootlogoExists then
                    print("✓ Original bootlogo restored successfully. Previous bootlogo removed.")
                    bootlogo.setMsgLog("Original bootlogo restored successfully. Previous bootlogo removed.")

                else
                    print("✓ Original bootlogo restored successfully. No previous bootlogo found.")
                    bootlogo.setMsgLog("Original bootlogo restored successfully. No previous bootlogo found.")
                end
                uninstallSuccess = true
            else
                print("✗ Restore failed: " .. (restoreErr or "Unknown error"))
                bootlogo.setMsgLog("Restore failed: " .. (restoreErr or "Unknown error"))
                if bootlogo.popup then
                    bootlogo.popup.show(
                        "Error", -- title
                        "Restoring original bootlogo failed", -- message1
                        "", -- message2
                        (restoreErr or "Unknown error"), -- warning
                        "error", -- mode
                        {"OK"}, -- optionText
                        "yes" -- defaultOption
                    )
                end
            end
        else
            print("No backup found: " .. Config.BOOTLOGO_FILENAME .. ".original")
            bootlogo.setMsgLog("No backup found to restore")
        end
    else
        print("✗ " .. Config.BOOTLOGO_PATH .. " directory does not exist")
        bootlogo.setMsgLog("Error: " .. Config.BOOTLOGO_PATH .. " directory not found")
    end
    
    -- Update preview if callback is set
    if bootlogo.updatePreview then
        bootlogo.updatePreview()
    end
    
    -- Show restart popup if uninstall was successful
    if uninstallSuccess and bootlogo.popup then
        bootlogo.popup.show(
            "Restart Required", -- title
            "A clean restart is required to apply these changes, Restart now?", -- message1
            "", -- message2
            "A hard reset or power off right now will result in a blank bootlogo", -- warning
            "restartRequired", -- mode
            {"Yes", "No"}, -- optionText
            "yes" -- defaultOption
        )
    end
    
    return uninstallSuccess
end

-- Delete current bootlogo
function bootlogo.delete()
    bootlogo.setMsgLog("Deleting current bootlogo...")
    
    local deleteSuccess = false
    
    -- Check if /mnt/boot exists
    if fileUtils.dirExists(Config.BOOTLOGO_PATH) then
        print("✓ " .. Config.BOOTLOGO_PATH .. " directory exists")

        local bootlogoFile = Config.BOOTLOGO_PATH .. "/" .. Config.BOOTLOGO_FILENAME
        
        -- Check if bootlogo.bmp exists
        local bootlogoExists = fileUtils.fileExists(bootlogoFile)
        
        if bootlogoExists then
            print("✓ Found bootlogo.bmp")
            
            -- Remove current bootlogo.bmp
            local removeSuccess, removeErr = fileUtils.removeFile(bootlogoFile)
            
            if removeSuccess then
                print("✓ Current bootlogo deleted successfully")
                bootlogo.setMsgLog("Current bootlogo deleted successfully")
                deleteSuccess = true
            else
                print("✗ Delete failed: " .. (removeErr or "Unknown error"))
                bootlogo.setMsgLog("Delete failed: " .. (removeErr or "Unknown error"))
                if bootlogo.popup then
                    bootlogo.popup.show(
                        "Error", -- title
                        "Delete failed", -- message1
                        "", -- message2
                        (removeErr or "Unknown error"), -- warning
                        "error", -- mode
                        {"OK"}, -- optionText
                        "yes" -- defaultOption
                    )
                end
            end
        else
            print("No " .. Config.BOOTLOGO_FILENAME .. " found to delete")
            bootlogo.setMsgLog("No " .. Config.BOOTLOGO_FILENAME .. " found to delete")
        end
    else
        print("✗ " .. Config.BOOTLOGO_PATH .. " directory does not exist")
        bootlogo.setMsgLog("Error: " .. Config.BOOTLOGO_PATH .. " directory not found")
    end
    
    -- Update preview if callback is set
    if bootlogo.updatePreview then
        bootlogo.updatePreview()
    end
    
    -- Show success popup if deletion was successful
    if deleteSuccess and bootlogo.popup then
        bootlogo.popup.show(
            "Success", -- title
            "Bootlogo deleted successfully", -- message1
            "", -- message2
            "The current bootlogo has been removed", -- warning
            "success", -- mode
            {"OK"}, -- optionText
            "yes" -- defaultOption
        )
    end
    
    return deleteSuccess
end

-- Install bootlogo to theme
function bootlogo.installToTheme(themePath, silent)
    local debug = true

    print("Installing bootlogo to theme: " .. themePath:match("([^/]+)$"))

    if not fileUtils.fileExists(Config.BOOTLOGO_PATH .. "/" .. Config.BOOTLOGO_FILENAME) then
        print("Bootlogo file does not exist: " .. Config.BOOTLOGO_PATH .. "/" .. Config.BOOTLOGO_FILENAME)
        bootlogo.setMsgLog("No current bootlogo found to install to theme " .. themePath:match("([^/]+)$"))
        return false
    end

    if not fileUtils.fileExists(themePath) then
        print("Theme file does not exist: " .. themePath:match("([^/]+)$"))
        bootlogo.setMsgLog("Error: Install to theme failed, theme file does not exist: " .. themePath:match("([^/]+)$"))
        return false
    end

    local zipFile, error = zip.open(themePath)
    if not zipFile then
        print("Failed to open theme archive: " .. (error or "Unknown error"))
        bootlogo.setMsgLog("Error: Install to theme failed, failed to open theme archive: " .. (error or "Unknown error"))
        return false
    end

    local numFiles = zipFile:get_num_files()
    print("Archive contains " .. numFiles .. " files")

    if numFiles <= 0 then
        print("Warning: Archive appears to be empty or invalid")
        bootlogo.setMsgLog("Error: Install to theme failed, archive appears to be empty or invalid")
        zipFile:close()
        return false
    end

    local currentResolution = Config.WINDOW_WIDTH .. "x" .. Config.WINDOW_HEIGHT
    local bootlogoZipPath = nil
    local bootlogoOriginalZipPath = nil

    for i = 1, numFiles do

        local fileName = zipFile:get_name(i)
        if fileName then
            -- print("Processing file " .. i .. "/" .. numFiles .. ": " .. fileName)
            if fileName == currentResolution .. "/image/" .. Config.BOOTLOGO_FILENAME then
                -- print("Found bootlogo.bmp in theme!!! : " .. fileName)
                bootlogoZipPath = fileName
            elseif fileName == currentResolution .. "/image/" .. Config.BOOTLOGO_FILENAME .. ".original" then
                -- print("Found bootlogo.bmp.original in theme!!! : " .. fileName)
                bootlogoOriginalZipPath = fileName
            end
        end
    end

    if not bootlogoZipPath then
        print("Warning: No bootlogo.bmp found in theme for " .. currentResolution)
        bootlogo.setMsgLog("Error: Install to theme failed, no bootlogo.bmp found in theme for " .. currentResolution)
        zipFile:close()
        return false
    end

    if not bootlogoOriginalZipPath then
        zipFile:rename(bootlogoZipPath, bootlogoZipPath .. ".original")
        print("Creating backup! Renamed bootlogo.bmp to bootlogo.bmp.original")
    else
        zipFile:delete(bootlogoZipPath)
        print("Backup already present! Removed existing bootlogo.bmp from theme")
    end

    zipFile:add(bootlogoZipPath, "file", Config.BOOTLOGO_PATH .. "/" .. Config.BOOTLOGO_FILENAME, 0, -1)
    zipFile:close()

    if not bootlogoOriginalZipPath then
        print("Bootlogo successfully installed to theme: " .. themePath:match("([^/]+)$") .. " (Backup created)")
        bootlogo.setMsgLog("Bootlogo successfully installed to theme: " .. themePath:match("([^/]+)$") .. " (Backup created)")
    else
        print("Bootlogo successfully installed to theme: " .. themePath:match("([^/]+)$") .. " (Backup already present)")
        bootlogo.setMsgLog("Bootlogo successfully installed to theme: " .. themePath:match("([^/]+)$") .. " (Backup already present)")
    end

    -- -- Verifying zip structure (debugging remove later)
    -- local zipTest = zip.open(themePath)
    -- local numFiles = zipTest:get_num_files()
    -- print("Archive contains " .. numFiles .. " files")
    -- for i = 1, numFiles do
    --     local fileName = zipTest:get_name(i)
    --     print("File " .. i .. ": " .. fileName)
    -- end
    -- zipTest:close()

    if bootlogo.popup and not silent then
        bootlogo.popup.show(
            "Success", -- title
            "Bootlogo installed to theme: " .. themePath:match("([^/]+)$"), -- message1
            "Switch to this theme to see the new bootlogo", -- message2
            "", -- warning
            "success", -- mode
            {"OK"}, -- optionText
            "yes" -- defaultOption
        )
    end


    return true
end

-- Uninstall bootlogo from theme
function bootlogo.uninstallFromTheme(themePath, silent)
    local debug = true

    print("Uninstalling bootlogo from theme: " .. themePath:match("([^/]+)$"))

    if not fileUtils.fileExists(themePath) then
        print("Theme file does not exist: " .. themePath)
        bootlogo.setMsgLog("Error: Uninstall from theme failed, theme file does not exist: " .. themePath)
        return false
    end

    local zipFile, error = zip.open(themePath)
    if not zipFile then
        print("Failed to open theme archive: " .. (error or "Unknown error"))
        bootlogo.setMsgLog("Error: Uninstall from theme failed, failed to open theme archive: " .. (error or "Unknown error"))
        return false
    end

    local numFiles = zipFile:get_num_files()
    print("Archive contains " .. numFiles .. " files")

    if numFiles <= 0 then
        print("Warning: Archive appears to be empty or invalid")
        bootlogo.setMsgLog("Error: Uninstall from theme failed, archive appears to be empty or invalid")
        zipFile:close()
        return false
    end

    local currentResolution = Config.WINDOW_WIDTH .. "x" .. Config.WINDOW_HEIGHT
    local bootlogoZipPath = nil
    local bootlogoOriginalZipPath = nil

    for i = 1, numFiles do
        local fileName = zipFile:get_name(i)
        if fileName then
            --print("Processing file " .. i .. "/" .. numFiles .. ": " .. fileName)
            if fileName == currentResolution .. "/image/" .. Config.BOOTLOGO_FILENAME then
                --print("Found bootlogo.bmp in theme!!! : " .. fileName)
                bootlogoZipPath = fileName
            elseif fileName == currentResolution .. "/image/" .. Config.BOOTLOGO_FILENAME .. ".original" then
                --print("Found bootlogo.bmp.original in theme!!! : " .. fileName)
                bootlogoOriginalZipPath = fileName
            end
        end
    end

    if not bootlogoOriginalZipPath then
        print("Warning: No bootlogo.bmp.original found in theme for " .. currentResolution)
        bootlogo.setMsgLog("No backup found to restore to theme " .. themePath:match("([^/]+)$") .. " (" .. currentResolution .. ")")
        zipFile:close()
        return false
    end

    if bootlogoZipPath then
        zipFile:delete(bootlogoZipPath)
        print("Removed existing bootlogo.bmp from theme")
    end

    local newZipPath = bootlogoOriginalZipPath:gsub(".original", "")
    zipFile:rename(bootlogoOriginalZipPath, newZipPath)
    print("Restored original bootlogo.bmp to theme")
    zipFile:close()

    print("Bootlogo successfully uninstalled from theme: " .. themePath:match("([^/]+)$") .. " (Backup restored)")
    bootlogo.setMsgLog("Bootlogo successfully uninstalled from theme: " .. themePath:match("([^/]+)$") .. " (Backup restored)")

    if bootlogo.popup and not silent then
        bootlogo.popup.show(
            "Success", -- title
            "Bootlogo uninstalled from theme: " .. themePath:match("([^/]+)$"), -- message1
            "Switch to this theme to see the original bootlogo", -- message2
            "", -- warning
            "success", -- mode
            {"OK"}, -- optionText
            "yes" -- defaultOption
        )
    end

    return true
end

-- Install bootlogo to all themes
function bootlogo.installToAllThemes()
    bootlogo.setMsgLog("Installing bootlogo to ALL themes...")
    
    local successCount = 0
    local totalCount = 0
    
    -- Get list of themes using lfs
    local themesDir = Config.THEME_PATH
    local success, err = pcall(function()
        print("Searching for themes in: " .. themesDir)
        for file in lfs.dir(themesDir) do
            if file ~= "." and file ~= ".." then
                print("Processing item: " .. file)
                local themePath = themesDir .. "/" .. file
                local attr = lfs.attributes(themePath)

                -- Check if it's a directory and has .muxthm extension
                if attr and attr.mode == "file" and file:match("%.muxthm$") then
                    print("Found theme: " .. themePath)
                    totalCount = totalCount + 1
                    if bootlogo.installToTheme(themePath, true) then
                        successCount = successCount + 1
                    end
                end
            end
        end
    end)
    
    if not success then
        print("Error finding themes: " .. (err or "Unknown error"))
    end
    
    bootlogo.setMsgLog("Installed current bootlogo to " .. successCount .. " of " .. totalCount .. " themes")

    if bootlogo.popup then
        bootlogo.popup.show(
            "Success", -- title
            "Installed current bootlogo to " .. successCount .. " of " .. totalCount .. " themes", -- message1
            "", -- message2
            "", -- warning
            "success", -- mode
            {"OK"}, -- optionText
            "yes" -- defaultOption
        )
    end

    return successCount, totalCount
end

-- Uninstall bootlogo from all themes
function bootlogo.uninstallFromAllThemes()
    bootlogo.setMsgLog("Uninstalling bootlogo from ALL themes...")
    
    local successCount = 0
    local totalCount = 0
    
    -- Get list of themes using lfs
    local themesDir = Config.THEME_PATH
    local success, err = pcall(function()
        print("Searching for themes in: " .. themesDir)
        for file in lfs.dir(themesDir) do
            if file ~= "." and file ~= ".." then
                print("Processing item: " .. file)
                local themePath = themesDir .. "/" .. file
                local attr = lfs.attributes(themePath)

                -- Check if it's a directory and has .muxthm extension
                if attr and attr.mode == "file" and file:match("%.muxthm$") then
                    print("Found theme: " .. themePath)
                    totalCount = totalCount + 1
                    if bootlogo.uninstallFromTheme(themePath, true) then
                        successCount = successCount + 1
                    end
                end
            end
        end
    end)
    
    if not success then
        print("Error finding themes: " .. (err or "Unknown error"))
    end
    
    bootlogo.setMsgLog("Restored original bootlogo to " .. successCount .. " of " .. totalCount .. " themes")

    if bootlogo.popup then
        bootlogo.popup.show(
            "Success", -- title
            "Restored original bootlogo to " .. successCount .. " of " .. totalCount .. " themes", -- message1
            "", -- message2
            "", -- warning
            "success", -- mode
            {"OK"}, -- optionText
            "yes" -- defaultOption
        )
    end

    return successCount, totalCount
end

-- Process all themes (generic function)
function bootlogo.processAllThemes(operation)
    if operation == "install" then
        return bootlogo.installToAllThemes()
    elseif operation == "uninstall" then
        return bootlogo.uninstallFromAllThemes()
    else
        bootlogo.setMsgLog("Unknown operation: " .. operation)
        return 0, 0
    end
end

return bootlogo
