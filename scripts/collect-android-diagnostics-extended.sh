#!/usr/bin/env bash
# Project: Crankshaft
# Extended diagnostic script to collect logs for Android Auto / AASDK USB issues
# Usage: sudo ./scripts/collect-android-diagnostics-extended.sh [--enable-debug] [--revert-debug] [--component=aa|all] [output-dir]

set -uuo pipefail

ENABLE_DEBUG=0
REVERT_DEBUG=0
COMPONENT=all
OUTDIR=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --enable-debug)
      ENABLE_DEBUG=1; shift ;;
    --revert-debug)
      REVERT_DEBUG=1; shift ;;
    --component=*)
      COMPONENT="${1#*=}"; shift ;;
    --component)
      COMPONENT="$2"; shift 2 ;;
    --help|-h)
      echo "Usage: $0 [--enable-debug] [--revert-debug] [--component=aa|all] [output-dir]"; exit 0 ;;
    *)
      if [ -z "$OUTDIR" ]; then OUTDIR="$1"; else echo "Unknown arg: $1"; exit 1; fi; shift ;;
  esac
done

if [ -z "$OUTDIR" ]; then
  OUTDIR="$HOME/crankshaft-diagnostics-$(date +%s)"
fi

mkdir -p "$OUTDIR"
cd "$OUTDIR" || exit 1

echo "Collecting diagnostics into: $OUTDIR" >&2

# Helper: enable debug drop-ins for crankshaft-core and crankshaft-ui
enable_debug() {
  echo "Enabling debug systemd drop-ins (AASDK/Crankshaft/Qt)..." >&2
  for svc in crankshaft-core crankshaft-ui; do
    DST_DIR="/etc/systemd/system/${svc}.service.d"
    sudo mkdir -p "$DST_DIR"
    # Backup existing drop-in if present
    if [ -f "$DST_DIR/99-crankshaft-debug.conf" ]; then
      sudo cp "$DST_DIR/99-crankshaft-debug.conf" "$OUTDIR/${svc}.99-crankshaft-debug.conf.bak" || true
    fi
    cat > /tmp/99-crankshaft-debug.conf <<'EOF'
[Service]
Environment="AASDK_LOG_LEVEL=DEBUG"
Environment="CRANKSHAFT_LOG_LEVEL=DEBUG"
Environment="QT_DEBUG_PLUGINS=1"
Environment="QT_LOGGING_RULES=*=true"
EOF
    sudo mv /tmp/99-crankshaft-debug.conf "$DST_DIR/99-crankshaft-debug.conf"
  done
  sudo systemctl daemon-reload
  sudo systemctl restart crankshaft-core crankshaft-ui || true
}

revert_debug() {
  echo "Reverting debug drop-ins (restore backups if available)..." >&2
  for svc in crankshaft-core crankshaft-ui; do
    DST_DIR="/etc/systemd/system/${svc}.service.d"
    if [ -f "$OUTDIR/${svc}.99-crankshaft-debug.conf.bak" ]; then
      echo "Restoring backup for $svc" >&2
      sudo cp "$OUTDIR/${svc}.99-crankshaft-debug.conf.bak" "$DST_DIR/99-crankshaft-debug.conf"
    else
      echo "Removing debug drop-in for $svc" >&2
      sudo rm -f "$DST_DIR/99-crankshaft-debug.conf" || true
    fi
  done
  sudo systemctl daemon-reload
  sudo systemctl restart crankshaft-core crankshaft-ui || true
}

# Optionally enable debug logging
if [ "$ENABLE_DEBUG" -eq 1 ]; then
  enable_debug
fi
if [ "$REVERT_DEBUG" -eq 1 ]; then
  revert_debug
  echo "Revert complete; exiting." >&2
  exit 0
fi

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

# Decide which journals to collect based on component
JOURNAL_BG_PIDS=""
if [ "$COMPONENT" = "aa" ]; then
  echo "Collecting Android Auto (AA) focused logs" >&2
  sudo journalctl -u crankshaft-core -b --no-pager | grep -i -E "android|aasdk|androidauto|usb" > journal-android.txt &
  PID_JOURNAL_A=$!
  JOURNAL_BG_PIDS="$PID_JOURNAL_A"
else
  echo "Collecting full crankshaft-core journal" >&2
  sudo journalctl -u crankshaft-core -b --no-pager > journal-full.txt &
  PID_JOURNAL=$!
  sudo journalctl -u crankshaft-core -b --no-pager | grep -i -E "android|aasdk|androidauto|usb" > journal-android.txt &
  PID_JOURNAL_A=$!
  JOURNAL_BG_PIDS="$PID_JOURNAL $PID_JOURNAL_A"
fi

# dmesg and udev monitor
sudo dmesg -w > dmesg.log &
PID_DMESG=$!
udevadm monitor --udev --property > udev-monitor.log &
PID_UDEV=$!

# Track which background pids we started (so we can kill them cleanly)
BG_PIDS="$JOURNAL_BG_PIDS $PID_DMESG $PID_UDEV"

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
