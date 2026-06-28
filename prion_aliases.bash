alias raids="sudo btrfs filesystem usage /mnt/Array && echo && sudo btrfs device stats /mnt/Array"
alias rcon='mcrcon -P 25575 -p "$MCRCON"'

nollm() {
    systemctl --user stop llama.qwen
    systemctl --user stop llama.gemma
    systemctl --user stop llama.qwythos
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

qwythos() {
    nollm
    systemctl --user start llama.qwythos
}

coder() {
    nollm
    systemctl --user start llama.coder
}

bake() {
    cd /home/bill88t/git/Beryllium

    local dir="/mnt/Array/BUILD"
    echo "Cleaning $dir"
    [ -d "$dir" ] && sudo rm -rf "$dir"

    mkdir "$dir"
    sudo mkimage/mkimage.py -w $dir -o /mnt/Array/Images -c ./images/"$1"/ -x

    local status=$?
    [ $status -ne 0 ] && sudo rm -rf "$dir"

    cd -
    return $status
}

bake_iso() {
    cd /home/bill88t/git/Beryllium/iso

    local dir="/mnt/Array/BUILD"
    echo "Cleaning $dir"
    [ -d "$dir" ] && sudo rm -rf "$dir"

    mkdir "$dir"
    sudo ./mkarchiso -v -w $dir -o /mnt/Array/Images ./"$1"

    local status=$?
    [ $status -ne 0 ] && sudo rm -rf "$dir"

    cd -
    return $status
}
