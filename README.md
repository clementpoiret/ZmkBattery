# ZMK Battery

A DankMaterialShell bar widget for the central and peripheral battery levels of
a ZMK split keyboard.

The plugin finds a paired Bluetooth device by its configured name, discovers
its Battery Level characteristics through BlueZ, and distinguishes the
`central` value from ZMK's `Peripheral 0` battery proxy using the standard GATT
Characteristic User Description descriptor.

## Requirements

- DankMaterialShell 1.5 or newer
- BlueZ
- `bash`
- `busctl`
- `jq`

## Setup

1. Open **Settings → Plugins** and scan for plugins.
2. Enable **ZMK Battery**.
3. Add **ZMK Battery** to the DankBar layout.
4. Open the plugin settings and set **Keyboard name** to the exact Bluetooth
   name or alias shown by `bluetoothctl devices`.

The default keyboard name is `Corne-ish Zen`. The widget refreshes every 60
seconds by default; clicking it refreshes immediately. The displayed names for
the central and peripheral halves can be changed independently. Leave either
label empty to show only that half's percentage.

The settings page includes a copy button for this discovery command:

```bash
bluetoothctl devices
```

To expose both split battery levels, configure ZMK to fetch and proxy the
peripheral battery as described in the
[ZMK battery configuration guide](https://v0-3-branch.zmk.dev/docs/config/battery).

## Script usage

The underlying query can also be run directly:

```bash
./getBattery.sh "Corne-ish Zen"
```

You can alternatively set `ZMK_KEYBOARD_NAME`:

```bash
ZMK_KEYBOARD_NAME="Corne-ish Zen" ./getBattery.sh
```

Example output:

```text
central: 79% peripheral 0: 77%
```
