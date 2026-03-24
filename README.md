# JACKASS
Jack of all trades Advanced Spec Sheet. A terminal-based hardware intelligence tool for Linux enthusiasts and system administrators — identify every component, surface CVE vulnerabilities, and verify patch status without leaving the shell.

Full hardware inventory — CPU topology, cache, microcode, GPU, storage, RAM DIMMs and network interfaces

DIMM-level RAM details — manufacturer, part number, serial number, speed and voltage via dmidecode

Storage device identification — HDD, SATA SSD and NVMe/M.2 with model, serial and SMART health status

Live CVE lookup via NIST NVD API — searches known vulnerabilities for detected hardware

CPU vulnerability status — Spectre, Meltdown, Retbleed and all kernel-reported mitigations

Temperature and fan monitoring — lm-sensors, /sys/class/thermal fallback, and NVIDIA GPU support

Rich OS fingerprinting — distro, variant, desktop environment, init system, uptime and package count

Interactive terminal UI — keyboard navigation, colour-coded status, per-category detail views

To get started, chmod +x jack-advanced-spec-sheet-[version]-installer.sh && sudo ./jack-advanced-spec-sheet-[version]-installer.sh

You can check dependencies prior to installation by running "sudo ./jack-advanced-spec-sheet-[version]-installer.sh -c

Run "sudo jackass".  Tool may take a few moments to load as it's gathering information.
