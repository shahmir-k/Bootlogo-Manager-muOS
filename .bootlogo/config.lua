-- Shahmir Khan August 11 2025
-- Bootlogo Manager v1.0.1 .bootlogo Configuration File
-- https://github.com/shahmir-k
-- https://linkedin.com/in/shahmir-k


local Config = {}

-- UI Configuration
Config.WINDOW_WIDTH = 640
Config.WINDOW_HEIGHT = 480
Config.BUTTON_WIDTH = 400
Config.BUTTON_HEIGHT = 30
Config.BUTTON_MARGIN = 20

-- Colors
Config.COLORS = {
    BACKGROUND = {0.078, 0.106, 0.173},
    HEADER_BG = {0.141, 0.141, 0.141},
    BUTTON_BG = {0.2, 0.2, 0.2},
    BUTTON_HOVER = {0.3, 0.3, 0.3},
    BUTTON_TEXT = {1, 1, 1},
    TEXT = {1, 1, 1},
    TEXT_SECONDARY = {0.8, 0.8, 0.8},
    DELETE_BUTTON_BG = {0.6, 0.1, 0.1},
    DELETE_BUTTON_HOVER = {0.8, 0.2, 0.2}
}

-- Button positions
Config.BUTTONS = {
    INSTALL = {
        x = (Config.WINDOW_WIDTH - Config.BUTTON_WIDTH) / 2,
        y = 60,
        width = Config.BUTTON_WIDTH,
        height = Config.BUTTON_HEIGHT,
        text = "Install Custom Bootlogo"
    },
    UNINSTALL = {
        x = (Config.WINDOW_WIDTH - Config.BUTTON_WIDTH) / 2,
        y = 60 + Config.BUTTON_HEIGHT + Config.BUTTON_MARGIN,
        width = Config.BUTTON_WIDTH,
        height = Config.BUTTON_HEIGHT,
        text = "Uninstall Custom Bootlogo"
    },
    INSTALL_THEME = {
        x = (Config.WINDOW_WIDTH - Config.BUTTON_WIDTH) / 2,
        y = 60 + (Config.BUTTON_HEIGHT + Config.BUTTON_MARGIN) * 2,
        width = Config.BUTTON_WIDTH,
        height = Config.BUTTON_HEIGHT,
        text = "Install Bootlogo to a Single Theme"
    },
    UNINSTALL_THEME = {
        x = (Config.WINDOW_WIDTH - Config.BUTTON_WIDTH) / 2,
        y = 60 + (Config.BUTTON_HEIGHT + Config.BUTTON_MARGIN) * 3,
        width = Config.BUTTON_WIDTH,
        height = Config.BUTTON_HEIGHT,
        text = "Uninstall Bootlogo from a Single Theme"
    },
    INSTALL_ALL_THEMES = {
        x = (Config.WINDOW_WIDTH - Config.BUTTON_WIDTH) / 2,
        y = 60 + (Config.BUTTON_HEIGHT + Config.BUTTON_MARGIN) * 4,
        width = Config.BUTTON_WIDTH,
        height = Config.BUTTON_HEIGHT,
        text = "Install Bootlogo to All Themes"
    },
    UNINSTALL_ALL_THEMES = {
        x = (Config.WINDOW_WIDTH - Config.BUTTON_WIDTH) / 2,
        y = 60 + (Config.BUTTON_HEIGHT + Config.BUTTON_MARGIN) * 5,
        width = Config.BUTTON_WIDTH,
        height = Config.BUTTON_HEIGHT,
        text = "Uninstall Bootlogo from All Themes"
    },
    DELETE = {
        x = (Config.WINDOW_WIDTH - Config.BUTTON_WIDTH) / 2,
        y = 60 + (Config.BUTTON_HEIGHT + Config.BUTTON_MARGIN) * 6,
        width = Config.BUTTON_WIDTH,
        height = Config.BUTTON_HEIGHT,
        text = "Delete Current Bootlogo"
    }
}

return Config 