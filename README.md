# Voron 3D Printer Configurations

This repository contains files related to my Voron 3D printer build. This includes
Klipper configurations, macros, and a range of helpful scripts and setup steps.

## Installation
The easiest way to setup this configuration is using the `moonraker.conf` file to install and manage updates.

```conf
[update_manager voron-config]
type: git_repo
path: ~/voron-config
origin: https://github.com/SierraSoftworks/voron-config.git
primary_branch: main
managed_services: klipper
```

Once this is done, you'll end up with a `voron-config` directory in your printer root, from which you can then symlink
to the `printer_data/config` directory. This should ensure that you consistently have the most recent config available
for your printer.

```bash
git clone https://github.com/SierraSoftworks/voron-config /printing/voron-config
/printing/voron-config/scripts/install.sh
```

## Details

### Printer Build
This configuration assumes that your build reflects my own, including the following:

 - [Voron 2.4 R2](https://github.com/VoronDesign/Voron-2) (350mm)
 - Raspberry Pi 5 (4GB RAM)
 - BigTreeTech TFT50 v2.1 running KlipperScreen
 - BigTreeTech U2C v2.1
 - BigTreeTech Octopus v1.1
 - BigTreeTech EBB2240 v1.0
 - BigTreeTech Smart Filament Sensor v1.1
 - PT1000 (2 wire) hotend thermistor
 - [Voron Tap (R8)](https://github.com/VoronDesign/Voron-Tap)
 - [~~Galileo 2~~](https://github.com/JaredC01/Galileo2) (switched back to Clockwork 2 due to flow-rate limitations)
 - [Nevermore Micro v6](https://github.com/nevermore3d/Nevermore_Micro)
 - Klipper + Mainsail installed under `/printing`.
 - Tailscale for secure remote access.

### Printer Hardware Configuration
 - Powering the EBB2240 using the HE3 port on the Octopus, allowing us to use the Octopus' built in relay to disable power remotely in an emergency.
    
    **NOTE**: This requires that you compile the Octopus firmware with the `PB11` GPIO pin configured to be on at controller startup. If you do
    not do this, Klipper will fail to start (waiting on the EBB2240 to start) and will not enable the pin. Careful that you don't connect a heater
    there, as it will be on at all times!

 - Using MOTOR_6 for the B stepper (and MOTOR_0 for the A stepper) to avoid needing to replace the Formbot kit cable which was too short to allow
   nice cable management.

 - Configuring the EBB2240 firmware to enable the `PA0` GPIO pin at startup (FAN1/heater fan) so that restarts don't run the risk of overheating the hotend.

 - Nevermore v6 connected to FAN4 on the Octopus (with jumpers set to 12V supply for Sunon Maglev 5015 fans).

 - Smart Filament Sensor connected to the `DIAG_7` port on the Octopus.

 - Chamber thermistor attached to `T0` on the Octopus (replacing the original hotend thermistor port).

 - LED chamber lighting connected to HE2 on the Octopus (24V supply at ~7-8W peak).

### Host Configuration
Running Raspbian 12 (Bookworm) on a Raspberry Pi 5 (4GB RAM) with a 32GB SD card. There are a range of changes
made to the way that this is installed relative to the "default" configuration.

 - Using Tailscale for remote access to the printer.
 - Have a dedicated `printing` user for all printing related tasks, home directory at `/printing`.
 - Have a dedicated `printing` group for all printing related tasks, management users are members of this group.
 - Installed Moonraker, Klipper, and Mainsail using Kiauh.
 - Using Caddy 2.0 as a reverse proxy for Mainsail, with Tailscale issued certs.
 - Using [Tailservice](https://sierrasoftworks.com/projects/tailservice) to expose Spoolman on Tailnet.
 - Configuring the `can0` network interface to run at 1Mbit/s with a 1k TX queue length.
 - Manually installed and configured `ustreamer` since Crowsnest doesn't (yet) support the RPi 5.
 - Installed and configured OpenTelemetry Collector to send realtime metrics and logs to Grafana.

### Klipper Firmware Configuration
To setup the Klipper firmware, you'll need to compile it for each of the boards in your system.
You do this by running `make menuconfig` and then selecting the following options (once saved,
you can run `make` to compile the firmware which will be placed in `out/klipper.bin`).

#### BTT Octopus
 - Enable extra low-level configuration options
 - Micro-processor architecture: `STM32`
 - Processor model: `STM32F446`
 - Bootloader offset: `32KiB`
 - Clock Reference: `12 MHz crystal`
 - Communication interface: `USB on PA11/PA12`
 - GPIO pins to set at micro-controller startup: `PB11`

 Once the firmware is built, place it on the SD card with the filename `firmware.bin` and insert it into the Octopus.
 A power cycle should then cause the Octopus to flash the firmware and reboot, at which point the firmware file will be
 renamed to `firmware.cur`.

#### BTT EBB2240
 - Enable extra low-level configuration options
 - Micro-processor architecture: `STM32`
 - Processor model: `STM32G0B1`
 - Bootloader offset: `8KiB`
 - Clock Reference: `8 MHz crystal`
 - Communication interface: `CAN bus on PB0/PB1`
 - CAN bus speed: `1 Mbit/s` (1000000)
 - GPIO pins to set at micro-controller startup: `PA0`

Once the firmware is built, flash it using the CANboot tooling by running the following command:

```bash
cd /printing/canboot/scripts
python3 flash_can.py -i can0 -q # Get the CAN ID of the EBB2240

# Once you have the ID, run the following command to flash the firmware (with the ID replaced if needed)
python3 ./flash_can.py -i can0 -f /printing/klipper/out/klipper.bin -u 9cf9505f7c7c
```

### Klipper Configuration
My Klipper configuration draws on a number of sources and integrates these into
a series of `[include]` statements, using a `_index.cfg` file to manage includes
within a number of subdirectories.

 - `controllers` contains configuration files for the various control boards in the system.
 - `displays` contains configuration files for the various displays/indicators in the system.
 - `effectors` contains configuration files for things that influence the environment (heaters, fans, motors etc).
 - `features` contains configuration files for various Klipper features used by the system.
 - `macros` contains various custom macros used by the system.
 - `config.cfg` contains the `_ConfigurationS` overrides used to configure the system's behaviour.
 - `printer.cfg` contains the `[include]` statements for the aforementioned configs, as well as auto-generated overrides.

### Macros
 - `NEVERMORE SPEED=[0..1]` turns on the Nevermore at the requested speed (and resets any shutdown delay).
 - `NEVERMORE_OFF_AFTER SECONDS=900` turns off the Nevermore after the requested number of seconds (using delayed gcode).

### Post Installation Printer Setup

#### PID Tuning
Once you've configured your printer, you'll need to tune the PID values for your hotend and bed.
You can do this using the following commands:

```
G28 # Home the printer
G0 X175 Y175 # Move to the center of the bed
G0 Z10 # Move the nozzle to 10mm above the bed

# Tune the bed PID at 110C
PID_CALIBRATE HEATER=heater_bed TARGET=110

# Tune the hotend PID at 250C (make sure you have an appropriate filament loaded, like ABS/ASA)
PID_CALIBRATE HEATER=extruder TARGET=250
```

#### Probe Calibration
Ensure that the probe has been correctly calibrated and the corresponding z_offset has been set in the Klipper config.
You can do this using the following commands:

```
G28 # Home the printer
G0 X175 Y175 # Move to the center of the bed
PROBE_CALIBRATE # Run the probe calibration routine
SAVE_CONFIG # Save the new z_offset value
```

#### Input Shaper Tuning
Once you've configured 