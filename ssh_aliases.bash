alias ssh="sshc && ssh"

__ssh_pick_endpoint() {
    local ep port extra
    local candidate

    for candidate in "$@"; do
        IFS=':' read -r ep port extra <<< "$candidate"
        port=${port:-22}

        # Try ICMP first
        if ping -c1 -W1 "$ep" &>/dev/null; then
            echo "$ep:$port:$extra"
            return 0
        fi

        # Try TCP fallback (some ICMP-blocked hosts)
        timeout 2 bash -c ":</dev/tcp/$ep/$port" &>/dev/null && {
            echo "$ep:$port:$extra"
            return 0
        }
    done

    return 1
}

__ssh_generate_functions() {
    local entry name user opts endpoints_str
    local -a endpoints
    local ep port extra

    for entry in "${SSH_MACHINES[@]}"; do
        IFS='|' read -r name user opts endpoints_str <<< "$entry"
        read -ra endpoints <<< "$endpoints_str"

        eval "
        $name() {
            local selected ep port extra
            selected=\$(__ssh_pick_endpoint ${endpoints[*]@Q}) || {
                echo 'No reachable endpoint for $name' >&2
                return 1
            }

            IFS=':' read -r ep port extra <<< \"\$selected\"
            if [ -S '\$SSH_AUTH_SOCK' ]; then
                if [ '\$(ssh-add -l)' == 'The agent has no identities.' ]; then
                    ssh-add
                    echo 'SSH agent identities added.'
                fi
            fi
            ssh -p \$port $opts ${extra} ${user:+$user@}\$ep \"\$@\"
        }
        "
    done
}

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

# Insecure
alias cssh='ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR'
alias csftp="sftp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"

if [ "${gnupg_SSH_AUTH_SOCK_by:-0}" -ne $$ ];
    then   export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)";
fi
