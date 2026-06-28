#!/usr/bin/env ruby
# frozen_string_literal: true
#
# ble_scan.rb — passive BLE presence counter for foot-traffic testing
# ---------------------------------------------------------------------
# Pure Ruby stdlib. Does NOT use a native BLE library — it drives BlueZ's
# own `bluetoothctl` and parses the stream. Works on Raspberry Pi OS.
#
# Setup (one time):
#   sudo apt update && sudo apt install -y ruby
#
# Run:
#   ruby ble_scan.rb                 # logs to ble_log_<timestamp>.csv
#   ruby ble_scan.rb mylog.csv       # custom file
#   Ctrl-C to stop -> prints a summary.
#
# If you get a permissions/"No default controller" error, either run with
# sudo, or add yourself to the bluetooth group:  sudo usermod -aG bluetooth $USER
# (then log out/in), and make sure the service is up:
#   sudo systemctl enable --now bluetooth
#
# IMPORTANT honesty note: this counts DISTINCT MAC ADDRESSES seen. Modern
# phones randomize their BLE MAC, so one phone can appear as several MACs.
# Treat the unique count as an UPPER BOUND, not a true person count. The
# point of this test is to learn whether passing phones show up AT ALL and
# how strong the signal is.

require "csv"
require "time"

csv_path = ARGV[0] || "ble_log_#{Time.now.strftime('%Y%m%d_%H%M%S')}.csv"

MAC_RE  = /([0-9A-F]{2}(?::[0-9A-F]{2}){5})/i
RSSI_RE = /RSSI:\s*(-?\d+)/i
# property keywords that follow a MAC but are NOT a device name
PROP_RE = /\A(RSSI|UUIDs?|ManufacturerData|ServiceData|TxPower|Connected|Paired|
              Trusted|Bonded|LegacyPairing|Modalias|Appearance|Icon|Class|
              ServicesResolved|WakeAllowed|AdvertisingFlags|AdvertisingData|
              Adapter|Alias|Blocked)\b/xi

seen = {} # mac => { first:, last:, hits:, rssi:, name: }

csv = CSV.open(csv_path, "w")
csv << %w[timestamp event mac rssi name unique_so_far]
csv.flush

puts "Logging to #{csv_path}"
puts "Starting BLE scan via bluetoothctl ... (Ctrl-C to stop)"
puts "-" * 64

at_exit do
  csv.flush rescue nil
  csv.close rescue nil
  puts "\n" + "=" * 64
  puts "SCAN SUMMARY"
  puts "  Unique MAC addresses seen : #{seen.size}"
  if seen.any?
    secs = (Time.now - seen.values.map { |v| v[:first] }.min).round
    puts "  Scan duration             : #{secs} sec"
    strongest = seen.values.map { |v| v[:rssi] }.compact.max
    puts "  Strongest RSSI (closest)  : #{strongest} dBm" if strongest
  end
  puts "  CSV saved to              : #{csv_path}"
  puts "  Reminder: count is an UPPER BOUND (phones rotate MACs)."
  puts "=" * 64
end

def strip_ansi(line)
  line.gsub(/\e\[[0-9;?]*[ -\/]*[@-~]/, "")
end

# Drive bluetoothctl with line-buffered output so we see devices live.
IO.popen(["stdbuf", "-oL", "bluetoothctl"], "r+") do |bt|
  bt.puts "power on"
  bt.puts "scan on"

  bt.each_line do |raw|
    line = strip_ansi(raw)
    m = line.match(MAC_RE)
    next unless m
    mac = m[1].upcase

    rssi = line[RSSI_RE, 1]&.to_i

    name = line[/Device\s+#{Regexp.escape(mac)}\s+(.+?)\s*\z/i, 1]
    name = nil if name && name.match?(PROP_RE)

    now = Time.now
    if (rec = seen[mac])
      rec[:last] = now
      rec[:hits] += 1
      rec[:rssi] = rssi if rssi
      rec[:name] = name if name && !name.empty?
      csv << [now.iso8601, "seen", mac, rssi, rec[:name], seen.size]
    else
      seen[mac] = { first: now, last: now, hits: 1, rssi: rssi, name: name }
      csv << [now.iso8601, "NEW", mac, rssi, name, seen.size]
      csv.flush
      printf("[%s] NEW  %s  RSSI=%-4s %-20s (unique: %d)\n",
             now.strftime("%H:%M:%S"), mac, (rssi || "?").to_s, name.to_s, seen.size)
    end
  end
end
