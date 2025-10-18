alias ll='ls -lh'
alias la='ls -lha'
alias date-dash='date +%Y-%m-%d-%H:%M:%S' # use this for tagging stuff.
alias py='python3'
hist() {
    history | grep "$1" | tac | bat
}
alias ff='fastfetch'

alias als='for alias_name in $(echo "${!BASH_ALIASES[@]}" | tr " " "\n" | sort); do echo "Alias: $alias_name"; echo "Command: ${BASH_ALIASES[$alias_name]}"; echo "-------"; done'

alias dun='du -h -d 1'

alias m='micro'
alias mf='micro -config-dir ~/.config/microfast'

findcontent() {
    grep -rl "$@" .
}

copy() {
    if [[ -z "$1" ]]; then
        echo "Usage: copy <file_or_directory>"
        return 1
    fi
    COPY_SOURCE="$(realpath -- "$1")"
    COPY_NAME="$(basename -- "$1")"
    CUT_MODE=0
}

cut() {
    if [[ -z "$1" ]]; then
        echo "Usage: cut <file_or_directory>"
        return 1
    fi
    COPY_SOURCE="$(realpath -- "$1")"
    COPY_NAME="$(basename -- "$1")"
    CUT_MODE=1
}

paste() {
    if [[ -z "$COPY_SOURCE" || -z "$COPY_NAME" ]]; then
        echo "No copied or cut file/directory."
        return 1
    fi

    TARGET_NAME="${1:-$COPY_NAME}"  # Use provided name or default to original

    if [[ $CUT_MODE -eq 1 ]]; then
        mv -- "$COPY_SOURCE" "./$TARGET_NAME"
        unset COPY_SOURCE COPY_NAME CUT_MODE
    else
        cp -r -- "$COPY_SOURCE" "./$TARGET_NAME"
    fi
}

alias reload='. ~/.bashrc'

getal() {
    local a result offset
    a=$(alias "$1")
    offset=$((8 + ${#1}))
    result=${a:$offset}
    echo "${result%?}"
}

alias n="clear && bredos-news -f && echo -ne '\033[1F\033[0K'"

alias sstart="sudo systemctl start"
alias skill="sudo systemctl kill"
alias sstop="sudo systemctl stop"
alias sstatus="sudo systemctl status"
alias srestart="sudo systemctl restart"
alias senable="sudo systemctl enable"
alias senablen="sudo systemctl enable --now"
alias sdisable="sudo systemctl disable"
alias sdisablen="sudo systemctl disable --now"
alias sdreload="sudo systemctl daemon-reload"

alias usstart="systemctl --user start"
alias uskill="systemctl --user kill"
alias usstop="systemctl --user stop"
alias usstatus="systemctl --user status"
alias usrestart="systemctl --user restart"
alias usenable="systemctl --user enable"
alias usenablen="systemctl --user enable --now"
alias usdisable="systemctl --user disable"
alias usdisablen="systemctl --user disable --now"
