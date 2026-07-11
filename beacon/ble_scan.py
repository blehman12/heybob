#!/usr/bin/env python3
"""
ble_scan.py - passive BLE presence counter for foot-traffic testing.

Uses bleak (>=3.0), which talks to BlueZ over D-Bus (the real API - robust for
long, unattended runs, unlike scraping bluetoothctl text). Uses the modern
async-iterator API `scanner.advertisement_data()` (bleak 3.x).

------------------------------------------------------------------------------
SETUP on Raspberry Pi OS (tested on Debian trixie / Python 3.13 on a Pi Zero 2 W;
also works on Bookworm). Python 3 is preinstalled:
    sudo apt update && sudo apt install -y python3-venv
    python3 -m venv ~/ble-env
    source ~/ble-env/bin/activate
    pip install bleak

RUN (with the venv active):
    python ble_scan.py                 # logs to ble_log_<timestamp>.csv
    python ble_scan.py mylog.csv       # custom filename
    Ctrl-C to stop -> prints a summary.

If bluetoothctl show reports "Powered: no / PowerState: off-blocked", the radio
is rfkill-blocked. Enable it once:
    sudo rfkill unblock bluetooth
    bluetoothctl power on
No sudo is needed for scanning itself.
------------------------------------------------------------------------------
FIELD FINDINGS (Jul 10 2026, Pi Zero 2 W "bob1"):
  * Phones ARE detectable - a phone brought near appeared at strong RSSI
    (~-50 dBm). Passive BLE sensing of phones works.
  * BUT one phone = MULTIPLE rotating MACs. Toggling a phone's Bluetooth
    produced 2+ new "devices" at once (Resolvable Private Addresses). Phones
    advertise several services on separate, rotating private addresses.
  * THEREFORE the unique-MAC count OVERCOUNTS people - one human can register
    as several devices and climbs as addresses rotate. Treat the count as an
    UPPER BOUND, not a person count. A real deployment needs a dedup/correction
    layer (RSSI+timing clustering, calibrated factor, payload fingerprinting,
    or a WiFi-probe cross-check).
"""

import asyncio
import csv
import sys
from datetime import datetime, timezone

from bleak import BleakScanner

csv_path = sys.argv[1] if len(sys.argv) > 1 else \
    f"ble_log_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv"

seen = {}  # mac -> {first, last, hits, rssi, name}


def now_local():
    return datetime.now(timezone.utc).astimezone()


def print_summary():
    print("\n" + "=" * 64)
    print("SCAN SUMMARY")
    print(f"  Unique MAC addresses seen : {len(seen)}")
    if seen:
        first = min(v["first"] for v in seen.values())
        secs = int((now_local() - first).total_seconds())
        print(f"  Scan duration             : {secs} sec")
        rssis = [v["rssi"] for v in seen.values() if v["rssi"] is not None]
        if rssis:
            print(f"  Strongest RSSI (closest)  : {max(rssis)} dBm")
    print(f"  CSV saved to              : {csv_path}")
    print("  Count is an UPPER BOUND (phones rotate MACs).")
    print("=" * 64)


async def main():
    f = open(csv_path, "w", newline="")
    w = csv.writer(f)
    w.writerow(["timestamp", "event", "mac", "rssi", "name", "unique_so_far"])
    f.flush()
    print(f"Logging to {csv_path}")
    print("Scanning via bleak (BlueZ/D-Bus) ... (Ctrl-C to stop)")
    print("-" * 64)
    try:
        # Default is active scanning (solicits scan responses -> more devices).
        # For a stealthier / lower-power deploy later, try
        # BleakScanner(scanning_mode="passive").
        async with BleakScanner() as scanner:
            async for dev, adv in scanner.advertisement_data():
                mac = dev.address.upper()
                rssi = adv.rssi
                name = adv.local_name or getattr(dev, "name", None) or ""
                ts = now_local()
                tstr = ts.isoformat(timespec="seconds")
                if mac in seen:
                    rec = seen[mac]
                    rec["hits"] += 1
                    rec["last"] = ts
                    if rssi is not None:
                        rec["rssi"] = rssi
                    if name:
                        rec["name"] = name
                    w.writerow([tstr, "seen", mac, rssi, rec["name"], len(seen)])
                else:
                    seen[mac] = {"first": ts, "last": ts, "hits": 1,
                                 "rssi": rssi, "name": name}
                    w.writerow([tstr, "NEW", mac, rssi, name, len(seen)])
                    f.flush()
                    rs = str(rssi) if rssi is not None else "?"
                    print(f"[{ts:%H:%M:%S}] NEW  {mac}  RSSI={rs:<4} "
                          f"{name[:20]:<20} (unique: {len(seen)})")
    finally:
        f.flush()
        f.close()
        print_summary()


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        pass
