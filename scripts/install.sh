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

# Setup the Prometheus exporter for Klipper. Its release assets carry the version in
# their name, which Moonraker's update_manager cannot match, so the version is pinned here.
KLIPPER_EXPORTER_VERSION="${KLIPPER_EXPORTER_VERSION:-0.16.0}"
if [ ! -d "$PRINTING_HOME/prometheus-klipper" ]; then
    echo -n "[FIX] Installing prometheus-klipper-exporter... "
    mkdir -p "$PRINTING_HOME/prometheus-klipper"
    cp -r "$SOURCE_DIR/services/prometheus-klipper-exporter/"* "$PRINTING_HOME/prometheus-klipper/" && echo "OK" || echo "FAILED"
    wget -O "$PRINTING_HOME/prometheus-klipper/prometheus-klipper-exporter-rpi-arm64" "https://github.com/scross01/prometheus-klipper-exporter/releases/download/v${KLIPPER_EXPORTER_VERSION}/prometheus-klipper-exporter-rpi-arm64-v${KLIPPER_EXPORTER_VERSION}" && echo "prometheus-klipper-exporter binary downloaded" || echo "FAILED to download prometheus-klipper-exporter binary"
    chmod +x "$PRINTING_HOME/prometheus-klipper/prometheus-klipper-exporter-rpi-arm64"
else
    echo "[OK] prometheus-klipper-exporter already installed"
fi

if [ ! -L "/etc/systemd/system/prometheus-klipper-exporter.service" ]; then
    echo -n "[FIX] Linking prometheus-klipper-exporter.service... "
    sudo ln -s "$SOURCE_DIR/services/prometheus-klipper-exporter/prometheus-klipper-exporter.service" "/etc/systemd/system/prometheus-klipper-exporter.service" && echo "OK" || echo "FAILED"
    sudo systemctl daemon-reload
    sudo systemctl enable prometheus-klipper-exporter.service
    sudo systemctl restart prometheus-klipper-exporter.service
else
    echo "[OK] prometheus-klipper-exporter.service already linked"
fi

# Caddy: the Caddyfile and the tracing drop-in come from this repository
if [ -d /etc/caddy ]; then
    if [ ! -L /etc/caddy/Caddyfile ]; then
        echo -n "[FIX] Linking Caddyfile... "
        sudo ln -sf "$SOURCE_DIR/networking/Caddyfile" /etc/caddy/Caddyfile && echo "OK" || echo "FAILED"
    else
        echo "[OK] Caddyfile already linked"
    fi
    if [ ! -L /etc/systemd/system/caddy.service.d/override.conf ]; then
        echo -n "[FIX] Linking caddy.service.d/override.conf... "
        sudo mkdir -p /etc/systemd/system/caddy.service.d
        sudo ln -sf "$SOURCE_DIR/services/caddy/override.conf" /etc/systemd/system/caddy.service.d/override.conf && echo "OK" || echo "FAILED"
        sudo systemctl daemon-reload
        sudo systemctl restart caddy
    else
        echo "[OK] caddy.service.d/override.conf already linked"
    fi
fi

echo "[OK] Setup complete"