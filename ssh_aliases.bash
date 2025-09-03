alias ssh="sshc && ssh"

fusermount_until_success() {
    local mountpoint="$1"
    local timeout="${2:-90}"  # Default timeout: 90 seconds
    local start_time=$(date +%s)

    while true; do
        if fusermount3 -u "$mountpoint" 2>/dev/null; then
            return 0
        else
            echo "Failed, retrying.."
        fi

        local now=$(date +%s)
        if (( now - start_time >= timeout )); then
            echo "Timeout reached while trying to unmount: $mountpoint" >&2
            return 1
        fi

        sleep 0.5
    done
}

cifsattach() {
  local name=""
  local ip=""
  local share="Public"
  local username=""
  local domain=""
  local password=""

  while [[ $# -gt 0 ]]; do
    case $1 in
      -n|--name)
        name="$2"
        shift 2
        ;;
      -i|--ip)
        ip="$2"
        shift 2
        ;;
      -s|--share)
        share="$2"
        shift 2
        ;;
      -u|--username)
        username="$2"
        shift 2
        ;;
      -d|--domain)
        domain="$2"
        shift 2
        ;;
      -P|--password)
        password="$2"
        shift 2
        ;;
      *)
        echo "Unknown option: $1" >&2
        return 1
        ;;
    esac
  done

  if [[ -z "$ip" || -z "$username" || -z "$password" ]]; then
    echo "Usage: cifsattach -i ip -u username -P password [-d domain] [-s share] [-n name]"
    return 1
  fi

  local mountpoint
  if [[ -z "$name" ]]; then
    mountpoint=$(mktemp -d /tmp/cifs.XXXXXX)
  else
    mountpoint="/tmp/$name"
    mkdir -p "$mountpoint"
  fi

  echo "Mounting //$ip/$share to $mountpoint..."

  local opts="username=$username,password=$password,uid=1000,gid=1000"
  [[ -n "$domain" ]] && opts+=",domain=$domain"

  if sudo mount -t cifs "//$ip/$share" "$mountpoint" -o "$opts"; then
    echo "Mounted at $mountpoint"
    echo "Press Enter to unmount..."
    read -r _
    sudo umount "$mountpoint" || echo "Failed to unmount CIFS!"
  else
    echo "Failed to mount CIFS share!"
  fi

  rmdir "$mountpoint" || echo "Failed to clean up mount point!"
}

ncifsattach() {
  local name=""
  local ip=""
  local share="Public"
  local username=""
  local domain=""
  local password=""

  while [[ $# -gt 0 ]]; do
    case $1 in
      -n|--name)
        name="$2"
        shift 2
        ;;
      -i|--ip)
        ip="$2"
        shift 2
        ;;
      -s|--share)
        share="$2"
        shift 2
        ;;
      -u|--username)
        username="$2"
        shift 2
        ;;
      -d|--domain)
        domain="$2"
        shift 2
        ;;
      -P|--password)
        password="$2"
        shift 2
        ;;
      *)
        echo "Unknown option: $1" >&2
        return 1
        ;;
    esac
  done

  if [[ -z "$ip" || -z "$username" || -z "$password" ]]; then
    echo "Usage: ncifsattach -i ip -u username -P password [-d domain] [-s share] [-n name]"
    return 1
  fi

  local mountpoint
  if [[ -z "$name" ]]; then
    mountpoint=$(mktemp -d /tmp/cifs.XXXXXX)
  else
    mountpoint="/tmp/$name"
    mkdir -p "$mountpoint"
  fi

  echo "Mounting //$ip/$share to $mountpoint..."

  local opts="username=$username,password=$password,uid=1000,gid=1000"
  [[ -n "$domain" ]] && opts+=",domain=$domain"

  if sudo mount -t cifs "//$ip/$share" "$mountpoint" -o "$opts"; then
    echo "Mounted at $mountpoint"
    sh -c "nautilus \"$mountpoint\" > /dev/null 2>&1" &
    disown
    echo "Press Enter to unmount..."
    read -r _
    sudo umount "$mountpoint" || echo "Failed to unmount CIFS!"
  else
    echo "Failed to mount CIFS share!"
  fi

  rmdir "$mountpoint" || echo "Failed to clean up mount point!"
}

sshfsattach() {
  grep -q '^user_allow_other' /etc/fuse.conf || echo 'user_allow_other' | sudo tee -a /etc/fuse.conf >/dev/null
  local name=""
  local port=""
  local remote_source=""
  while [[ $# -gt 0 ]]; do
    case $1 in
      -n|--name)
        name="$2"
        shift 2
        ;;
      -p|--port)
        port="$2"
        shift 2
        ;;
      -*)
        echo "Unknown option: $1" >&2
        return 1
        ;;
      *)
        remote_source="$1"
        shift
        ;;
    esac
  done

  if [[ -z "$remote_source" ]]; then
    echo "Usage: sshfsattach [-n name] [-p port] user@host:/remote/path"
    return 1
  fi

  local uid gid
  uid=$(id -u)
  gid=$(id -g)

  local mountpoint
  if [[ -z "$name" ]]; then
    mountpoint=$(mktemp -d /tmp/sshfs.XXXXXX)
  else
    mountpoint="/tmp/$name"
    mkdir -p "$mountpoint"
  fi

  echo "Mounting $remote_source to $mountpoint..."

  local sshfs_opts="-o reconnect,uid=$uid,gid=$gid,cache=yes,compression=yes,reconnect,ServerAliveInterval=15,ServerAliveCountMax=3,allow_root"
  if [[ -n "$port" ]]; then
    sshfs_opts+=",port=$port"
  fi

  if sshfs "$remote_source" "$mountpoint" $sshfs_opts; then
    echo "Mounted at $mountpoint"
    echo "Press Enter to unmount..."
    read -r _
    fusermount_until_success "$mountpoint" || echo "Failed to unmount sshfs!"
  else
    echo "Failed to mount remote source!"
  fi

  rmdir "$mountpoint" || echo "Failed to clean up mount point!"
}


nsshfsattach() {
  grep -q '^user_allow_other' /etc/fuse.conf || echo 'user_allow_other' | sudo tee -a /etc/fuse.conf >/dev/null
  local name=""
  local port=""
  local remote_source=""
  while [[ $# -gt 0 ]]; do
    case $1 in
      -n|--name)
        name="$2"
        shift 2
        ;;
      -p|--port)
        port="$2"
        shift 2
        ;;
      -*)
        echo "Unknown option: $1" >&2
        return 1
        ;;
      *)
        remote_source="$1"
        shift
        ;;
    esac
  done
  if [[ -z "$remote_source" ]]; then
    echo "Usage: sshfsmount [-n name] user@host:/remote/path"
    return 1
  fi
  local uid gid
  uid=$(id -u)
  gid=$(id -g)
  local mountpoint
  if [[ -z "$name" ]]; then
    mountpoint=$(mktemp -d /tmp/sshfs.XXXXXX)
  else
    mountpoint="/tmp/$name"
    mkdir -p "$mountpoint"
  fi
  echo "Mounting $remote_source to $mountpoint..."

  local sshfs_opts="-o reconnect,uid=$uid,gid=$gid,cache=yes,compression=yes,reconnect,ServerAliveInterval=15,ServerAliveCountMax=3,allow_root"
    if [[ -n "$port" ]]; then
      sshfs_opts+=",port=$port"
    fi

  if sshfs "$remote_source" "$mountpoint" $sshfs_opts; then
    echo "Mounted at $mountpoint"
    sh -c "nautilus "$mountpoint" > /dev/null 2>&1" &
    disown
    echo "Press Enter to unmount..."
    read -r _
    fusermount_until_success "$mountpoint" || echo "Failed to unmount sshfs!"
  else
    echo "Failed to mount remote source!"
  fi
  rmdir "$mountpoint" || echo "Failed to clean up mount point!"
}

# SSH-Agent
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"

sshc() {
    if [ -S "$SSH_AUTH_SOCK" ]; then
        if [ "$(ssh-add -l)" == "The agent has no identities." ]; then
            ssh-add
            echo "SSH agent identities added."
        fi
    fi
}

alias keyfalse="sshc && ssh -x -p25564 bill88t@0.feline.gr"
alias keyshut="sshc && ssh -p25564 bill88t@0.feline.gr sudo shutdown now"
alias wake="sshc && ssh -p25562 bill88t@0.feline.gr wake"
alias leto="sshc && ssh -o HostKeyAlgorithms=ssh-rsa -o PubkeyAcceptedKeyTypes=+ssh-rsa root@leto-delphi.gr"
alias letosftp="sshc && sftp -o HostKeyAlgorithms=ssh-rsa -o PubkeyAcceptedKeyTypes=+ssh-rsa root@leto-delphi.gr"
alias r5l="sshc && ssh -p25562 bill88t@0.feline.gr"
alias pandavps="sshc && ssh panda@152.53.0.224 -p 25564"
alias cm5="sshc && ssh bill88t@192.168.1.235"

alias prion="sshc && ssh bill88t@prion.ling-draconis.ts.net"
alias duo="sshc && ssh bill88t@duo.ling-draconis.ts.net"
alias icu="sshc && ssh bill88t@icu.ling-draconis.ts.net"
alias op5u="sshc && ssh bill88t@op5u.ling-draconis.ts.net"
alias r5t="sshc && ssh bill88t@r5t.ling-draconis.ts.net"
alias r5t="sshc && ssh bill88t@r5t.ling-draconis.ts.net"
alias r5bp="sshc && ssh bill88t@r5bp.ling-draconis.ts.net"

# Insecure
alias cssh='ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR'
alias csftp="sftp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"

alias fsprionarray="sshfsattach bill88t@prion.ling-draconis.ts.net:/mnt/Array -n prionarray"
alias fsprion="sshfsattach bill88t@prion.ling-draconis.ts.net:/home/bill88t -n prion"

alias nfsprionarray="nsshfsattach bill88t@prion.ling-draconis.ts.net:/mnt/Array -n prionarray"
alias nfsprion="nsshfsattach bill88t@prion.ling-draconis.ts.net:/home/bill88t -n prion"
