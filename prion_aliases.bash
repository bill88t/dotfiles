alias raids="sudo btrfs filesystem usage /mnt/Array && echo && sudo btrfs device stats /mnt/Array"
alias rcon='mcrcon -P 25575 -p "$MCRCON"'

alias kobold="systemctl --user stop llama.cpp && systemctl --user start kobold.cpp"
alias llama="systemctl --user stop kobold.cpp && systemctl --user start llama.cpp"
alias nollm="systemctl --user stop kobold.cpp && systemctl --user stop llama.cpp"
