#!/usr/bin/env python3
"""
ble_scan.py - passive BLE presence counter for foot-traffic testing.

Uses bleak, which talks to BlueZ over D-Bus (the real API - robust for long,
unattended runs, unlike scraping bluetoothctl text).

------------------------------------------------------------------------------
SETUP on Raspberry Pi OS (Bookworm) - Python 3 is already installed:
    sudo apt update && sudo apt install -y python3-venv
    python3 -m venv ~/ble-env
    source ~/ble-env/bin/activate
    pip install bleak
(Bookworm blocks system-wide pip installs, so the venv is the clean way.)

RUN (with the venv active):
    python ble_scan.py                 # logs to ble_log_<timestamp>.csv
    python ble_scan.py mylog.csv       # custom filename
    Ctrl-C to stop -> prints a summary.

No sudo needed for scanning. If you hit a permission error, make sure the
service is up and you're in the bluetooth group:
    sudo systemctl enable --now bluetooth
    sudo usermod -aG bluetooth $USER     # then log out/in
------------------------------------------------------------------------------
HONESTY NOTE: this counts DISTINCT MAC ADDRESSES. Modern phones randomize their
BLE MAC, so one phone can appear as several MACs -> treat the unique count as an
UPPER BOUND on real devices, not a true person count. The goal of this test is
to learn whether passing phones show up AT ALL and how strong the signal is.
"""

import asyncio
import csv
import signal
import sys
from datetime import datetime, timezone

from bleak import BleakScanner

csv_path = sys.argv[1] if len(sys.argv) > 1 else \
    f"ble_log_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv"

seen = {}  # mac -> {first, last, hits, rssi, name}

csv_file = open(csv_path, "w", newline="")
writer = csv.writer(csv_file)
writer.writerow(["timestamp", "event", "mac", "rssi", "name", "unique_so_far"])
csv_file.flush()


def detection_callback(device, adv):
    """Fires for every BLE advertisement bleak receives."""
    mac = device.address.upper()
    rssi = adv.rssi                       # signal strength in dBm (closer = higher / less negative)
    name = adv.local_name or device.name or ""
    now = datetime.now(timezone.utc).astimezone()
    ts = now.isoformat(timespec="seconds")

    if mac in seen:
        rec = seen[mac]
        rec["last"] = now
        rec["hits"] += 1
        if rssi is not None:
            rec["rssi"] = rssi
        if name:
            rec["name"] = name
        writer.writerow([ts, "seen", mac, rssi, rec["name"], len(seen)])
    else:
        seen[mac] = {"first": now, "last": now, "hits": 1, "rssi": rssi, "name": name}
        writer.writerow([ts, "NEW", mac, rssi, name, len(seen)])
        csv_file.flush()
        rssi_str = str(rssi) if rssi is not None else "?"
        print(f"[{now:%H:%M:%S}] NEW  {mac}  RSSI={rssi_str:<4}  "
              f"{name[:20]:<20} (unique: {len(seen)})")


def print_summary():
    csv_file.flush()
    csv_file.close()
    print("\n" + "=" * 64)
    print("SCAN SUMMARY")
    print(f"  Unique MAC addresses seen : {len(seen)}")
    if seen:
        first = min(v["first"] for v in seen.values())
        secs = int((datetime.now(timezone.utc).astimezone() - first).total_seconds())
        print(f"  Scan duration             : {secs} sec")
        rssis = [v["rssi"] for v in seen.values() if v["rssi"] is not None]
        if rssis:
            print(f"  Strongest RSSI (closest)  : {max(rssis)} dBm")
    print(f"  CSV saved to              : {csv_path}")
    print("  Reminder: count is an UPPER BOUND (phones rotate MACs).")
    print("=" * 64)


async def main():
    print(f"Logging to {csv_path}")
    print("Starting BLE scan via bleak (BlueZ/D-Bus) ... (Ctrl-C to stop)")
    print("-" * 64)

    # Default is active scanning (solicits scan responses -> catches more devices).
    # For a stealthier / lower-power deploy later, try scanning_mode="passive".
    scanner = BleakScanner(detection_callback=detection_callback)
    await scanner.start()

    stop = asyncio.Event()
    loop = asyncio.get_running_loop()
    for sig in (signal.SIGINT, signal.SIGTERM):
        loop.add_signal_handler(sig, stop.set)
    await stop.wait()

    await scanner.stop()


if __name__ == "__main__":
    try:
        asyncio.run(main())
    finally:
        print_summary()
