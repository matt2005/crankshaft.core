# Android Auto — Quick Troubleshooting Guide

A short, practical checklist for diagnosing phone detection and Android Auto issues. For full, detailed steps see `docs/android_auto_troubleshooting.md`.

## Quick checklist

- Use a short, data-capable USB cable (avoid charge-only leads).
- Plug directly into the Pi host port; avoid unpowered hubs.
- Stop `adb` while testing: `adb kill-server`.
- Ensure the active host profile uses the real Android Auto service (`useMock: false`).
- Restart `crankshaft-core` after any profile/config change.
- Collect logs while reproducing the issue.

## Key commands

Tail kernel messages while plugging the phone:

```bash
sudo dmesg -w
# plug the phone and watch for new USB lines
```

List USB devices and check negotiated speed:

```bash
lsusb
lsusb -t
```

Check systemd logs for crankshaft-core (show recent messages):

```bash
sudo journalctl -u crankshaft-core -b -e
# or filter for Android/AASDK/USB messages:
sudo journalctl -u crankshaft-core -b -e | grep -i "android\|aasdk\|usb"
```

Enable verbose AASDK / Qt logging (temporarily):

```bash
# For interactive runs (example):
export AASDK_LOG_LEVEL=DEBUG
QT_LOGGING_RULES="*=true" QT_DEBUG_PLUGINS=1 ./build/ui/crankshaft-ui

# For systemd override, create an override and restart services:
sudo systemctl edit crankshaft-core
# add under [Service]: Environment="AASDK_LOG_LEVEL=DEBUG"

sudo systemctl daemon-reload
sudo systemctl restart crankshaft-core
```

## Switch from mock to real Android Auto

Edit the active host profile (`/etc/crankshaft/profiles/host_profiles.json`) and set the AndroidAuto device `useMock` property to `false`. Example (safe, makes a backup):

```bash
sudo cp /etc/crankshaft/profiles/host_profiles.json /etc/crankshaft/profiles/host_profiles.json.bak
sudo sed -n '1,200p' /etc/crankshaft/profiles/host_profiles.json  # inspect
# edit with your editor, e.g.:
sudo nano /etc/crankshaft/profiles/host_profiles.json
# find the AndroidAuto device and set:
# "useMock": false
sudo systemctl restart crankshaft-core
sudo journalctl -u crankshaft-core -f | grep -i android
```

Or run the following Python one-liner to set `useMock=false` for all AndroidAuto devices and keep a backup:

```bash
sudo python3 - <<'PY'
import json,shutil
p='/etc/crankshaft/profiles/host_profiles.json'
shutil.copy2(p,p+'.bak')
j=json.load(open(p))
for item in j:
  for d in item.get('devices',[]):
    if d.get('name','').lower()=='androidauto':
      d['useMock']=False
json.dump(j,open(p,'w'),indent=2)
print('Updated profiles; backup saved to',p+'.bak')
PY
sudo systemctl restart crankshaft-core
```

## Quick diagnostics to capture when reproducing

- `dmesg -w` output while plugging the phone.
- `lsusb` and `lsusb -t` before and after plugging.
- `sudo journalctl -u crankshaft-core -b --no-pager` (include AASDK/Android messages).
- `udevadm monitor --udev --property` while plugging.

## Common causes and mitigations

- Unreliable cable/port or power dips: use a short, shielded cable and a stable 5V/3A supply.
- `adb` claiming the device: stop it (`adb kill-server`).
- Device re-enumerates (bus/dev path changes): try a different port and test with a powered hub.
- Permission issues: add a udev rule matching VID/PID/serial and reload udev.

Example udev rule (replace with real VID/PID):

```bash
echo 'SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", ATTR{idProduct}=="4ee7", MODE="0664", GROUP="crankshaft"' | sudo tee /etc/udev/rules.d/99-androidauto.rules
sudo udevadm control --reload
sudo udevadm trigger
```

## Next steps

- If the phone still fails to connect, gather the logs above and open an issue including: phone model and Android version, cable used, power arrangement, and the captured logs.
- For deep debugging, enable AASDK debug logging and share the `journalctl` output.

----

For the detailed troubleshooting guide and analysis, see `docs/android_auto_troubleshooting.md`.
