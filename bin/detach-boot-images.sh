#!/usr/bin/env bash
set -euo pipefail

image="$(realpath "${1:-./boot.img}")"

if [[ ! -e "$image" ]]; then
    printf 'Image not found: %s\n' "$image" >&2
    exit 1
fi

mapfile -t loop_devices < <(
    sudo losetup --associated "$image" |
        cut -d: -f1
)

if (( ${#loop_devices[@]} == 0 )); then
    printf 'No loop devices are attached to %s\n' "$image"
    exit 0
fi

for loop_device in "${loop_devices[@]}"; do
    printf 'Detaching %s from %s\n' "$loop_device" "$image"
    sudo losetup --detach "$loop_device"
done