alias raids="sudo btrfs filesystem usage /mnt/Array && echo && sudo btrfs device stats /mnt/Array"
alias rcon='mcrcon -P 25575 -p "$MCRCON"'

nollm() {
    systemctl --user stop llama.qwen
    systemctl --user stop llama.gemma
    systemctl --user stop llama.coder
    systemctl --user stop kobold.cpp
    systemctl --user stop kobold.image
}

kobold() {
    nollm
    systemctl --user start kobold.cpp
}

kobold-image() {
    nollm
    systemctl --user start kobold.image
}

gemma() {
    nollm
    systemctl --user start llama.gemma
}

qwen() {
    nollm
    systemctl --user start llama.qwen
}

coder() {
    nollm
    systemctl --user start llama.coder
}
