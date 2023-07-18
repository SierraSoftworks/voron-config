#!/usr/bin/env bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
PRINTING_HOME="${PRINTING_HOME:-$HOME}"

SOURCE_DIR="$(dirname $SCRIPT_DIR)"
CONFIG_DIR="${CONFIG_DIR:-$PRINTING_HOME/printer_data/config}"

# Check if the mainsail-config directory exists and hasn't (yet) been linked
if [ -d "$PRINTING_HOME/mainsail-config" ]; then
    if [ ! -L "$SOURCE_DIR/v2/klipper/mainsail.cfg" ]; then
        ln -s "$PRINTING_HOME/mainsail-config/client.cfg" "$SOURCE_DIR/v2/klipper/mainsail.cfg"
    fi
fi

# Check if the klipper config directory exists and hasn't (yet) been linked
# if so, back it up and then replace it with a symlink
if [ ! -L "$CONFIG_DIR" ]; then
    if [ -d "$CONFIG_DIR" ]; then
        mv "$CONFIG_DIR" "${CONFIG_DIR}_backup"
    fi
    
    ln -s "$SOURCE_DIR/v2/klipper" "$CONFIG_DIR"
fi