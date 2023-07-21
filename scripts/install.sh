#!/usr/bin/env bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
PRINTING_HOME="${PRINTING_HOME:-$HOME}"

SOURCE_DIR="$(dirname $SCRIPT_DIR)"
CONFIG_DIR="${CONFIG_DIR:-$PRINTING_HOME/printer_data/config}"

# Check if the mainsail-config directory exists and hasn't (yet) been linked
if [ -d "$PRINTING_HOME/mainsail-config" ]; then
    if [ ! -L "$SOURCE_DIR/v2/klipper/mainsail.cfg" ]; then
        echo -n "[FIX] Linking mainsail-config to klipper config... "
        ln -s "$PRINTING_HOME/mainsail-config/client.cfg" "$SOURCE_DIR/v2/klipper/mainsail.cfg" && echo "OK" || echo "FAILED"
    else
        echo "[OK] mainsail-config already linked to klipper config"
    fi
fi

# Check if the moonraker-timelapse directory exists and hasn't (yet) been linked
if [ -d "$PRINTING_HOME/moonraker-timelapse" ]; then
    if [ ! -L "$SOURCE_DIR/v2/klipper/timelapse.cfg" ]; then
        echo -n "[FIX] Linking moonraker-timelapse to klipper config... "
        ln -s "$PRINTING_HOME/moonraker-timelapse/klipper_macro/timelapse.cfg" "$SOURCE_DIR/v2/klipper/timelapse.cfg" && echo "OK" || echo "FAILED"
    else
        echo "[OK] moonraker-timelapse already linked to klipper config"
    fi
fi

# Check if the klipper config directory exists and hasn't (yet) been linked
# if so, back it up and then replace it with a symlink
if [ ! -L "$CONFIG_DIR" ]; then
    if [ -d "$CONFIG_DIR" ]; then
        echo -n "[FIX] Backing up existing klipper config... "
        mv "$CONFIG_DIR" "${CONFIG_DIR}_backup" && echo "OK" || echo "FAILED"
    fi

    echo -n "[FIX] Linking klipper config... "
    ln -s "$SOURCE_DIR/v2/klipper" "$CONFIG_DIR" && echo "OK" || echo "FAILED"
else
    echo "[OK] klipper config already linked"
fi

if [ ! -f "$SOURCE_DIR/v2/klipper/printer.cfg" ]; then
    echo -n "[FIX] Creating printer.cfg... "
    cp "$SOURCE_DIR/v2/klipper/printer.cfg.example" "$SOURCE_DIR/v2/klipper/printer.cfg" && echo "OK" || echo "FAILED"
    echo "Remember to modify printer.cfg to match your printer's configuration if changes are required."
fi

echo "[OK] Setup complete"