-- Shahmir Khan August 11 2025
-- Bootlogo Manager v1.0.1 Window Configuration File
-- https://github.com/shahmir-k
-- https://linkedin.com/in/shahmir-k

function love.conf(t)
    t.window.title = "Bootlogo Manager"
    t.window.width = 640
    t.window.height = 480
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