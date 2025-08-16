#!/bin/sh
# HELP: Manage custom bootlogo installation and removal
# ICON: bootlogo-manager
# GRID: Bootlogo Manager

#help,icon,grid are used by muOS to populate help message, app icon, and app name in the app grid

. /opt/muos/script/var/func.sh
# This command runs the func.sh script in the current shell context
# (FOR GOOSE NOT muOS PIXIE)
# This allows for various core muOS functions to be available in this script
# Some Key Functions:
# FRONTEND() - Control the frontend (start/stop/restart)
# EXEC_MUX() - Execute muOS modules
# GET_VAR() - Read configuration values
# SET_VAR() - Write configuration values
# LOG_INFO() - Logging functions
# SETUP_SDL_ENVIRONMENT() - Set up SDL environment
# Key Variables:
# MP="/opt/muos" - muOS installation path
# HOME="/root" - Home directory
# KIOSK_CONFIG - Kiosk configuration path
# DEVICE_CONTROL_DIR - Device control directory
# MUOS_LOG_DIR - Log directory

echo app >/tmp/ACT_GO # Let the frontend know to back to the app grid after the app exits

# Set the love directory environment variable
LOVEDIR="$(GET_VAR "device" "storage/rom/mount")/MUOS/application/Bootlogo Manager" 
# Set the gptokeyb binary path environment variable
GPTOKEYB="$(GET_VAR "device" "storage/rom/mount")/MUOS/emulator/gptokeyb/gptokeyb2" 
# Set the bin directory environment variable for love and various other supporting binaries
BINDIR="$LOVEDIR/bin" 

# Set the SDL game controller config file path environment variable
SDL_GAMECONTROLLERCONFIG_FILE="/usr/lib/gamecontrollerdb.txt"
# Set the LD_LIBRARY_PATH environment variable for the supporting binaries
LD_LIBRARY_PATH="$BINDIR/libs.aarch64:$LD_LIBRARY_PATH"
# Set the LUA_CPATH environment variable for the supporting binaries
LUA_CPATH="$BINDIR/libs.aarch64/?.so;;"
# Export the SDL_GAMECONTROLLERCONFIG_FILE, LD_LIBRARY_PATH, and LUA_CPATH environment variables
export SDL_GAMECONTROLLERCONFIG_FILE LD_LIBRARY_PATH LUA_CPATH

# Launcher
cd "$LOVEDIR" || exit # Change to the love directory

# This SET_VAR doesn't work and gives an error
#SET_VAR "SYSTEM" "FOREGROUND_PROCESS" "love" # Set the foreground process to love

if [ -t 0 ]; then # if being launched through ssh terminal for debug print statements
    echo "Terminal detected, running in terminal mode"
    echo ""
    # stop the frontend so the app and frontend don't fight over drawing to the screen
    echo "Looking for muxlaunch and frontend.sh processes to stop frontend"
    while pgrep muxlaunch >/dev/null || pgrep frontend.sh >/dev/null; do
        killall -9 muxlaunch frontend.sh
        sleep 1
    done
fi

# Run Application
$GPTOKEYB "love" & # Tell gptokeyb to watch love as the controller
"$BINDIR/love" . # Run the love executable

# Cleanup after application exit
if [ -t 0 ]; then
    echo "Application was running in terminal mode, restarting frontend"
    echo ""
    /opt/muos/script/mux/frontend.sh >/dev/null 2>&1 &  # Restart the frontend
fi
kill -9 "$(pidof gptokeyb2)" 2>/dev/null # Kill the gptokeyb process