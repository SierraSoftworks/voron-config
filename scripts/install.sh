#!/usr/bin/env bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
PRINTING_HOME="${PRINTING_HOME:-$HOME}"

SOURCE_DIR="$(dirname $SCRIPT_DIR)"
CONFIG_DIR="${CONFIG_DIR:-$PRINTING_HOME/printer_data/config}"

# Check if the mainsail-config directory exists and hasn't (yet) been linked
if [ -d "$PRINTING_HOME/mainsail-config" ]; then
    if [ ! -L "$SOURCE_DIR/klipper/mainsail.cfg" ]; then
        echo -n "[FIX] Linking mainsail-config to klipper config... "
        ln -s "$PRINTING_HOME/mainsail-config/client.cfg" "$SOURCE_DIR/klipper/mainsail.cfg" && echo "OK" || echo "FAILED"
    else
        echo "[OK] mainsail-config already linked to klipper config"
    fi
fi

# Check if the moonraker-timelapse directory exists and hasn't (yet) been linked
if [ -d "$PRINTING_HOME/moonraker-timelapse" ]; then
    if [ ! -L "$SOURCE_DIR/klipper/timelapse.cfg" ]; then
        echo -n "[FIX] Linking moonraker-timelapse to klipper config... "
        ln -s "$PRINTING_HOME/moonraker-timelapse/klipper_macro/timelapse.cfg" "$SOURCE_DIR/klipper/timelapse.cfg" && echo "OK" || echo "FAILED"
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
    ln -s "$SOURCE_DIR/klipper" "$CONFIG_DIR" && echo "OK" || echo "FAILED"
else
    echo "[OK] klipper config already linked"
fi

if [ ! -f "$SOURCE_DIR/klipper/printer.cfg" ]; then
    echo -n "[FIX] Creating printer.cfg... "
    cp "$SOURCE_DIR/klipper/printer.cfg.example" "$SOURCE_DIR/klipper/printer.cfg" && echo "OK" || echo "FAILED"
    echo "Remember to modify printer.cfg to match your printer's configuration if changes are required."
fi

# Setup go2rtc service
if [ ! -d "$PRINTING_HOME/go2rtc" ]; then
    echo -n "[FIX] Installing go2rtc... "
    mkdir -p "$PRINTING_HOME/go2rtc"
    cp -r "$SOURCE_DIR/services/go2rtc/"* "$PRINTING_HOME/go2rtc/" && echo "OK" || echo "FAILED"
    wget -O "$PRINTING_HOME/go2rtc/go2rtc_linux_arm64" "https://github.com/AlexxIT/go2rtc/releases/download/v1.9.4/go2rtc_linux_arm64" && echo "go2rtc binary downloaded" || echo "FAILED to download go2rtc binary"
    chmod +x "$PRINTING_HOME/go2rtc/go2rtc_linux_arm64"
else
    echo "[OK] go2rtc already installed"
fi

if [ ! -L "/etc/systemd/system/go2rtc.service" ]; then
    echo -n "[FIX] Linking go2rtc.service... "
    sudo ln -s "$SOURCE_DIR/services/go2rtc/go2rtc.service" "/etc/systemd/system/go2rtc.service" && echo "OK" || echo "FAILED"

    sudo systemctl daemon-reload
    sudo systemctl enable go2rtc.service
    sudo systemctl restart go2rtc.service
else
    echo "[OK] go2rtc.service already linked"
fi

# Setup tailservice
if [ ! -d "$PRINTING_HOME/spoolman-tailservice" ]; then
    echo -n "[FIX] Installing spoolman-tailservice... "
    mkdir -p "$PRINTING_HOME/spoolman-tailservice"
    cp -r "$SOURCE_DIR/services/spoolman-tailservice/"* "$PRINTING_HOME/spoolman-tailservice/" && echo "OK" || echo "FAILED"
    wget -O "$PRINTING_HOME/spoolman-tailservice/tailservice-linux-arm64" "https://github.com/SierraSoftworks/tailservice/releases/download/v1.0.6/tailservice-linux-arm64" && echo "tailservice binary downloaded" || echo "FAILED to download tailservice binary"
    chmod +x "$PRINTING_HOME/spoolman-tailservice/tailservice-linux-arm64"
else
    echo "[OK] spoolman-tailservice already installed"
fi

if [ ! -L "/etc/systemd/system/spoolman-tailservice.service" ]; then
    echo -n "[FIX] Linking spoolman-tailservice.service... "
    sudo ln -s "$SOURCE_DIR/services/spoolman-tailservice/spoolman-tailservice.service" "/etc/systemd/system/spoolman-tailservice.service" && echo "OK" || echo "FAILED"
    sudo systemctl daemon-reload
    sudo systemctl enable spoolman-tailservice.service
    sudo systemctl restart spoolman-tailservice.service
else
    echo "[OK] spoolman-tailservice.service already linked"
fi

echo "[OK] Setup complete"