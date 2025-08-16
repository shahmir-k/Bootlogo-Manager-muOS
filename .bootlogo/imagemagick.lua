-- Simple Lua wrapper for ImageMagick command-line tool
-- Since muOS already has ImageMagick installed, we can use it directly

local magick = {}
local fileUtils = require("fileUtils")
local zip = require("brimworks.zip")

-- Helper function to execute shell commands
local function execute_command(cmd)
    local handle = io.popen(cmd .. " 2>&1")
    local result = handle:read("*a")
    local success = handle:close()
    return success, result
end

-- Check if ImageMagick is available
function magick.is_available()
    local success, result = execute_command("magick --version")
    if success then
        -- Extract version information for debugging
        local version = result:match("Version: ImageMagick ([^\n]+)")
        if version then
            print("DEBUG: ImageMagick available - " .. version)
            
            -- Extract major version number
            local majorVersion = version:match("^(%d+)")
            if majorVersion then
                local major = tonumber(majorVersion)
                if major >= 7 then
                    print("DEBUG: ImageMagick version " .. major .. " is compatible")
                    return true
                else
                    print("DEBUG: ImageMagick version " .. major .. " is too old (need version 7+)")
                    return false
                end
            else
                print("DEBUG: Could not parse ImageMagick version number")
                return false
            end
        else
            -- Fallback: try to get just the first line if the version pattern doesn't match
            local firstLine = result:match("^([^\n]+)")
            if firstLine then
                print("DEBUG: ImageMagick available - " .. firstLine)
                print("DEBUG: Could not parse version number from output")
                return false
            else
                print("DEBUG: ImageMagick available (version info not parsed)")
                return false
            end
        end
    else
        print("DEBUG: ImageMagick not available - " .. (result or "Unknown error"))
        return false
    end
end

-- Get list of file extensions that can be converted to BMP
function magick.supportedFormats()
    -- Returns a list of file extensions that can be converted to BMP using ImageMagick
    return {
        -- Directly usable as bootlogo
        ".bmp",
        -- Other common image formats
        ".png", ".jpg", ".jpeg", ".jpe", ".gif", ".tga", ".webp", ".ico", ".cur",
        -- Raw/RGB formats (removed - require dimension specification)
        -- ".rgb", ".rgba", ".bgr", ".bgra", ".gray", ".cmyk",
        -- Portable formats
        ".ppm", ".pgm", ".pbm", ".pnm",
        -- Other formats
        ".sgi", ".sun", ".ras", ".pcx", ".xpm", ".psd", ".tiff", ".tif"
    }
end

-- Convert any image format to BMP
function magick.convert_to_bmp(input_path, output_path, output_width, output_height)
    print("DEBUG: Converting image to BMP: " .. input_path .. " → " .. output_path)
    print("DEBUG: Resizing to: " .. output_width .. "x" .. output_height)
    local file_ext = input_path:match("%.([^%.]+)$"):lower()
    local cmd = nil
    if file_ext == "psd" then
        cmd = string.format('convert "%s"[0] -flatten -resize %dx%d -format BMP "%s"', input_path, output_width, output_height, output_path)
    else
        cmd = string.format('convert "%s" -resize %dx%d -format BMP "%s"', input_path, output_width, output_height, output_path)
    end
    return execute_command(cmd)
end

function magick.generatePreviewCanvas(input_path, width, height)
    -- Try to load the image
    print("DEBUG: Attempting to load image from path: " .. input_path)       
        
    -- Create thumbnail using ImageMagick and save it next to LÖVE executable
    local success, image
    
    -- Get the directory where LÖVE is running from
    local love_dir = love.filesystem.getSource()
    local thumbnail_filename = "preview_" .. os.time() .. ".jpg"
    local thumbnail_path = love_dir .. "/" .. thumbnail_filename

    print("DEBUG: Creating thumbnail at: " .. thumbnail_path)

    local file_ext = input_path:match("%.([^%.]+)$"):lower()

    if file_ext == "psd" then
        -- PSD files need special handling: select first layer [0] and flatten
        magick_cmd = string.format("convert '%s'[0] -flatten -resize %dx%d -quality 85 '%s' 2>/dev/null", 
            input_path, width, height, thumbnail_path)
    else
        -- Standard formats: direct conversion to JPEG with quality setting
        magick_cmd = string.format("convert '%s' -resize %dx%d -quality 85 '%s' 2>/dev/null", 
            input_path, width, height, thumbnail_path)
    end

    --local cmd = string.format('magick "%s" -resize "%dx%d^" -gravity center -extent %dx%d "%s"', 
    --                          input_path, width, height, width, height, output_path)
    
    print("DEBUG: ImageMagick command: " .. magick_cmd)

    local magick_success = os.execute(magick_cmd)
    if magick_success then
        -- Check if file exists using fileUtils
        if fileUtils.fileExists(thumbnail_path) then
            success, image = pcall(love.graphics.newImage, thumbnail_filename)
            -- Clean up the temporary file
            local delete_result = fileUtils.removeFile(thumbnail_path)
            if delete_result then
                print("DEBUG: Temporary thumbnail deleted successfully")
            else
                print("DEBUG: Failed to delete temporary thumbnail")
            end

            if success and image then
                print("DEBUG: Successfully loaded thumbnail into Love2D")
                -- Create a scaled thumbnail using LÖVE's canvas system
                local canvas = love.graphics.newCanvas(width, height)
                love.graphics.setCanvas(canvas)
                love.graphics.clear() -- Clears canvas with transparent background

                -- Calculate scaling to fit the preview area while maintaining aspect ratio
                local imgWidth, imgHeight = image:getDimensions()
                local scaleX = width / imgWidth
                local scaleY = height / imgHeight
                local scale = math.min(scaleX, scaleY)
                
                -- Calculate position to center the image
                local drawWidth = imgWidth * scale
                local drawHeight = imgHeight * scale
                local drawX = (width - drawWidth) / 2
                local drawY = (height - drawHeight) / 2
                
                -- Draw the image scaled to fit the preview area
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.draw(image, drawX, drawY, 0, scale, scale)

                love.graphics.setCanvas()
                return canvas
            else
                print("DEBUG: Failed to load thumbnail into Love2D: " .. tostring(image))
            end
        else
            print("DEBUG: Thumbnail file does not exist after ImageMagick conversion")
        end
    else
        print("DEBUG: Failed to create thumbnail with ImageMagick")
    end
    
    return nil
end

function magick.generateThemePreviewCanvas(input_path, width, height, currentResolution, bootlogoFilename)
    -- Try to load the theme
    print("DEBUG: Attempting to load theme from path: " .. input_path)
    
    -- Check if the theme file exists
    if not fileUtils.fileExists(input_path) then
        print("DEBUG: Theme file does not exist: " .. input_path)
        return nil
    end
    
    -- Extract the .bmp file of the current resolution from the theme
    local fileToFind = currentResolution .. "/image/" .. bootlogoFilename

    print("DEBUG: Extracting .bmp file from theme: " .. fileToFind)

    local zipFile, error = zip.open(input_path)
    if not zipFile then
        print("DEBUG: Failed to open theme archive: " .. (error or "Unknown error"))
        return nil
    end

    local bmpFile = zipFile:open(fileToFind)
    if not bmpFile then
        print("DEBUG: Failed to find preview .bmp file in theme: " .. fileToFind)
        zipFile:close()
        return nil
    end

    local fileSize = zipFile:stat(fileToFind).size
    local bmpFileData = bmpFile:read(fileSize)
    bmpFile:close()
    zipFile:close()

    -- Create FileData from the raw BMP data
    local fileData = love.filesystem.newFileData(bmpFileData, "theme_preview.bmp")
    
    local imageDataLoadSuccess, imageData = pcall(love.image.newImageData, fileData)
    if not imageDataLoadSuccess then
        print("DEBUG: Failed to create love2d image data from bmp file data")
        fileData:release()
        return nil
    end

    local imageLoadSuccess, image = pcall(love.graphics.newImage, imageData)
    if not imageLoadSuccess then
        print("DEBUG: Failed to create love2d graphics image from image data")
        fileData:release()
        imageData:release()
        return nil
    end
    fileData:release()
    imageData:release()

    print("DEBUG: Successfully loaded thumbnail into Love2D")
    -- Create a scaled thumbnail using LÖVE's canvas system
    local canvas = love.graphics.newCanvas(width, height)
    love.graphics.setCanvas(canvas)
    love.graphics.clear() -- Clears canvas with transparent background

    -- Calculate scaling to fit the preview area while maintaining aspect ratio
    local imgWidth, imgHeight = image:getDimensions()
    local scaleX = width / imgWidth
    local scaleY = height / imgHeight
    local scale = math.min(scaleX, scaleY)
    
    -- Calculate position to center the image
    local drawWidth = imgWidth * scale
    local drawHeight = imgHeight * scale
    local drawX = (width - drawWidth) / 2
    local drawY = (height - drawHeight) / 2
    
    -- Draw the image scaled to fit the preview area
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(image, drawX, drawY, 0, scale, scale)

    love.graphics.setCanvas()
    return canvas
end

return magick
