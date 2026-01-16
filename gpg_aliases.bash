gpsign() {
    for filename in "$@"; do
        gpg --use-agent --output "${filename}.sig" --detach-sig "$filename"
    done
}

alias gpgreload="gpgconf --reload gpg-agent"
alias gpgrestart="systemctl --user restart gpg-agent"
gpgpasswd() {
    gpg --edit-key $1 passwd save quit
}
