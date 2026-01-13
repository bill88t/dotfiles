gpsign() {
    for filename in "$@"; do
        gpg --use-agent --output "${filename}.sig" --detach-sig "$filename"
    done
}

alias gpgreload="gpgconf --reload gpg-agent"
alias gpgrestart="systemctl --user restart gpg-agent"
alias gpgpasswd="gpg --edit-key $GPGKEY passwd save quit"
