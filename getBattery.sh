#!/usr/bin/env bash

# Override with ZMK_KEYBOARD_NAME or pass the keyboard name as the first argument.
keyboard_name="${1:-${ZMK_KEYBOARD_NAME:-Corne-ish Zen}}"

battery_uuid="00002a19-0000-1000-8000-00805f9b34fb"
description_uuid="00002901-0000-1000-8000-00805f9b34fb"
central_path=
peripheral_0_path=

print_result() {
    printf 'central: %s peripheral 0: %s\n' "${1:---%}" "${2:---%}"
}

if ! command -v busctl >/dev/null || ! command -v jq >/dev/null; then
    print_result
    exit
fi

objects=$(
    busctl --system --json=short call \
        org.bluez \
        / \
        org.freedesktop.DBus.ObjectManager \
        GetManagedObjects \
        2>/dev/null
) || {
    print_result
    exit
}

device_path=$(
    jq -r --arg name "$keyboard_name" '
        .data[0]
        | [
            to_entries[]
            | select(
                .value["org.bluez.Device1"]? as $device
                | (($device.Alias.data? // "") == $name
                    or ($device.Name.data? // "") == $name)
            )
            | {
                path: .key,
                connected: (.value["org.bluez.Device1"].Connected.data? // false)
            }
        ]
        | sort_by(.connected)
        | last
        | .path // empty
    ' <<< "$objects"
)

if [[ -z $device_path ]]; then
    print_result
    exit
fi

while IFS=$'\t' read -r role path; do
    case $role in
        central)
            central_path=$path
            ;;
        "peripheral 0")
            peripheral_0_path=$path
            ;;
    esac
done < <(
    jq -r \
        --arg device "$device_path" \
        --arg battery_uuid "$battery_uuid" \
        --arg description_uuid "$description_uuid" '
        .data[0] as $objects
        | $objects
        | to_entries[]
        | select(.key | startswith($device + "/"))
        | select(
            (.value["org.bluez.GattCharacteristic1"].UUID.data? // "")
            == $battery_uuid
        )
        | .key as $characteristic
        | [
            $objects
            | to_entries[]
            | select(
                (.value["org.bluez.GattDescriptor1"].Characteristic.data? // "")
                == $characteristic
            )
            | select(
                (.value["org.bluez.GattDescriptor1"].UUID.data? // "")
                == $description_uuid
            )
        ] as $descriptions
        | [
            (if ($descriptions | length) == 0
                then "central"
                else "peripheral 0"
            end),
            $characteristic
        ]
        | @tsv
    ' <<< "$objects"
)

read_battery() {
    local value

    [[ -n $1 ]] || {
        printf '%s' '--%'
        return
    }

    value=$(
        busctl --system --timeout=3s --json=short call \
            org.bluez \
            "$1" \
            org.bluez.GattCharacteristic1 \
            ReadValue \
            'a{sv}' 0 \
            2>/dev/null |
            jq -er '
                .data[0]
                | select(length == 1)
                | .[0]
                | select(. >= 0 and . <= 100)
            '
    ) || {
        printf '%s' '--%'
        return
    }

    printf '%d%%' "$value"
}

print_result \
    "$(read_battery "$central_path")" \
    "$(read_battery "$peripheral_0_path")"
