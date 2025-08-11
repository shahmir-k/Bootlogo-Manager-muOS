-- Shahmir Khan August 11 2025
-- Bootlogo Manager v1.0.1 Unused Functions File
-- https://github.com/shahmir-k
-- https://linkedin.com/in/shahmir-k

function installBootlogoToThemeInternal(themePath)
    -- Internal version of installBootlogoToTheme that returns success/failure
    -- This is the same logic as installBootlogoToTheme but without UI updates
    
    -- Create temporary directory for extraction
    local tempDir = "/tmp/theme_extract_" .. os.time() .. "_" .. math.random(1000, 9999)
    local extractCmd = "mkdir -p " .. tempDir .. " && cd " .. tempDir .. " && unzip -q '" .. themePath .. "'"
    
    local extractResult = os.execute(extractCmd)
    if not extractResult then
        os.execute("rm -rf " .. tempDir)
        return false
    end
    
    -- Search for bootlogo files
    local bootlogoPath = nil
    local bootlogoOriginalPath = nil
    
    local findCmd = "find " .. tempDir .. " -name 'bootlogo.bmp' -o -name 'bootlogo.bmp.original'"
    local findHandle = io.popen(findCmd)
    if findHandle then
        local findResult = findHandle:read("*a")
        findHandle:close()
        
        for line in findResult:gmatch("[^\r\n]+") do
            if line:match("bootlogo%.bmp$") then
                bootlogoPath = line
            elseif line:match("bootlogo%.bmp%.original$") then
                bootlogoOriginalPath = line
            end
        end
    end
    
    if not bootlogoPath then
        os.execute("rm -rf " .. tempDir)
        return false
    end
    
    -- Check if we have a current bootlogo to install
    local currentBootlogoExists = io.popen("test -f /mnt/boot/bootlogo.bmp && echo 'exists' || echo 'not_exists'")
    local currentBootlogoResult = currentBootlogoExists:read("*a"):gsub("%s+$", "")
    currentBootlogoExists:close()
    
    if currentBootlogoResult == "not_exists" then
        os.execute("rm -rf " .. tempDir)
        return false
    end
    
    -- Backup original bootlogo in theme if it doesn't exist
    if not bootlogoOriginalPath then
        local backupCmd = "cp '" .. bootlogoPath .. "' '" .. bootlogoPath .. ".original'"
        os.execute(backupCmd)
    end
    
    -- Copy current bootlogo to theme
    local copyCmd = "cp /mnt/boot/bootlogo.bmp '" .. bootlogoPath .. "'"
    local copyResult = os.execute(copyCmd)
    
    if not copyResult then
        os.execute("rm -rf " .. tempDir)
        return false
    end
    
    -- Repack the theme file
    local repackCmd = "cd " .. tempDir .. " && zip -r -q '" .. themePath .. ".new' ."
    local repackResult = os.execute(repackCmd)
    
    if not repackResult then
        os.execute("rm -rf " .. tempDir)
        os.execute("rm -f '" .. themePath .. ".new'")
        return false
    end
    
    -- Replace original theme file with new one
    local replaceCmd = "mv '" .. themePath .. ".new' '" .. themePath .. "'"
    local replaceResult = os.execute(replaceCmd)
    
    if not replaceResult then
        os.execute("rm -rf " .. tempDir)
        os.execute("rm -f '" .. themePath .. ".new'")
        return false
    end
    
    -- Clean up temporary directory
    os.execute("rm -rf " .. tempDir)
    return true
end

function uninstallBootlogoFromThemeInternal(themePath)
    -- Internal version of uninstallBootlogoFromTheme that returns success/failure
    -- This is the same logic as uninstallBootlogoFromTheme but without UI updates
    
    -- Create temporary directory for extraction
    local tempDir = "/tmp/theme_extract_" .. os.time() .. "_" .. math.random(1000, 9999)
    local extractCmd = "mkdir -p " .. tempDir .. " && cd " .. tempDir .. " && unzip -q '" .. themePath .. "'"
    
    local extractResult = os.execute(extractCmd)
    if not extractResult then
        os.execute("rm -rf " .. tempDir)
        return false
    end
    
    -- Search for bootlogo files
    local bootlogoPath = nil
    local bootlogoOriginalPath = nil
    
    local findCmd = "find " .. tempDir .. " -name 'bootlogo.bmp' -o -name 'bootlogo.bmp.original'"
    local findHandle = io.popen(findCmd)
    if findHandle then
        local findResult = findHandle:read("*a")
        findHandle:close()
        
        for line in findResult:gmatch("[^\r\n]+") do
            if line:match("bootlogo%.bmp$") then
                bootlogoPath = line
            elseif line:match("bootlogo%.bmp%.original$") then
                bootlogoOriginalPath = line
            end
        end
    end
    
    if not bootlogoPath or not bootlogoOriginalPath then
        os.execute("rm -rf " .. tempDir)
        return false
    end
    
    -- Restore original bootlogo from backup
    local restoreCmd = "cp '" .. bootlogoOriginalPath .. "' '" .. bootlogoPath .. "'"
    local restoreResult = os.execute(restoreCmd)
    
    if not restoreResult then
        os.execute("rm -rf " .. tempDir)
        return false
    end
    
    -- Remove the backup file since we've restored it
    local removeBackupCmd = "rm '" .. bootlogoOriginalPath .. "'"
    os.execute(removeBackupCmd)
    
    -- Repack the theme file
    local repackCmd = "cd " .. tempDir .. " && zip -r -q '" .. themePath .. ".new' ."
    local repackResult = os.execute(repackCmd)
    
    if not repackResult then
        os.execute("rm -rf " .. tempDir)
        os.execute("rm -f '" .. themePath .. ".new'")
        return false
    end
    
    -- Replace original theme file with new one
    local replaceCmd = "mv '" .. themePath .. ".new' '" .. themePath .. "'"
    local replaceResult = os.execute(replaceCmd)
    
    if not replaceResult then
        os.execute("rm -rf " .. tempDir)
        os.execute("rm -f '" .. themePath .. ".new'")
        return false
    end
    
    -- Clean up temporary directory
    os.execute("rm -rf " .. tempDir)
    return true
end 