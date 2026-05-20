alias raids="sudo btrfs filesystem usage /mnt/Array && echo && sudo btrfs device stats /mnt/Array"
alias rcon='mcrcon -P 25575 -p "$MCRCON"'

nollm() {
    systemctl --user stop llama.qwen
    systemctl --user stop llama.gemma
    systemctl --user stop kobold.cpp
    systemctl --user stop kobold.image
}

alias kobold="nollm && systemctl --user start kobold.cpp"
alias kobold-image="nollm && systemctl --user start kobold.image"
alias gemma="nollm && systemctl --user start llama.gemma"
alias qwen="nollm && systemctl --user start llama.qwen"
