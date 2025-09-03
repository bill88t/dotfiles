gpsign() {
    for filename in "$@"; do
        gpg --use-agent --output "${filename}.sig" --detach-sig "$filename"
    done
}

alias gpgreload="gpgconf --reload gpg-agent"
alias gpgpasswd="gpg --edit-key $GPGKEY passwd save quit"
