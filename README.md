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
 - BigTreeTech Pi v1.4 + U2C v1.0
 - BigTreeTech Octopus v1.1
 - BigTreeTech EBB2240 v1.0
 - BigTreeTech Smart Filament Sensor v1.1
 - [Voron Tap (R8)](https://github.com/VoronDesign/Voron-Tap)
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

### Host Configuration
The BigTreeTech Pi starts off running the stock CB1 image, which I have then reconfigured
fairly substantially. This includes at least the following:

 - Moving all printing tooling and configuration to the `/printing` directory (from `/home/biqu`).
 - Migrating all printing agents to a new `printing` user, and creating a `printing` group for it.
 - Creating custom user accounts with membership to the `printing` group to better manage access permissions.
 - Installing Tailscale to provide network access to the printer, as well as secured SSH access.
 - Upgrading the OS to Debian 12 (Bookworm) to ensure we're running the latest stable packages.
 - Replacing NGINX with Caddy 2.0 as the reverse proxy for Mainsail, enabling the user of Tailscale+LetsEncrypt certs.
 - Setting up the `can0` network interface and configuring `systemd-network` to manage it.

### Klipper Configuration
My Klipper configuration draws on a number of sources and integrates these into
a series of `[include]` statements, using a `_index.cfg` file to manage includes
within a number of subdirectories.

 - `controllers` contains configuration files for the various control boards in the system.
 - `displays` contains configuration files for the various displays/indicators in the system.
 - `effectors` contains configuration files for things that influence the environment (heaters, fans, motors etc).
 - `features` contains configuration files for various Klipper features used by the system.
 - `macros` contains various custom macros used by the system.
 - `config.cfg` contains the `_CLIENT_VARIABLES` overrides used to configure the system's behaviour.
 - `printer.cfg` contains the `[include]` statements for the aforementioned configs, as well as auto-generated overrides.

### Macros
 - `NEVERMORE SPEED=[0..1]` turns on the Nevermore at the requested speed (and resets any shutdown delay).
 - `NEVERMORE_OFF_AFTER SECONDS=900` turns off the Nevermore after the requested number of seconds (using delayed gcode).