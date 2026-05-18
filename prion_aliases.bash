alias raids="sudo btrfs filesystem usage /mnt/Array && echo && sudo btrfs device stats /mnt/Array"
alias rcon='mcrcon -P 25575 -p "$MCRCON"'

alias kobold="systemctl --user stop llama.qwen && systemctl --user stop llama.gemma && systemctl --user start kobold.cpp"
alias gemma="systemctl --user stop kobold.cpp && systemctl --user stop llama.qwen && systemctl --user start llama.gemma"
alias qwen="systemctl --user stop kobold.cpp && systemctl --user stop llama.gemma && systemctl --user start llama.qwen"
alias nollm="systemctl --user stop kobold.cpp && systemctl --user stop llama.qwen && systemctl --user stop llama.gemma"
