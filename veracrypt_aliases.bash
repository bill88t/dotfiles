verprivattach() {
    local password=""
    local device=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--password)
            password="$2"
            shift 2
            ;;
        -*)
            echo "Unknown option: $1" >&2
            return 1
            ;;
        *)
            device="$1"
            shift
            ;;
        esac
    done

    if [[ -z "$device" || -z "$password" ]]; then
        echo "Usage: verprivattach -p password <device-or-container>"
        return 1
    fi

    local base="/run/media"
    local prefix="veracrypt"
    local mountpoint

    local i=1
    while [[ -e "$base/$prefix$i" ]]; do
        i=$((i+1))
    done
    mountpoint="$base/$prefix$i"

    echo "Mounting $device to $mountpoint.."

    if veracrypt -t --pim=0 --password="$password" --protect-hidden=no -k="" "$device" "$mountpoint" --fs-options="relatime,ssd,discard=async,compress=zstd,space_cache=v2"; then
        echo "Mounted hidden volume at $mountpoint."
    else
      echo "Failed to mount $device"
      return 1
    fi

    cd $mountpoint
    if [[ -f .loadsh ]]; then
        echo "Entering environment, exit to unmount.."
        /usr/bin/env -i "$SHELL" --rcfile <(echo "export HOME="$mountpoint";source .loadsh")
        echo "Unmounting.."
    else
        echo "Press Enter to unmount..."
        read -r _
    fi
    cd -

    while true; do
        sync "$mountpoint" || true
        if veracrypt -t -u "$device"; then
            parent="/dev/$(lsblk -no pkname "$device")"

            udisksctl power-off -b "$parent" >/dev/null 2>&1 || true
            eject "$parent" >/dev/null 2>&1 || true

            return 0
        fi
    done
}

verpubattach() {
    local password=""
    local hiddenpw=""
    local device=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--password)
            password="$2"
            shift 2
            ;;
        -P|--hidden-password)
            hiddenpw="$2"
            shift 2
            ;;
        -*)
            echo "Unknown option: $1" >&2
            return 1
            ;;
        *)
            device="$1"
            shift
            ;;
        esac
    done

    if [[ -z "$device" || -z "$password" ]]; then
        echo "Usage: verpubvattach -p password [-P hidden-password] <device-or-container>"
        return 1
    fi

    local base="/run/media"
    local prefix="veracrypt"
    local mountpoint

    local i=1
    while [[ -e "$base/$prefix$i" ]]; do
        i=$((i+1))
    done
    mountpoint="$base/$prefix$i"

    echo "Mounting $device to $mountpoint.."

    local cmd=(veracrypt -t --pim=0 --password="$password" -k="" "$device" "$mountpoint")

    if [[ -n "$hiddenpw" ]]; then
        cmd+=(--protection-password="$hiddenpw" --protection-pim=0 --protection-keyfiles="" --protect-hidden=yes)
    else
        cmd+=(--protect-hidden=no)
    fi

    if "${cmd[@]}"; then
        echo "Mounted volume at $mountpoint."
    else
        echo "Failed to mount $device"
        return 1
    fi

    echo "Press Enter to unmount..."
    read -r _

    while true; do
        sync "$mountpoint" || true
        if veracrypt -t -u "$device"; then
            parent="/dev/$(lsblk -no pkname "$device")"

            udisksctl power-off -b "$parent" >/dev/null 2>&1 || true
            eject "$parent" >/dev/null 2>&1 || true

            return 0
        fi
    done
}

# ---------------------------------------------------------------------------
# File-container mounts
#
# Everything below mounts a VeraCrypt *file container* that lives on some
# filesystem. That filesystem may or may not already be mounted; if it is
# not, it is mounted via udisks (looked up by PARTUUID through
# /dev/disk/by-partuuid). The container path itself is arbitrary — it just
# has to be valid once the filesystem is mounted.
#
# On unmount, the filesystem is unmounted ONLY if we mounted it. If it was
# already mounted before us, it is left alone.
# ---------------------------------------------------------------------------

# _verfile_mount
#
# Internal engine for the file-container functions.
#
# Usage:
#   _verfile_mount <container_path> <partuuid> <password> [hidden_password]
_verfile_mount() {
    local container="$1"
    local partuuid="$2"
    local password="$3"
    local hiddenpw="$4"

    if [[ -z "$container" || -z "$password" ]]; then
        echo "_verfile_mount: container path and password are required" >&2
        return 1
    fi

    local mounted_by_us=0
    local blockdev=""

    # Locate the backing block device, if a PARTUUID was given.
    if [[ -n "$partuuid" ]]; then
        blockdev="/dev/disk/by-partuuid/$partuuid"
        if [[ ! -e "$blockdev" ]]; then
            echo "Error: PARTUUID=$partuuid not found on this system" >&2
            return 1
        fi
        blockdev="$(readlink -f "$blockdev")"
    fi

    # If the container is not visible yet, mount its filesystem via udisks.
    if [[ ! -e "$container" ]]; then
        if [[ -z "$blockdev" ]]; then
            echo "Error: $container not found and no PARTUUID given to mount its filesystem" >&2
            return 1
        fi

        # Already mounted somewhere else? (udisksctl refuses to double-mount.)
        if findmnt -S "$blockdev" >/dev/null 2>&1; then
            echo "Filesystem of $blockdev is already mounted, but $container is missing." >&2
            return 1
        fi

        echo "Mounting filesystem $blockdev via udisks.."
        local mount_output
        if ! mount_output=$(udisksctl mount -b "$blockdev" 2>&1); then
            echo "Failed to mount $blockdev: $mount_output" >&2
            return 1
        fi
        mounted_by_us=1
        echo "$mount_output"

        # Wait for the container path to appear (filesystem settle).
        local waited=0
        while [[ ! -e "$container" ]]; do
            sleep 1
            waited=$((waited + 1))
            if [[ $waited -ge 15 ]]; then
                echo "Timeout: $container not found after mounting $blockdev" >&2
                udisksctl unmount -b "$blockdev" >/dev/null 2>&1 || true
                parent="/dev/$(lsblk -no pkname "$blockdev")"
                udisksctl power-off -b "$parent" >/dev/null 2>&1 || true
                return 1
            fi
        done
        echo "$container is available (waited ${waited}s)."
    fi

    # Pick a fresh veracrypt mountpoint, same scheme as the partition flow.
    local base="/run/media"
    local prefix="veracrypt"
    local mountpoint

    local i=1
    while [[ -e "$base/$prefix$i" ]]; do
        i=$((i+1))
    done
    mountpoint="$base/$prefix$i"

    echo "Mounting container $container to $mountpoint.."

    # Same password handling as verpubattach: outer password, optional
    # hidden-volume protection password.
    local cmd=(veracrypt -t --pim=0 --password="$password" -k="" "$container" "$mountpoint")

    if [[ -n "$hiddenpw" ]]; then
        cmd+=(--protection-password="$hiddenpw" --protection-pim=0 --protection-keyfiles="" --protect-hidden=yes)
    else
        cmd+=(--protect-hidden=no)
    fi

    if "${cmd[@]}"; then
        echo "Mounted container at $mountpoint."
    else
        echo "Failed to mount container $container"
        # If we mounted the filesystem for this, clean up after ourselves.
        if [[ $mounted_by_us -eq 1 ]]; then
            udisksctl unmount -b "$blockdev" >/dev/null 2>&1 || true
        fi
        return 1
    fi

    # Interaction phase: .loadsh environment if present, else press-enter.
    builtin cd "$mountpoint"
    if [[ -f .loadsh ]]; then
        echo "Entering environment, exit to unmount.."
        /usr/bin/env -i "$SHELL" --rcfile <(echo "export HOME=\"$mountpoint\";source .loadsh")
        echo "Unmounting.."
    else
        echo "Press Enter to unmount..."
        read -r _
    fi
    builtin cd - >/dev/null

    # Dismount loop, same as the partition flow.
    while true; do
        sync "$mountpoint" || true
        if veracrypt -t -u "$container"; then
            # Only unmount the backing filesystem if we mounted it.
            if [[ $mounted_by_us -eq 1 ]]; then
                udisksctl unmount -b "$blockdev" >/dev/null 2>&1 || true

                # Power off the parent device, same as the partition flow.
                parent="/dev/$(lsblk -no pkname "$blockdev")"
                udisksctl power-off -b "$parent" >/dev/null 2>&1 || true
                eject "$parent" >/dev/null 2>&1 || true
            else
                echo "Backing filesystem was already mounted, leaving it mounted."
            fi
            return 0
        fi
    done
}

# verpathattach
#
# Mounts a VeraCrypt file container. If the container path is not visible,
# the filesystem holding it is located by PARTUUID (via
# /dev/disk/by-partuuid) and mounted with udisks first.
#
# Usage:
#   verpathattach -p <password> [-u PARTUUID] /path/to/container
#   verpathattach -p 'hunter2' -u a1b2c3d4-e5f6-7890-abcd-ef1234567890 /run/media/bill88t/usb-disk/vol
#
# Options:
#   -p, --password    Password for the VeraCrypt volume
#   -u, --partuuid    PARTUUID of the partition holding the container's
#                     filesystem (required only if the path is not visible)
verpathattach() {
    local password=""
    local partuuid=""
    local container=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--password)
                password="$2"
                shift 2
                ;;
            -u|--partuuid)
                partuuid="$2"
                shift 2
                ;;
            -*)
                echo "Unknown option: $1" >&2
                return 1
                ;;
            *)
                container="$1"
                shift
                ;;
        esac
    done

    if [[ -z "$container" || -z "$password" ]]; then
        echo "Usage: verpathattach -p password [-u PARTUUID] /path/to/container"
        return 1
    fi

    _verfile_mount "$container" "$partuuid" "$password"
}

# verpathattachpub
#
# Same as verpathattach, but for public (decoy) volumes with optional
# hidden-volume protection.
#
# Usage:
#   verpathattachpub -p <password> [-P <hidden-password>] [-u PARTUUID] /path/to/container
#   verpathattachpub -p 'public' -P 'hidden' -u a1b2c3d4-e5f6-7890-abcd-ef1234567890 /run/media/bill88t/usb-disk/pubvol
verpathattachpub() {
    local password=""
    local hiddenpw=""
    local partuuid=""
    local container=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--password)
                password="$2"
                shift 2
                ;;
            -P|--hidden-password)
                hiddenpw="$2"
                shift 2
                ;;
            -u|--partuuid)
                partuuid="$2"
                shift 2
                ;;
            -*)
                echo "Unknown option: $1" >&2
                return 1
                ;;
            *)
                container="$1"
                shift
                ;;
        esac
    done

    if [[ -z "$container" || -z "$password" ]]; then
        echo "Usage: verpathattachpub -p password [-P hidden-password] [-u PARTUUID] /path/to/container"
        return 1
    fi

    _verfile_mount "$container" "$partuuid" "$password" "$hiddenpw"
}

# vdisk
#
# Creates a per-volume function (alias) that remembers the PARTUUID of the
# filesystem holding the container, the container's path on that
# filesystem, and the password(s). The generated function handles both the
# "filesystem already mounted" and "needs udisks mount" cases.
#
# Usage:
#   vdisk <name> <PARTUUID> <container_path> <password> [hidden_password]
#
# Parameters:
#   <name>            Name for the generated function
#   <PARTUUID>        PARTUUID of the partition holding the filesystem
#   <container_path>  Path of the veracrypt file once the filesystem is
#                     mounted (any arbitrary path, e.g. "/run/media/bill88t/TONK/backups/vol.vc")
#   <password>        Password for the VeraCrypt volume
#   [hidden_password] Optional hidden volume password (public mode)
#
# Example:
#   vdisk mysecret "a1b2c3d4-e5f6-7890-abcd-ef1234567890" "/run/media/bill88t/TONK/vol" "hunter2"
#   mysecret
#
#   vdisk mypub "a1b2c3d4-e5f6-7890-abcd-ef1234567890" "/mnt/pub.vc" "public" "hidden"
#   mypub
vdisk() {
    local name="$1"
    local partuuid="$2"
    local container="$3"
    local password="$4"
    local hiddenpw="$5"

    if [[ -z "$name" || -z "$partuuid" || -z "$container" || -z "$password" ]]; then
        echo "Usage: vdisk <name> <PARTUUID> <container_path> <password> [hidden_password]"
        echo "  Example: vdisk myvol a1b2c3d4-e5f6-7890-abcd-ef1234567890 /run/media/bill88t/TONK/vol hunter2"
        return 1
    fi

    # Quote every value safely for the generated function body.
    local q_partuuid q_container q_password q_hiddenpw
    printf -v q_partuuid '%q' "$partuuid"
    printf -v q_container '%q' "$container"
    printf -v q_password '%q' "$password"
    printf -v q_hiddenpw '%q' "${hiddenpw:-}"

    eval "
    $name() {
        _verfile_mount $q_container $q_partuuid $q_password ${hiddenpw:+$q_hiddenpw}
    }
    "
}

# verfileattach
#
# One-shot mount of a VeraCrypt file container: just a path and password(s).
# No PARTUUID lookup, no automatic filesystem mounting, no unmount of the
# backing filesystem — the container must already be visible.
#
# Usage:
#   verfileattach -p <password> [-P <hidden-password>] /path/to/container
#   verfileattach -p 'hunter2' /run/media/bill88t/TONK/vol.vc
#   verfileattach -p 'public' -P 'hidden' /mnt/pub.vc
#
# Options:
#   -p, --password         Password for the VeraCrypt volume
#   -P, --hidden-password  Password for the hidden volume (optional)
#
# If .loadsh exists in the mounted volume, enters an isolated shell;
# otherwise waits for Enter. Only the veracrypt volume itself is unmounted.
verfileattach() {
    local password=""
    local hiddenpw=""
    local container=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--password)
                password="$2"
                shift 2
                ;;
            -P|--hidden-password)
                hiddenpw="$2"
                shift 2
                ;;
            -*)
                echo "Unknown option: $1" >&2
                return 1
                ;;
            *)
                container="$1"
                shift
                ;;
        esac
    done

    if [[ -z "$container" || -z "$password" ]]; then
        echo "Usage: verfileattach -p password [-P hidden-password] /path/to/container"
        return 1
    fi

    if [[ ! -e "$container" ]]; then
        echo "Error: container $container not found" >&2
        return 1
    fi

    local base="/run/media"
    local prefix="veracrypt"
    local mountpoint

    local i=1
    while [[ -e "$base/$prefix$i" ]]; do
        i=$((i+1))
    done
    mountpoint="$base/$prefix$i"

    echo "Mounting container $container to $mountpoint.."

    local cmd=(veracrypt -t --pim=0 --password="$password" -k="" "$container" "$mountpoint")

    if [[ -n "$hiddenpw" ]]; then
        cmd+=(--protection-password="$hiddenpw" --protection-pim=0 --protection-keyfiles="" --protect-hidden=yes)
    else
        cmd+=(--protect-hidden=no)
    fi

    if "${cmd[@]}"; then
        echo "Mounted container at $mountpoint."
    else
        echo "Failed to mount container $container"
        return 1
    fi

    builtin cd "$mountpoint"
    if [[ -f .loadsh ]]; then
        echo "Entering environment, exit to unmount.."
        /usr/bin/env -i "$SHELL" --rcfile <(echo "export HOME=\"$mountpoint\";source .loadsh")
        echo "Unmounting.."
    else
        echo "Press Enter to unmount..."
        read -r _
    fi
    builtin cd - >/dev/null

    while true; do
        sync "$mountpoint" || true
        if veracrypt -t -u "$container"; then
            return 0
        fi
    done
}
