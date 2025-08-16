-- File Utilities Module for Bootlogo Manager
-- Handles all file system operations and utilities

local lfs = require("lfs")

local fileUtils = {}

-- Helper function to check if directory exists
function fileUtils.dirExists(path)
    local success, attr = pcall(lfs.attributes, path)
    return success and attr and attr.mode == "directory"
end

-- Helper function to check if file exists
function fileUtils.fileExists(path)
    local success, attr = pcall(lfs.attributes, path)
    return success and attr and attr.mode == "file"
end

-- Helper function to rename files
function fileUtils.renameFile(oldPath, newPath)
    local success, err = pcall(os.rename, oldPath, newPath)
    return success, err
end

-- Helper function to copy files (with overwrite option)
function fileUtils.copyFile(srcPath, destPath, overwrite)
    overwrite = overwrite or false
    
    local success, err = pcall(function()
        -- Check if source file exists
        if not fileUtils.fileExists(srcPath) then
            error("Source file does not exist: " .. srcPath)
        end
        print("copyFile: Source file exists: " .. srcPath)
        
        -- Check if destination directory exists
        local destDir = destPath:match("(.*)/")
        if destDir and not fileUtils.dirExists(destDir) then
            error("Destination directory does not exist: " .. destDir)
        end
        print("copyFile: Destination directory exists: " .. destDir)
        -- Check if destination file already exists (unless overwrite is enabled)
        if not overwrite and fileUtils.fileExists(destPath) then
            error("Destination file already exists: " .. destPath)
        end
        print("copyFile: Destination file doesn't exist or overwrite is enabled: " .. destPath)
        local srcFile = io.open(srcPath, "rb")
        if not srcFile then
            error("Cannot open source file: " .. srcPath)
        end
        print("copyFile: Source file opened: " .. srcPath)
        local destFile = io.open(destPath, "wb")
        if not destFile then
            srcFile:close()
            error("Cannot create destination file: " .. destPath)
        end
        print("copyFile: Destination file created: " .. destPath)
        -- Read source file in chunks to handle large files
        local chunkSize = 8192 -- 8KB chunks
        local chunk = srcFile:read(chunkSize)
        while chunk do
            destFile:write(chunk)
            chunk = srcFile:read(chunkSize)
        end
        
        -- Close files
        srcFile:close()
        if not destFile:close() then
            os.remove(destPath) -- Clean up partial file
            error("Error writing destination file: " .. destPath)
        end
        
        return true
    end)
    
    return success, err
end

-- Helper function to remove files
function fileUtils.removeFile(path)
    local success, err = pcall(os.remove, path)
    return success, err
end

-- Helper function to create directories
function fileUtils.createDirectory(path)
    local success, err = pcall(lfs.mkdir, path)
    return success, err
end

return fileUtils
