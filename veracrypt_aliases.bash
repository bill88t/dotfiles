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
        if veracrypt -t -u "$device"; then
            sudo eject $(lsblk -no pkname "$device" | sed 's|^|/dev/|')
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
        if veracrypt -t -u "$device"; then
            return 0
        else
            echo "Failed, retrying.."
            sleep 1
        fi
    done
}
