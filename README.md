# Voron 3D Printer Configurations

This repository contains files related to my Voron 3D printer build. This includes
Klipper configurations, macros, and a range of helpful scripts and setup steps.

## Build Details
This configuration assumes that your build reflects my own, including the following:

 - [Voron 2.4 R2](https://github.com/VoronDesign/Voron-2) (350mm)
 - BigTreeTech Pi v1.4 + U2C v1.0
 - BigTreeTech Octopus v1.1
 - BigTreeTech EBB2240 v1.0
 - [Voron Tap (R8)](https://github.com/VoronDesign/Voron-Tap)
 - [Nevermore Micro v6](https://github.com/nevermore3d/Nevermore_Micro)
 - Klipper + Mainsail installed under `/printing`.
 - Tailscale for general network access

## Klipper Configuration
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

## Host Configuration
The BigTreeTech Pi starts off running the stock CB1 image, which I have then reconfigured
fairly substantially. This includes at least the following:

 - Moving all printing tooling and configuration to the `/printing` directory (from `/home/biqu`).
 - Migrating all printing agents to a new `printing` user, and creating a `printing` group for it.
 - Creating custom user accounts with membership to the `printing` group to better manage access permissions.
 - Installing Tailscale to provide network access to the printer, as well as secured SSH access.
 - Upgrading the OS to Debian 12 (Bookworm) to ensure we're running the latest stable packages.
 - Replacing NGINX with Caddy 2.0 as the reverse proxy for Mainsail, enabling the user of Tailscale+LetsEncrypt certs.
 - Setting up the `can0` network interface and configuring `systemd-network` to manage it.
