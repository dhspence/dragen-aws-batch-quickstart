#!/bin/bash
set -eo pipefail
set -x

# Default values
## Override with environment variables (ex. 'export RAID_DEVICES="/dev/sda /dev/sdb"')
RAID_DEVICES="${RAID_DEVICES:-/dev/nvme1n1 /dev/nvme2n1 /dev/nvme3n1 /dev/nvme4n1}"
RAID_NAME="${RAID_NAME:-/dev/md0}"
MOUNT_POINT="${MOUNT_POINT:-/staging}"
WAIT_TIME="${WAIT_TIME:-3m}"

function log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

function convert_to_seconds() {
    local t="$1"
    case "$t" in
        *s) echo "${t%s}" ;;
        *m) echo $(( ${t%m} * 60 )) ;;
        *h) echo $(( ${t%h} * 3600 )) ;;
        *d) echo $(( ${t%d} * 86400 )) ;;
        *) echo "$t" ;;
    esac
}

function wait_for_path() {
    local path="$1"
    local timeout_sec=$(convert_to_seconds "$2")
    local count=0

    log "Waiting for $path (timeout: $((timeout_sec/60))m $((timeout_sec%60))s)..."
    while [ ! -e "$path" ] && [ $count -lt $timeout_sec ]; do
        sleep 1
        ((count++))
    done

    if [ -e "$path" ]; then
        log "$path is available."
        return 0
    else
        log "ERROR: $path did not appear within the timeout period."
        exit 1
    fi
}

function create_raid() {
    local raid_devices="$1"
    local raid_name="$2"
    local mount_point="$3"
    local wait_time="$4"

    log "Waiting for RAID devices to appear..."
    for dev in $raid_devices; do
        wait_for_path "$dev" "$wait_time"
    done

    log "Creating RAID0 array: $raid_name"
    echo "yes" | mdadm \
        --create "$raid_name" \
        --level=0 \
        --raid-devices=$(echo "$raid_devices" | wc -w) \
        $raid_devices \
        --force

    wait_for_path "$raid_name" "$wait_time"
    mkfs.ext4 -F "$raid_name"

    UUID=$(blkid -s UUID -o value "$raid_name")
    echo "UUID=$UUID $mount_point ext4 defaults,noatime 0 2" >> /etc/fstab

    mdadm --detail --scan >> /etc/mdadm.conf
}

function configure_existing_raid() {
    local existing_raid_device="/dev/$1"
    log "Configuring existing RAID array: $existing_raid_device"

    raid_info=$(mdadm --detail --scan --verbose "$existing_raid_device" || true)
    sorted_raid_info_devices=$(echo "$raid_info" | sed -n -e 's/^\s*devices=//p' | tr ',' '\n' | sort | tr '\n' ',')
    sorted_raid_devices=$(echo "$RAID_DEVICES" | tr ' ' '\n' | sort | tr '\n' ',')

    if [[ -z "$raid_info" ]] \
    || [[ "$raid_info" != *"raid0"* ]] \
    || [[ "$sorted_raid_info_devices" != "$sorted_raid_devices" ]]; then
        log "RAID array $existing_raid_device is not configured properly."
        exit 1
    fi
}

LOG_FILE="configure-raid.log"
exec > >(tee -a "$LOG_FILE") 2> >(tee -a "$LOG_FILE" >&2)

if [[ -f /proc/mdstat ]]; then
    existing_raid_device=$(grep -oE '^md[0-9]+' /proc/mdstat 2>/dev/null || true)
    if [[ -n "$existing_raid_device" ]]; then
        log "RAID array /dev/$existing_raid_device already exists."
        configure_existing_raid "$existing_raid_device"
    else
        create_raid "$RAID_DEVICES" "$RAID_NAME" "$MOUNT_POINT" "$WAIT_TIME"
    fi
else
    create_raid "$RAID_DEVICES" "$RAID_NAME" "$MOUNT_POINT" "$WAIT_TIME"
fi

mkdir -p "${MOUNT_POINT}/tmp"
chmod -R 777 "$MOUNT_POINT"
mount "$RAID_NAME" "$MOUNT_POINT"
log "RAID0 array mounted at: $MOUNT_POINT"

mv "$LOG_FILE" "$MOUNT_POINT/$LOG_FILE"
log "RAID setup and mount complete. Log saved to $MOUNT_POINT/$LOG_FILE"

cd "$MOUNT_POINT" || exit 1

if [[ $# -gt 0 ]]; then
    log "Executing passed command: $*"
    exec "$@"
else
    log "No command passed. Dropping into bash shell."
    exec bash
fi
