# HeyBob BLE Foot-Traffic Beacon — scanner scripts

Experimental tooling for the BLE foot-traffic differentiator: Raspberry Pi units
that passively detect nearby phones to estimate booth/area foot traffic.

**Status (Jun 2026):** proof-of-concept / validation stage. Hardware: 2× Raspberry
Pi Zero 2 W (headless) + a CanaKit Pi 4 8GB as the dev/test bench. These scripts
are for the **validation question**: do passing phones actually show up on a passive
BLE scan, and how reliably?

## Scripts

| File | Lang | Notes |
|------|------|-------|
| `ble_scan.py` | Python + [bleak] | **Preferred.** Talks to BlueZ over D-Bus (the real API) — robust for long unattended runs. Python is preinstalled on Raspberry Pi OS. |
| `ble_scan.rb` | Ruby (stdlib) | Shells out to `bluetoothctl` and parses output. No gems, but Ruby isn't preinstalled (`sudo apt install ruby`). Kept for reference / quick pokes. |

Both do the same thing: log every detected BLE advertisement (timestamp, MAC,
RSSI, name) to a CSV, dedupe by MAC, and print a running unique count.

## Quick start (Python, on a Pi)

```bash
sudo apt update && sudo apt install -y python3-venv
python3 -m venv ~/ble-env
source ~/ble-env/bin/activate
pip install bleak
python ble_scan.py            # Ctrl-C to stop -> summary + CSV
```

## Reading the result

- **RSSI** is signal strength in dBm (closer to 0 = nearer; −50 ≈ close, −90 ≈ far).
- Hold your own phone next to the Pi first → it should appear with strong RSSI (proves the rig).
- Then let it run while phones walk past → count NEW devices over ~10 min.

## ⚠️ Honest caveat

The count is **distinct MAC addresses**, which is an **UPPER BOUND**, not a true
person count: phones randomize their BLE MAC (one phone → several MACs), and many
phones don't continuously advertise BLE. If passing phones show up weakly, **WiFi
probe-request sniffing** (Scapy / `tshark`) is likely the better signal — a
comparison script is the planned next step.

[bleak]: https://github.com/hbldh/bleak
