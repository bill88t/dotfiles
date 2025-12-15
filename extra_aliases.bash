alias nht='nhentai --no-html -t $(getconf _NPROCESSORS_ONLN) --id'

tempvenv() {
    local venv_dir
    venv_dir=$(mktemp -d -t tempvenv-XXXXXX)
    echo "Created temporary venv directory $venv_dir"
    python -m venv "$venv_dir"
    echo "Setup complete"

    (source "$venv_dir/bin/activate" && bash --rcfile <(cat ~/.bashrc; echo 'PS1="('$venv_dir') $PS1"'))

    if [[ -d "$venv_dir" && -f "$venv_dir/bin/activate" ]]; then
        echo "Cleaning up.."
        rm -rf "$venv_dir"
    else
        echo "Warning: Skipping removal, unexpected venv path: $venv_dir"
    fi
}

alias lsgovernor="cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor"

cpu_freqs() {
  for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
    core=$(basename "$cpu")
    freq=$(<"$cpu/cpufreq/scaling_cur_freq")
    printf "%s: %.1f MHz\n" "$core" "$(bc <<< "scale=1; $freq / 1000")"
  done
}

alias jf="journalctl -f"
alias jb="journalctl -b"

mv_subdirfiles_to_pwd() {
    local cwd
    cwd=$(realpath .)

    # Safety filter
    local depth=$(( $(tr -cd '/' <<< "$cwd" | wc -c) ))
    if (( depth < 3 )); then
        echo "ERROR: Directory too shallow ($cwd) — likely unsafe." >&2
        read -rp "Type 'yes' to continue: " confirm
        [[ "$confirm" == "yes" ]] || return 1
    fi

    # Check for files to move
    if ! find . -mindepth 2 -type f -print -quit | grep -q .; then
        echo "No files found in subdirectories." >&2
        return 0
    fi

    echo "Dry run: would move the following files to $cwd"
    find . -mindepth 2 -type f -exec printf '  %s\n' {} +
    echo
    read -rp "Proceed with actual move? (yes/no) " confirm
    [[ "$confirm" == "yes" ]] || { echo "Aborted."; return 0; }

    # Move files with collision handling
    find . -mindepth 2 -type f | while IFS= read -r f; do
        local base target name ext n
        base=$(basename "$f")

        if [[ "$base" == *.* && "$base" != .* ]]; then
            name="${base%.*}"
            ext="${base##*.}"
        elif [[ "$base" == .*.* ]]; then
            # Hidden file with extension (e.g., .git.txt)
            name="${base%.*}"
            ext="${base##*.}"
        else
            # No extension or just hidden file
            name="$base"
            ext=""
        fi

        target="$cwd/$base"
        n=1
        while [[ -e "$target" ]]; do
            if [[ -n "$ext" ]]; then
                target="$cwd/${name} (${n}).${ext}"
            else
                target="$cwd/${name} (${n})"
            fi
            ((n++))
        done

        mv "$f" "$target"
    done

    echo "Done: All subdirectory files safely moved into $cwd."
    find . -type d -empty -delete
    echo "Cleanup: Removed all subdirs."
}

alias wifipass='nmcli dev wifi show-password'

alias lswakeups='grep . /sys/bus/usb/devices/*/power/wakeup'

alias mdl="megatools dl"

nopen() {
    sh -c "nautilus \"$1\" > /dev/null 2>&1" &
    disown
}

dopen() {
    dolphin "${1:-$PWD}" >/dev/null 2>&1 &
    disown
}

# alias kml="kemono-scraper --cookie ~/git/dotfiles/cookies.txt --link"
alias kml="kemono-scraper --link"

alias cookies="yt-dlp --cookies cookies.txt --cookies-from-browser firefox"

zcomp() {
  if [ $# -eq 0 ]; then
    echo "Usage: zstd_compress_rm file_or_dir1 [file_or_dir2 ...]"
    return 1
  fi

  for item in "$@"; do
    if [ -f "$item" ]; then
      # Regular file
      zstd -20 --ultra -T0 --long=31 "$item"
      if [ $? -eq 0 ]; then
        echo "Successfully compressed file $item, removing original"
        rm "$item"
      else
        echo "Failed to compress file $item, keeping original"
      fi
    elif [ -d "$item" ]; then
      # Directory - create a tar.zst archive
      output_file="${item%/}.tar.zst"
      tar -cf - "$item" | zstd -20 --ultra -T0 --long=31 > "$output_file"
      if [ $? -eq 0 ]; then
        echo "Successfully compressed directory $item to $output_file, removing original"
        rm -r "$item"
      else
        echo "Failed to compress directory $item, keeping original"
      fi
    else
      echo "Warning: $item is not a file or directory, skipping"
    fi
  done
}

zarchive() {
  if [ $# -lt 2 ]; then
    echo "Usage: zarchive archive_name.tar.zst file_or_dir1 [file_or_dir2 ...]"
    return 1
  fi

  output_file="$1"
  shift

  # Store original files in an array for later removal
  original_items=("$@")

  # Create a tar archive and pipe it to zstd
  tar -cf - "$@" | zstd -20 --ultra -T0 --long=31 > "$output_file"

  if [ $? -eq 0 ]; then
    echo "Successfully created compressed archive $output_file, removing original files/directories"
    rm -r "${original_items[@]}"
    return 0
  else
    echo "Failed to create compressed archive, keeping original files/directories"
    return 1
  fi
}

zextract() {
  if [ $# -ne 1 ]; then
    echo "Usage: zextract archive_name.tar.zst"
    return 1
  fi

  archive_file="$1"

  if [ ! -f "$archive_file" ]; then
    echo "Error: File '$archive_file' does not exist."
    return 1
  fi

  # Extract using zstd -> tar
  zstd -d -c --long=31 "$archive_file" | tar -xf -

  if [ $? -eq 0 ]; then
    echo "Successfully extracted archive $archive_file, removing archive file"
    rm "$archive_file"
    return 0
  else
    echo "Failed to extract archive $archive_file, keeping archive file"
    return 1
  fi
}

alias tiny_rsync='rsync --whole-file --info=progress2 -zaHAX --safe-links --delete-delay --delay-updates --timeout=600'
alias best_rsync='rsync --info=progress2 -zaHAX --safe-links --delete-delay --delay-updates --timeout=600'

pchain() {
    local pid="$1"
    if [[ -z $pid || ! $pid =~ ^[0-9]+$ ]]; then
        echo "Usage: pchain PID" >&2
        return 2
    fi

    # Print header
    printf "%-8s | %s\n" "PID" "Name"
    printf "%s\n" "--------+----------------"

    while [[ $pid != 0 ]]; do
        local name ppid

        if [[ -r /proc/$pid/comm ]]; then
            name=$(head -c -1 /proc/$pid/comm 2>/dev/null)
            [[ -n $name ]] || name="[unknown]"
        else
            name="[no-comm]"
        fi

        printf "%-8s | %s\n" "$pid" "$name"

        [[ -r /proc/$pid/status ]] || break
        ppid=$(awk '/^PPid:/ {print $2; exit}' /proc/$pid/status)
        [[ -n $ppid && $ppid -ne $pid ]] || break

        pid=$ppid
    done
}

disk_compress() {
    local dev="$1"
    local outfile="$2"

    if [[ -z "$dev" || -z "$outfile" ]]; then
        echo "Usage: disk_compress <device> <output.zst>" >&2
        return 1
    fi

    if [[ ! -b "$dev" ]]; then
        echo "Error: '$dev' is not a block device." >&2
        return 1
    fi

    echo "Imaging $dev -> $outfile.."
    sudo dd if="$dev" bs=16M status=none | \
        pv -s $(sudo blockdev --getsize64 "$dev") | \
        zstd -T0 -19 -q -o "$outfile"

    echo "Validating.."
    local md5_zst
    md5_zst=$(zstdcat "$outfile" | md5sum | awk '{print $1}')

    local md5_dev
    md5_dev=$(sudo dd if="$dev" bs=16M status=none | \
        pv -s $(sudo blockdev --getsize64 "$dev") | \
        md5sum | awk '{print $1}')

    if [[ "$md5_zst" != "$md5_dev" ]]; then
        echo "Warning: Checksums do NOT match!"
        echo "MD5 of zst: $md5_zst"
        echo "MD5 of dev: $md5_dev"
    fi

    echo "Done: $outfile"
}

disk_decompress() {
    local infile="$1"
    local dev="$2"

    if [[ -z "$infile" || -z "$dev" ]]; then
        echo "Usage: disk_decompress <input.zst> <device>" >&2
        return 1
    fi

    if [[ ! -b "$dev" ]]; then
        echo "Error: '$dev' is not a block device." >&2
        return 1
    fi

    echo "Restoring $infile -> $dev ..."
    zstd -dc -q "$infile" |\
    sudo dd of="$dev" bs=16M status=progress conv=fsync

    echo "Validating.."
    local md5_zst
    md5_zst=$(zstdcat "$infile" | md5sum | awk '{print $1}')

    local md5_dev
    md5_dev=$(sudo dd if="$dev" bs=16M status=none | \
        pv -s $(sudo blockdev --getsize64 "$dev") | \
        md5sum | awk '{print $1}')

    if [[ "$md5_zst" != "$md5_dev" ]]; then
        echo "Warning: Checksums do NOT match!"
        echo "MD5 of zst: $md5_zst"
        echo "MD5 of dev: $md5_dev"
    fi

    echo "Done writing to $dev"
}

t() {
    command -v tmux >/dev/null 2>&1 || {
        echo "tmux not installed"
        return 1
    }

    echo "tmux:"
    echo "  1) Create session"
    echo "  2) Attach to newest session"
    echo "  3) Attach to named session"
    echo "  4) Detach everyone"
    echo "  5) Kill all sessions"
    echo
    read -rp "Select option [1-5]: " opt

    case "$opt" in
        1)
            read -rp "Session name: " name
            [ -z "$name" ] && { echo "No name given"; return 1; }
            tmux new -s "$name"
            ;;
        2)
            tmux ls >/dev/null 2>&1 || {
                echo "No tmux sessions"
                return 1
            }
            # newest = last in list
            session=$(tmux ls -F '#{session_name}' | tail -n 1)
            tmux attach -t "$session"
            ;;
        3)
            tmux ls >/dev/null 2>&1 || {
                echo "No tmux sessions"
                return 1
            }
            echo "Sessions:"
            tmux ls -F '#{session_name}'
            echo
            read -rp "Session name: " name
            [ -z "$name" ] && { echo "No name given"; return 1; }
            tmux attach -t "$name"
            ;;
        4)
            tmux detach-client -a
            ;;
        5)
            read -rp "Really kill ALL tmux sessions? [y/N]: " confirm
            case "$confirm" in
                y|Y)
                    tmux kill-server
                    ;;
                *)
                    echo "Aborted"
                    ;;
            esac
            ;;
        *)
            echo "Invalid option"
            return 1
            ;;
    esac
}
