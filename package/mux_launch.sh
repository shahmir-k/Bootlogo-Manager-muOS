#!/bin/sh
# HELP: Manage custom bootlogo installation and removal
# ICON: bootlogo-manager
# GRID: Bootlogo Manager

. /opt/muos/script/var/func.sh

echo app >/tmp/ACT_GO

LOVEDIR="$(GET_VAR "device" "storage/rom/mount")/MUOS/application/Bootlogo Manager"
GPTOKEYB="$(GET_VAR "device" "storage/rom/mount")/MUOS/emulator/gptokeyb/gptokeyb2"
BINDIR="$LOVEDIR/bin"

SDL_GAMECONTROLLERCONFIG_FILE="/usr/lib/gamecontrollerdb.txt"
LD_LIBRARY_PATH="$BINDIR/libs.aarch64:$LD_LIBRARY_PATH"
export SDL_GAMECONTROLLERCONFIG_FILE LD_LIBRARY_PATH

# Launcher
cd "$LOVEDIR" || exit
SET_VAR "SYSTEM" "FOREGROUND_PROCESS" "love"

# Run Application
$GPTOKEYB "love" &
"$BINDIR/love" .
kill -9 "$(pidof gptokeyb2)" 2>/dev/null 