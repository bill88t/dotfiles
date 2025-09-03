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
        echo "Usage: verprivattach [-n name] -p password <device-or-container>"
        return 1
    fi

    local base="/run/media"
    local prefix="veracrypt"
    local mountpoint

    if [[ -z "$name" ]]; then
        local i=1
        while [[ -e "$base/$prefix$i" ]]; do
            i=$((i+1))
        done
        mountpoint="$base/$prefix$i"
    else
        mountpoint="$base/$name"
    fi

    echo "Mounting $device to $mountpoint.."

    if veracrypt -t --pim=0 --password="$password" --protect-hidden=no -k="" "$device" "$mountpoint"; then
        echo "Mounted hidden volume at $mountpoint."
    else
      echo "Failed to mount $device"
      return 1
    fi

    echo "Press Enter to unmount..."
    read -r _

    while true; do
        if veracrypt -t -u "$mountpoint"; then
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
        echo "Usage: verpubvattach [-n name] -p password <device-or-container>"
        return 1
    fi

    local base="/run/media"
    local prefix="veracrypt"
    local mountpoint

    if [[ -z "$name" ]]; then
        local i=1
        while [[ -e "$base/$prefix$i" ]]; do
            i=$((i+1))
        done
        mountpoint="$base/$prefix$i"
    else
        mountpoint="$base/$name"
    fi

    echo "Mounting $device to $mountpoint.."

    if veracrypt -t --pim=0 --password="$password" --protection-password="$hiddenpw" --protection-pim=0 --protection-keyfiles="" --protect-hidden=yes -k="" "$device" "$mountpoint"; then
        echo "Mounted outer volume at $mountpoint."
    else
        echo "Failed to mount $device"
        return 1
    fi

    echo "Press Enter to unmount..."
    read -r _

    while true; do
        if veracrypt -t -u "$mountpoint"; then
            return 0
        else
            echo "Failed, retrying.."
        fi
    done
}
