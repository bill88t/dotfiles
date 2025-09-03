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

alias mv_subdirfiles_to_pwd='find . -mindepth 2 -type f -exec mv -t . {} +'

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

alias tiny_rsync='rsync --whole-file --info=progress2 -zaHAX'
alias best_rsync='rsync --info=progress2 -zaHAX'
