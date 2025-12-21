#!/usr/bin/env bash
# Project: Crankshaft
# Diagnostic script to collect logs for Android Auto / AASDK USB issues
# Usage: sudo ./scripts/collect-android-diagnostics.sh [output-dir]

set -u

OUTDIR=${1:-$HOME/crankshaft-diagnostics-$(date +%s)}
mkdir -p "$OUTDIR"
cd "$OUTDIR" || exit 1

echo "Collecting diagnostics into: $OUTDIR"

# Capture static information
echo "-- capture: uname, ps, mount, env" > meta.txt
uname -a >> meta.txt 2>&1
date --iso-8601=seconds >> meta.txt 2>&1
ps aux >> meta.txt 2>&1
mount >> meta.txt 2>&1

# Capture lsusb snapshots
echo "-- lsusb (before)" > lsusb-before.txt
lsusb >> lsusb-before.txt 2>&1
lsusb -t >> lsusb-before.txt 2>&1

# Start background captures (press ENTER after reproducing to stop)
# Journal - full
sudo journalctl -u crankshaft-core -b --no-pager > journal-full.txt &
PID_JOURNAL=$!
# Journal - filtered for Android/AASDK/USB
sudo journalctl -u crankshaft-core -b --no-pager | grep -i -E "android|aasdk|androidauto|usb" > journal-android.txt &
PID_JOURNAL_A=$!

# dmesg and udev monitor
sudo dmesg -w > dmesg.log &
PID_DMESG=$!
udevadm monitor --udev --property > udev-monitor.log &
PID_UDEV=$!

# Track which background pids we started (so we can kill them cleanly)
BG_PIDS="$PID_JOURNAL $PID_JOURNAL_A $PID_DMESG $PID_UDEV"

# Also capture current device nodes and permissions
ls -l /dev/bus/usb/*/* > usb-dev-nodes-before.txt 2>&1 || true
sudo lsof /dev/bus/usb/* > lsof-usb-before.txt 2>&1 || true

echo
echo "Background captures started. Plug the phone now. When finished reproducing, press ENTER to stop captures and package results."
read -r

# Give monitors a moment to flush
sleep 1

# Stop background captures
for pid in $BG_PIDS; do
  if kill -0 "$pid" 2>/dev/null; then
    kill "$pid" || true
    wait "$pid" 2>/dev/null || true
  fi
done

# Capture lsusb after reproduce
lsusb > lsusb-after.txt 2>&1
lsusb -t > lsusb-t-after.txt 2>&1
ls -l /dev/bus/usb/*/* > usb-dev-nodes-after.txt 2>&1 || true
sudo lsof /dev/bus/usb/* > lsof-usb-after.txt 2>&1 || true

# Copy journalctl filtered recent tail (helps small review)
sudo journalctl -u crankshaft-core -b --no-pager | tail -n 500 > journal-recent.txt

# Package results
TARBALL=${OUTDIR}.tgz
tar -czf "$TARBALL" -C "$(dirname "$OUTDIR")" "$(basename "$OUTDIR")"

echo
echo "Diagnostics captured and packaged: $TARBALL"
echo "Please upload or share this tarball when opening an issue."

exit 0
