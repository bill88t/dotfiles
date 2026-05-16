alias raids="sudo btrfs filesystem usage /mnt/Array && echo && sudo btrfs device stats /mnt/Array"
alias rcon='mcrcon -P 25575 -p "$MCRCON"'

alias kobold="systemctl --user stop llama.cpp && systemctl --user start koboldcpp"
alias llama="systemctl --user stop koboldcpp && systemctl --user start llama.cpp"
